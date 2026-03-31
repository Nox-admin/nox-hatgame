import Foundation
import SwiftUI
import Combine

// MARK: - Word Attribution
// После раунда: какое слово угадал какой игрок

struct WordAttribution: Identifiable {
    let id: UUID         // == word.id
    let text: String
    var guesser: Player? // nil = никто не угадал
}

// MARK: - FreeForAllGameViewModel

@MainActor
final class FreeForAllGameViewModel: ObservableObject, PausableViewModel {
    var pauseTimerService: PausableTimerService { timerService }

    enum Phase: Equatable {
        case waiting      // Передача телефона, показываем кто объясняет
        case playing      // Активный раунд
        case attribution  // "Кто угадал?" — матрица слово × игрок
        case gameOver     // Финал
        case goHome       // Досрочный выход до начала игры → на главный экран
    }

    // MARK: - State

    @Published var phase: Phase = .waiting
    @Published var wordDeck: [Word] = []
    @Published var currentTurnGuessed: [Word] = []   // угаданные за ход
    @Published var currentTurnSkipped: [Word] = []   // пропущенные за ход
    @Published var attributions: [WordAttribution] = []
    @Published var isPaused: Bool = false
    @Published var isPausedBySystem: Bool = false

    // Индивидуальные очки: playerId → score
    @Published var scores: [UUID: Int] = [:]

    // MARK: - Config

    let config: GameConfig
    let timerService: TimerService
    private var explainerIndex: Int = 0
    private var roundNumber: Int = 1

    var players: [Player] { config.players }

    // Текущий объяснитель
    var currentExplainer: Player? {
        guard !players.isEmpty else { return nil }
        return players[explainerIndex % players.count]
    }

    // Игроки которые угадывают (все кроме объяснителя)
    var guessers: [Player] {
        guard let explainer = currentExplainer else { return players }
        return players.filter { $0.id != explainer.id }
    }

    var currentWord: Word? { wordDeck.first }
    var wordsRemaining: Int { wordDeck.count }
    var roundScore: Int { currentTurnGuessed.count }
    var isLastRound: Bool { wordDeck.count <= currentTurnGuessed.count }

    var standings: [(player: Player, score: Int)] {
        players
            .map { (player: $0, score: scores[$0.id] ?? 0) }
            .sorted { $0.score > $1.score }
    }

    // MARK: - Init

    init(config: GameConfig) {
        self.config = config
        self.timerService = TimerService(duration: config.turnDuration)
        // Загружаем слова из конфига
        let deck = DeckService.loadAllWords(level: config.difficulty.wordLevel).shuffled()
        self.wordDeck = deck

        // Инициируем очки
        for player in config.players {
            scores[player.id] = 0
        }
    }

    // MARK: - Game control

    func startRound() {
        guard !wordDeck.isEmpty else {
            phase = .gameOver
            return
        }
        currentTurnGuessed = []
        currentTurnSkipped = []

        timerService.onExpire = { [weak self] in
            Task { @MainActor in self?.endRound() }
        }
        timerService.start(duration: config.turnDuration)
        phase = .playing
    }

    func wordGuessed() {
        guard phase == .playing, let word = wordDeck.first else { return }
        wordDeck.removeFirst()
        var guessed = word
        guessed.isGuessed = true
        currentTurnGuessed.append(guessed)
        if wordDeck.isEmpty { endRound() }
    }

    func wordSkipped() {
        guard phase == .playing, let word = wordDeck.first else { return }
        wordDeck.removeFirst()
        currentTurnSkipped.append(word)
        // Возвращаем в колоду — случайно, но deterministic по индексу (избегаем random в рендере)
        wordDeck.append(word)
    }

    func endRound() {
        timerService.stop()
        // Возвращаем пропущенные слова в колоду (перемешиваем)
        wordDeck.append(contentsOf: currentTurnSkipped.shuffled())
        currentTurnSkipped = []

        // Подготавливаем атрибуцию для угаданных слов
        attributions = currentTurnGuessed.map { word in
            WordAttribution(id: word.id, text: word.text, guesser: nil)
        }

        if attributions.isEmpty {
            // Нет угаданных слов — пропускаем атрибуцию
            confirmAttribution()
        } else {
            phase = .attribution
        }
    }

    // MARK: - Attribution

    func setGuesser(_ player: Player?, for wordId: UUID) {
        guard let idx = attributions.firstIndex(where: { $0.id == wordId }) else { return }
        attributions[idx].guesser = player
    }

    func confirmAttribution() {
        // Начисляем очки
        guard let explainer = currentExplainer else { advance(); return }

        for attribution in attributions {
            if let guesser = attribution.guesser {
                scores[explainer.id, default: 0] += 1
                scores[guesser.id, default: 0] += 1
            }
        }

        advance()
    }

    private func advance() {
        if wordDeck.isEmpty {
            phase = .gameOver
            return
        }
        // Ротируем объяснителя
        explainerIndex = (explainerIndex + 1) % players.count
        if explainerIndex == 0 { roundNumber += 1 }
        phase = .waiting
    }

    // MARK: - Pause (реализация через PausableViewModel)

    // MARK: - Round info

    var roundLabel: String {
        L10n.FreeForAll.roundLabel(roundNumber)
    }

    var explainerOrdinal: String {
        guard let explainer = currentExplainer else { return "" }
        return L10n.FreeForAll.explainerLabel(explainer.name)
    }

    // MARK: - TASK-013: Принудительное завершение + рестарт

    func endGameEarly() {
        // BUG-021: с WaitingView (ещё не играли) → на главный экран; с Gameplay/Pause → финал с очками
        if phase == .waiting {
            phase = .goHome
        } else {
            timerService.stop()
            phase = .gameOver
        }
    }

    func restartGame() {
        let deck = DeckService.loadAllWords(level: config.difficulty.wordLevel).shuffled()
        wordDeck = deck
        currentTurnGuessed = []
        currentTurnSkipped = []
        attributions = []
        explainerIndex = 0
        roundNumber = 1
        for player in config.players { scores[player.id] = 0 }
        phase = .waiting
    }

    var gameResult: GameResult {
        .players(standings: standings, mode: config.mode)
    }
}
