import Foundation
import SwiftUI
import Combine

/// Результат слова в ходе (для экрана TurnEnd)
struct TurnWordResult: Identifiable, Equatable {
    let id: UUID
    let text: String
    var guessed: Bool
}

/// Главная ViewModel — связывает UI с игровым движком
@MainActor
final class GameViewModel: ObservableObject {

    // MARK: - Навигация

    @Published var navigationState: NavigationState = .home

    // MARK: - Игровой движок и сервисы

    @Published var engine: GameEngine
    @Published var settings: GameSettings

    // MARK: - Состояние UI

    @Published var isPaused: Bool = false
    /// true когда пауза вызвана системой (фон/звонок) — для BUG-009 scenePhase handling
    @Published var isPausedBySystem: Bool = false

    // MARK: - v2: Pending players (between PlayerSetup and ModeSelection)

    @Published var pendingPlayers: [Player] = []

    // MARK: - v2: Mode-specific ViewModels

    @Published var pairsViewModel: PairsGameViewModel? = nil
    @Published var teamsViewModel: TeamsGameViewModel? = nil
    @Published var freeForAllViewModel: FreeForAllGameViewModel? = nil

    // MARK: - Word input phase

    @Published var allPlayers: [Player] = []
    // BUG-012: wordsPerPlayer убран — в "Шляпе" нет фиксированного лимита слов на игрока
    @Published var currentWordInputPlayerIndex: Int = 0
    @Published var enteredWordsForCurrentPlayer: [String] = []
    @Published var allEnteredWords: [String] = []
    @Published var isCurrentPlayerDone: Bool = false
    @Published var showPhoneHandoff: Bool = false

    // MARK: - Turn results

    @Published var turnResults: [TurnWordResult] = []
    private var guessedCountBeforeTurn: Int = 0

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Инициализация

    init() {
        let settings = GameSettings.defaults
        self.settings = settings
        self.engine = GameEngine(settings: settings)
        observeEngine()
    }

    // MARK: - Навигация

    func navigateTo(_ state: NavigationState) {
        navigationState = state
    }

    func startNewGame() {
        navigationState = .teamSetup
    }

    /// v2: Запуск игры из GameConfig (режим + команды + настройки)
    func startGame(with config: GameConfig) {
        // TASK-027: случайно выбираем hatSize слов; если слов меньше — берём все
        let deck = DeckService.loadDeck(level: config.difficulty.wordLevel, count: config.hatSize)
        engine.updateSettings(GameSettings(
            roundDuration: config.turnDuration,
            wordsCount: deck.count
        ))

        // Сброс предыдущих mode VM
        pairsViewModel = nil
        teamsViewModel = nil
        freeForAllViewModel = nil

        switch config.mode {
        case .pairs:
            let vm = PairsGameViewModel(config: config, deck: deck)
            pairsViewModel = vm
            // BUG-022: pipe child VM changes into GameViewModel so ContentView re-renders
            vm.objectWillChange
                .sink { [weak self] _ in self?.objectWillChange.send() }
                .store(in: &cancellables)
            navigationState = .pairsWaiting

        case .teams:
            let vm = TeamsGameViewModel(config: config)
            teamsViewModel = vm
            vm.objectWillChange
                .sink { [weak self] _ in self?.objectWillChange.send() }
                .store(in: &cancellables)
            navigationState = .teamsWaiting

        case .freeForAll:
            let vm = FreeForAllGameViewModel(config: config)
            freeForAllViewModel = vm
            vm.objectWillChange
                .sink { [weak self] _ in self?.objectWillChange.send() }
                .store(in: &cancellables)
            navigationState = .freeForAllWaiting
        }
    }

    func openSettings() {
        navigationState = .settings
    }

    func goHome() {
        engine.resetGame()
        resetWordInputState()
        pairsViewModel = nil
        teamsViewModel = nil
        freeForAllViewModel = nil
        navigationState = .home
    }

    // MARK: - Setup → Word Input / Waiting

