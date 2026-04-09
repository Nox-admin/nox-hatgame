import Foundation
import SwiftUI
import Combine

/// ViewModel командного режима игры
@MainActor
final class TeamsGameViewModel: ObservableObject, PausableViewModel {
    var pauseTimerService: PausableTimerService { engine.timerService }

    // MARK: - Фаза игры

    enum TeamsPhase: Equatable {
        case waiting    // Передай телефон — покажи кто объясняет
        case playing    // Активный ход
        case roundEnd   // Результаты хода с коррекцией
        case gameOver   // Финальные результаты
        case goHome     // Досрочный выход до начала игры → на главный экран
    }

    // MARK: - Published state

    let engine: GameEngine
    let config: GameConfig

    @Published var navigationPhase: TeamsPhase = .waiting
    @Published var turnResults: [TurnWordResult] = []
    @Published var isPaused: Bool = false
    @Published var isPausedBySystem: Bool = false

    private var guessedCountBeforeTurn: Int = 0
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(config: GameConfig) {
        self.config = config
        let settings = GameSettings(roundDuration: config.turnDuration)
        self.engine = GameEngine(settings: settings)
        let deck = DeckService.loadAllWords(level: config.difficulty.wordLevel).shuffled()
        engine.setupGame(teams: config.teams, deck: deck)
        setupObserver()
    }

    // MARK: - Подписка на состояние движка

    private func setupObserver() {
        engine.$session
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                guard let self, self.navigationPhase == .playing else { return }
                if session.state == .gameOver {
                    self.navigationPhase = .gameOver
                } else if session.state == .roundEnd {
                    self.prepareTurnResults()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Computed properties

    var currentTeam: Team? { engine.session.currentTeam }
    var currentExplainer: Player? { engine.session.currentTeam?.currentExplainer }
    var currentWord: Word? { engine.session.currentWord }
    var wordsRemaining: Int { engine.session.wordsRemaining }
    var roundScore: Int { engine.session.roundScore }
    var currentRound: Int { engine.session.currentRound }
    var standings: [Team] { engine.standings }

    var turnGuessedCount: Int {
        turnResults.filter { $0.guessed }.count
    }

    // MARK: - Управление игрой

    func startTurn() {
        guessedCountBeforeTurn = engine.session.guessedWords.count
        engine.startRound()
        navigationPhase = .playing
    }

    func guessWord() {
        guard navigationPhase == .playing else { return }
        engine.wordGuessed()
        checkState()
    }

    func skipWord() {
        guard navigationPhase == .playing else { return }
        engine.wordSkipped()
        checkState()
    }

    private func checkState() {
        // BUG-004: guard — не обрабатываем если уже ушли с playing
        guard navigationPhase == .playing else { return }
        if engine.session.state == .gameOver {
            navigationPhase = .gameOver
        } else if engine.session.state == .roundEnd {
            prepareTurnResults()
        }
    }

    // MARK: - Пауза (реализация через PausableViewModel)

    // MARK: - Результаты хода

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
        navigationPhase = .roundEnd
    }

    func toggleResult(at index: Int) {
        guard turnResults.indices.contains(index) else { return }
        // Только переключаем UI-состояние. Счёт пересчитывается единожды в applyCorrections()
        // при подтверждении раунда, чтобы избежать двойного начисления.
        turnResults[index].guessed.toggle()
    }

    func confirmRound() {
        applyCorrections()
        let teamCount = engine.session.teams.count
        guard teamCount > 0 else { return }

        if engine.session.wordDeck.isEmpty || engine.checkGameOver() {
            engine.session.state = .gameOver
            navigationPhase = .gameOver
        } else {
            // Ротация объясняющего в текущей команде
            let prevIdx = engine.session.currentTeamIndex % teamCount
            engine.session.teams[prevIdx].rotateExplainer()
            // Переход к следующей команде
            engine.session.currentTeamIndex = (engine.session.currentTeamIndex + 1) % teamCount
            if engine.session.currentTeamIndex == 0 {
                engine.session.currentRound += 1
            }
            engine.session.skippedWordsThisTurn = []
            engine.session.roundScore = 0
            engine.session.state = .setup
            navigationPhase = .waiting
        }
    }

    // MARK: - Приватные

    private func applyCorrections() {
        let teamCount = engine.session.teams.count
        guard teamCount > 0 else { return }
        let teamIdx = engine.session.currentTeamIndex % teamCount

        let originalGuessedIds: Set<UUID>
        if guessedCountBeforeTurn < engine.session.guessedWords.count {
            originalGuessedIds = Set(engine.session.guessedWords[guessedCountBeforeTurn...].map { $0.id })
        } else {
            originalGuessedIds = []
        }

        // Вся логика синхронизации deck/guessedWords и пересчёта score — в GameEngine.
        engine.applyTurnCorrections(
            turnResults: turnResults,
            originalGuessedIds: originalGuessedIds,
            teamIdx: teamIdx
        )
    }

    // MARK: - TASK-013: Принудительное завершение + рестарт

    // BUG-031: досрочное завершение хода (объяснитель нажимает сам)
    func endTurnEarly() {
        guard navigationPhase == .playing else { return }
        engine.timerService.stop()
        prepareTurnResults()
    }

    func endGameEarly() {
        engine.timerService.stop()
        navigationPhase = .gameOver
    }

    func restartGame() {
        let deck = DeckService.loadAllWords(level: config.difficulty.wordLevel).shuffled()
        // Сброс команд
        for i in engine.session.teams.indices {
            engine.session.teams[i].score = 0
            engine.session.teams[i].currentExplainerIndex = 0
        }
        engine.session.currentTeamIndex = 0
        engine.session.currentRound = 1
        engine.session.wordDeck = deck
        engine.session.guessedWords = []
        engine.session.state = .setup
        turnResults = []
        guessedCountBeforeTurn = 0
        navigationPhase = .waiting
    }

    var gameResult: GameResult {
        .teams(standings: engine.standings)
    }
}
