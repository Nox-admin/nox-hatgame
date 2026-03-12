import Foundation
import SwiftUI

/// ViewModel попарного режима игры
@MainActor
final class PairsGameViewModel: ObservableObject {

    // MARK: - Фаза игры

    enum GamePhase: Equatable {
        case waiting    // Между раундами — покажи кто кому, передай телефон
        case playing    // Активный раунд
        case roundEnd   // Результаты раунда (угаданные/пропущенные)
        case gameOver   // Все раунды сыграны — финальные результаты
        case circleEnd  // BUG-042: полный круг завершён, предложить сыграть ещё
        case goHome     // Досрочный выход до начала игры → на главный экран
    }

    // MARK: - Published state

    @Published var phase: GamePhase = .waiting
    @Published var currentRoundIndex: Int = 0
    @Published var wordDeck: [Word] = []
    @Published var currentTurnGuessed: [Word] = []
    @Published var currentTurnSkipped: [Word] = []
    @Published var isPaused: Bool = false
    @Published var isPausedBySystem: Bool = false

    /// Индивидуальные очки: playerId -> score
    @Published var scores: [UUID: Int] = [:]

    // MARK: - Dependencies

    private(set) var schedule: PairsSchedule
    let config: GameConfig
    let timerService: TimerService

    // MARK: - Init

    init(config: GameConfig, deck: [Word]) {
        self.config = config
        self.schedule = PairsSchedule.generate(players: config.players)
        self.wordDeck = deck
        self.timerService = TimerService(duration: config.turnDuration)
        for player in config.players {
            scores[player.id] = 0
        }
    }

    // MARK: - Computed

    var currentRound: PairsRound? {
        guard schedule.rounds.indices.contains(currentRoundIndex) else { return nil }
        return schedule.rounds[currentRoundIndex]
    }

    var currentWord: Word? { wordDeck.first }
    var wordsRemaining: Int { wordDeck.count }
    var isLastRound: Bool { currentRoundIndex >= schedule.totalRounds - 1 }

    /// Таблица лидеров (отсортирована по убыванию очков)
    var standings: [(player: Player, score: Int)] {
        config.players
            .map { player in (player: player, score: scores[player.id] ?? 0) }
            .sorted { $0.score > $1.score }
    }

    var turnGuessedCount: Int { currentTurnGuessed.count }

    // MARK: - Управление игрой

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
        guard phase == .playing, var word = wordDeck.first else { return }
        wordDeck.removeFirst()
        word.isGuessed = true
        currentTurnGuessed.append(word)
        // +1 объясняющему, +1 угадывающему
        if let round = currentRound {
            scores[round.explainer.id, default: 0] += 1
            scores[round.guesser.id, default: 0] += 1
        }
        if wordDeck.isEmpty { endRound() }
    }

    func wordSkipped() {
        guard phase == .playing, let word = wordDeck.first else { return }
        wordDeck.removeFirst()
        currentTurnSkipped.append(word)
        // Вернуть в случайную позицию колоды
        let insertIdx = wordDeck.isEmpty ? 0 : Int.random(in: 0...wordDeck.count)
        wordDeck.insert(word, at: insertIdx)
    }

    func endRound() {
        timerService.stop()
        phase = .roundEnd
    }

    func confirmRound() {
        if wordDeck.isEmpty {
            phase = .gameOver
        } else if isLastRound {
            // BUG-042: полный круг завершён — предлагаем сыграть ещё или закончить
            phase = .circleEnd
        } else {
            currentRoundIndex += 1
            phase = .waiting
        }
    }

    /// BUG-042: запускает новый полный круг, очки накапливаются
    func continueNextCircle() {
        let newSchedule = PairsSchedule.generate(players: config.players)
        // Заменяем расписание (приватное — нужно через mutable copy)
        schedule = newSchedule
        currentRoundIndex = 0
        phase = .waiting
    }

    var circleNumber: Int {
        // Номер текущего круга = (всего завершённых раундов / N) + 1
        let n = config.players.count
        guard n > 0 else { return 1 }
        return (currentRoundIndex / n) + 1
    }

    // MARK: - Пауза

    func pauseGame() {
        timerService.pause()
        isPaused = true
        isPausedBySystem = false
    }

    func pauseBySystem() {
        timerService.pause()
        isPaused = true
        isPausedBySystem = true
    }

    func resumeGame() {
        timerService.resume()
        isPaused = false
        isPausedBySystem = false
    }

    // MARK: - Коррекция результатов

    func toggleTurnResult(wordId: UUID) {
        if let idx = currentTurnGuessed.firstIndex(where: { $0.id == wordId }) {
            var word = currentTurnGuessed.remove(at: idx)
            word.isGuessed = false
            currentTurnSkipped.append(word)
            if let round = currentRound {
                scores[round.explainer.id, default: 0] = max(0, (scores[round.explainer.id] ?? 0) - 1)
                scores[round.guesser.id, default: 0] = max(0, (scores[round.guesser.id] ?? 0) - 1)
            }
        } else if let idx = currentTurnSkipped.firstIndex(where: { $0.id == wordId }) {
            var word = currentTurnSkipped.remove(at: idx)
            word.isGuessed = true
            currentTurnGuessed.append(word)
            if let round = currentRound {
                scores[round.explainer.id, default: 0] += 1
                scores[round.guesser.id, default: 0] += 1
            }
        }
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
        currentRoundIndex = 0
        currentTurnGuessed = []
        currentTurnSkipped = []
        for player in config.players { scores[player.id] = 0 }
        phase = .waiting
    }

    var gameResult: GameResult {
        .players(standings: standings, mode: config.mode)
    }
}