    /// Start the word input or game phase depending on difficulty
    /// BUG-012: wordsPerPlayer убран — для словарей используются ВСЕ слова выбранного уровня
    func setupWordInput(players: [Player], turnDuration: Int, difficulty: DifficultyLevel) {
        self.allPlayers = players
        self.settings.roundDuration = turnDuration

        if difficulty == .custom {
            // Игроки вводят слова сами — без ограничения по количеству
            currentWordInputPlayerIndex = 0
            enteredWordsForCurrentPlayer = []
            allEnteredWords = []
            isCurrentPlayerDone = false
            navigationState = .wordInput
        } else {
            // Загружаем ВСЕ слова выбранного уровня и перемешиваем (BUG-017)
            let teams = players.map { Team(name: $0.name, players: [$0]) }
            let deck = DeckService.loadAllWords(level: difficulty.wordLevel).shuffled()
            engine.updateSettings(settings)
            engine.setupGame(teams: teams, deck: deck)
            navigationState = .waiting
        }
    }

    // MARK: - Word Input Actions

    func addWord(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        enteredWordsForCurrentPlayer.append(trimmed)
        // BUG-012: нет автоматического завершения по лимиту — игрок сам нажимает "Готово"
    }

    func moveToNextPlayer() {
        allEnteredWords.append(contentsOf: enteredWordsForCurrentPlayer)
        enteredWordsForCurrentPlayer = []
        isCurrentPlayerDone = false

        if currentWordInputPlayerIndex < allPlayers.count - 1 {
            currentWordInputPlayerIndex += 1
            showPhoneHandoff = true
        } else {
            startGameWithWords()
        }
    }

    func phoneHandoffDone() {
        showPhoneHandoff = false
    }

    var currentWordInputPlayer: Player? {
        guard allPlayers.indices.contains(currentWordInputPlayerIndex) else { return nil }
        return allPlayers[currentWordInputPlayerIndex]
    }

    var nextWordInputPlayer: Player? {
        let next = currentWordInputPlayerIndex + 1
        guard allPlayers.indices.contains(next) else { return nil }
        return allPlayers[next]
    }

    var currentWordNumber: Int {
        enteredWordsForCurrentPlayer.count + 1
    }

    var isLastPlayer: Bool {
        currentWordInputPlayerIndex >= allPlayers.count - 1
    }

    // MARK: - Game Start

    private func startGameWithWords() {
        let words = allEnteredWords.shuffled().map { Word(text: $0) } // BUG-017: shuffled()
        let teams = allPlayers.map { Team(name: $0.name, players: [$0]) }
        engine.updateSettings(settings)
        engine.setupGame(teams: teams, deck: words)
        navigationState = .waiting
    }

    // MARK: - Waiting → Gameplay

    func startTurn() {
        guessedCountBeforeTurn = engine.session.guessedWords.count
        engine.startRound()
        navigationState = .gameplay
    }

    // MARK: - Игровые действия

    func guessWord() {
        engine.wordGuessed()
        checkGameState()
    }

    func skipWord() {
        guard settings.allowSkipping else { return }
        engine.wordSkipped()
        checkGameState()
    }

    func pauseGame() {
        engine.timerService.pause()
        isPaused = true
        isPausedBySystem = false
    }

    /// Системная пауза (фон / входящий звонок) — BUG-009
    func pauseGameBySystem() {
        engine.timerService.pause()
        isPaused = true
        isPausedBySystem = true
    }

    func resumeGame() {
        engine.timerService.resume()
        isPaused = false
        isPausedBySystem = false
    }

    /// Legacy method kept for GameplayView compatibility
    func nextTeam() {
        confirmTurnResults()
    }

    func playAgain() {
        engine.resetGame()
        resetWordInputState()
        navigationState = .teamSetup
    }

    // MARK: - Turn End

    func prepareTurnResults() {
        let turnGuessed: [Word]
        if guessedCountBeforeTurn < engine.session.guessedWords.count {
            turnGuessed = Array(engine.session.guessedWords[guessedCountBeforeTurn...])
        } else {
            turnGuessed = []
        }
        let turnSkipped = engine.session.skippedWordsThisTurn

        turnResults = turnGuessed.map { TurnWordResult(id: $0.id, text: $0.text, guessed: true) }
                    + turnSkipped.map { TurnWordResult(id: $0.id, text: $0.text, guessed: false) }
        navigationState = .turnEnd
    }

    func toggleTurnResult(at index: Int) {
        guard turnResults.indices.contains(index) else { return }
        turnResults[index].guessed.toggle()
    }

    func confirmTurnResults() {
        applyTurnCorrections()

        if engine.session.wordDeck.isEmpty || engine.checkGameOver() {
            engine.session.state = .gameOver
            navigationState = .results
        } else {
            engine.session.state = .setup
            let teamCount = engine.session.teams.count
            guard teamCount > 0 else { return }
            engine.session.currentTeamIndex = (engine.session.currentTeamIndex + 1) % teamCount
            if engine.session.currentTeamIndex == 0 {
                engine.session.currentRound += 1
            }
            // Rotate explainer for the team that just played
            let prevIdx = (engine.session.currentTeamIndex - 1 + teamCount) % teamCount
            engine.session.teams[prevIdx].rotateExplainer()
            engine.session.skippedWordsThisTurn = []
            engine.session.roundScore = 0
            navigationState = .waiting
        }
    }

    var turnGuessedCount: Int {
        turnResults.filter { $0.guessed }.count
    }

    // MARK: - Computed properties for UI

    var currentWord: Word? {
        engine.session.currentWord
    }

    var currentTeam: Team? {
        engine.session.currentTeam
    }

    var wordsRemaining: Int {
        engine.session.wordsRemaining
    }

    var roundScore: Int {
        engine.session.roundScore
    }

    var gameState: GameState {
        engine.session.state
    }

    var standings: [Team] {
        engine.standings
    }

    var currentRound: Int {
        engine.session.currentRound
    }

    var currentExplainerName: String {
        engine.session.currentTeam?.currentExplainer?.name ?? ""
    }

    // MARK: - Приватные методы

    private func observeEngine() {
        engine.$session
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                guard let self else { return }
                // BUG-004: guard чтобы не триггерить дважды (Combine + checkGameState)
                // Combine-observer обрабатывает только когда мы на экране gameplay
                guard self.navigationState == .gameplay else { return }
                if session.state == .gameOver {
                    self.navigationState = .results
                } else if session.state == .roundEnd {
                    self.prepareTurnResults()
                }
            }
            .store(in: &cancellables)
    }

    private func checkGameState() {
        // BUG-004: guard — не обрабатываем если уже ушли с gameplay (Combine уже обработал)
        guard navigationState == .gameplay else { return }
        if engine.session.state == .gameOver {
            navigationState = .results
        } else if engine.session.state == .roundEnd {
            prepareTurnResults()
        }
    }

    private func applyTurnCorrections() {
        let teamCount = engine.session.teams.count
        guard teamCount > 0 else { return }
        let teamIdx = engine.session.currentTeamIndex % teamCount

        let originalGuessedIds: Set<UUID>
        if guessedCountBeforeTurn < engine.session.guessedWords.count {
            originalGuessedIds = Set(engine.session.guessedWords[guessedCountBeforeTurn...].map { $0.id })
        } else {
            originalGuessedIds = []
        }

        for result in turnResults {
            let wasGuessed = originalGuessedIds.contains(result.id)

            if result.guessed && !wasGuessed {
                // Changed from skipped → guessed
                engine.session.teams[teamIdx].score += 1
                if let deckIdx = engine.session.wordDeck.firstIndex(where: { $0.id == result.id }) {
                    var word = engine.session.wordDeck.remove(at: deckIdx)
                    word.isGuessed = true
                    engine.session.guessedWords.append(word)
                }
            } else if !result.guessed && wasGuessed {
                // Changed from guessed → skipped
                engine.session.teams[teamIdx].score = max(0, engine.session.teams[teamIdx].score - 1)
                if let guessedIdx = engine.session.guessedWords.firstIndex(where: { $0.id == result.id }) {
                    var word = engine.session.guessedWords.remove(at: guessedIdx)
                    word.isGuessed = false
                    let insertIdx = engine.session.wordDeck.isEmpty
                        ? 0
                        : Int.random(in: 0...engine.session.wordDeck.count)
                    engine.session.wordDeck.insert(word, at: insertIdx)
                }
            }
        }
    }

    private func resetWordInputState() {
        allPlayers = []
        enteredWordsForCurrentPlayer = []
        allEnteredWords = []
        currentWordInputPlayerIndex = 0
        isCurrentPlayerDone = false
        showPhoneHandoff = false
        turnResults = []
    }

    /// Начать игру с выбранными командами (legacy — used by old flow)
    func beginGame(teams: [Team]) {
        engine.updateSettings(settings)
        let deck = DeckService.loadDeck(
            level: settings.difficulty,
            count: settings.wordsCount
        )
        engine.setupGame(teams: teams, deck: deck)
        engine.startRound()
        navigationState = .gameplay
    }
}
