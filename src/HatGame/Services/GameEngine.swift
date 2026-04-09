import Foundation

/// Игровой движок — основная логика игры «Шляпа»
///
/// Конечный автомат: .setup → .playing → .roundEnd → .playing → ... → .gameOver
final class GameEngine: ObservableObject {

    // MARK: - Публичные свойства

    @Published var session: GameSession
    @Published var timerService: TimerService

    private var settings: GameSettings

    // MARK: - Инициализация

    init(settings: GameSettings = .defaults) {
        self.settings = settings
        self.session = GameSession()
        self.timerService = TimerService(duration: settings.roundDuration)
    }

    // MARK: - Настройка игры

    /// Инициализация новой игры с командами и колодой
    func setupGame(teams: [Team], deck: [Word]) {
        session = GameSession(
            teams: teams,
            wordDeck: deck,
            state: .setup
        )
    }

    /// Обновить настройки
    func updateSettings(_ newSettings: GameSettings) {
        settings = newSettings
        timerService = TimerService(duration: newSettings.roundDuration)
    }

    // MARK: - Управление раундами

    /// Начать раунд для текущей команды
    func startRound() {
        guard !session.wordDeck.isEmpty else {
            endGame()
            return
        }

        session.state = .playing
        session.roundScore = 0
        session.skippedWordsThisTurn = []
        session.wordDeck.shuffle()

        // Переиспользуем существующий timerService — НЕ пересоздаём,
        // иначе @ObservedObject в GameplayView потеряет подписку (BUG-001 fix)
        timerService.onExpire = { [weak self] in
            DispatchQueue.main.async {
                self?.endRound()
            }
        }
        timerService.start(duration: settings.roundDuration)
    }

    /// Слово угадано — начислить очко, перейти к следующему слову
    func wordGuessed() {
        guard session.state == .playing,
              var word = session.wordDeck.first else { return }

        // Помечаем слово как угаданное
        word.isGuessed = true
        session.guessedWords.append(word)
        session.wordDeck.removeFirst()
        session.roundScore += 1

        // Начисляем очко текущей команде
        if !session.teams.isEmpty {
            let idx = session.currentTeamIndex % session.teams.count
            session.teams[idx].score += 1
        }

        // Проверяем, остались ли слова
        if session.wordDeck.isEmpty {
            endRound()
        }
    }

    /// Слово пропущено — убрать из текущей позиции, вернуть в конец колоды
    func wordSkipped() {
        guard session.state == .playing,
              let word = session.wordDeck.first else { return }

        session.wordDeck.removeFirst()
        session.skippedWordsThisTurn.append(word)

        // Штраф за пропуск (если включено в настройках)
        if settings.penaltyForSkip, !session.teams.isEmpty {
            let idx = session.currentTeamIndex % session.teams.count
            session.teams[idx].score = max(0, session.teams[idx].score - 1)
            session.roundScore -= 1
        }

        // Пропущенное слово возвращается в колоду (в случайное место)
        let insertIndex = session.wordDeck.isEmpty
            ? 0
            : Int.random(in: 0...session.wordDeck.count)
        session.wordDeck.insert(word, at: insertIndex)

        // Если слов не осталось (все пропущены — маловероятно, но обрабатываем)
        if checkGameOver() {
            endGame()
        }
    }

    /// Завершить текущий раунд
    func endRound() {
        timerService.stop()

        // rotateExplainer() НЕ вызываем здесь — вызывается в GameViewModel.confirmTurnResults()
        // чтобы избежать двойной ротации (BUG-002 fix)

        // Проверяем окончание игры
        if checkGameOver() {
            endGame()
            return
        }

        session.state = .roundEnd
    }

    /// Переключиться на следующую команду и начать новый раунд
    func nextTeamTurn() {
        guard !session.teams.isEmpty else { return }

        // Переход к следующей команде
        session.currentTeamIndex = (session.currentTeamIndex + 1) % session.teams.count

        // Если прошли полный круг — увеличиваем номер раунда
        if session.currentTeamIndex == 0 {
            session.currentRound += 1
        }

        startRound()
    }

    // MARK: - Проверка окончания игры

    /// Проверить, закончилась ли игра (все слова угаданы)
    func checkGameOver() -> Bool {
        // Игра заканчивается, когда все слова угаданы (колода пуста)
        // Примечание: пропущенные слова возвращаются в колоду,
        // поэтому колода пуста только когда всё угадано
        let allGuessed = session.wordDeck.allSatisfy { $0.isGuessed }
        return session.wordDeck.isEmpty || allGuessed
    }

    // MARK: - Коррекция результатов

    /// Применяет пользовательские правки к результатам раунда.
    ///
    /// Единый источник правды для синхронизации `wordDeck`/`guessedWords` и пересчёта score.
    /// Вызывается из `GameViewModel.confirmTurnResults()` и `TeamsGameViewModel.confirmRound()`.
    ///
    /// - Parameters:
    ///   - turnResults: итоговый массив `TurnWordResult` после правок пользователем
    ///   - originalGuessedIds: идентификаторы слов, угаданных **до** правок (снимок начала хода)
    ///   - teamIdx: индекс команды, счёт которой нужно скорректировать
    func applyTurnCorrections(
        turnResults: [TurnWordResult],
        originalGuessedIds: Set<UUID>,
        teamIdx: Int
    ) {
        guard !session.teams.isEmpty, session.teams.indices.contains(teamIdx) else { return }

        var scoreDelta = 0

        for result in turnResults {
            let wasGuessed = originalGuessedIds.contains(result.id)

            if result.guessed && !wasGuessed {
                // Пропущенное → угаданное
                scoreDelta += 1
                if let deckIdx = session.wordDeck.firstIndex(where: { $0.id == result.id }) {
                    var word = session.wordDeck.remove(at: deckIdx)
                    word.isGuessed = true
                    session.guessedWords.append(word)
                }
            } else if !result.guessed && wasGuessed {
                // Угаданное → пропущенное
                scoreDelta -= 1
                if let guessedIdx = session.guessedWords.firstIndex(where: { $0.id == result.id }) {
                    var word = session.guessedWords.remove(at: guessedIdx)
                    word.isGuessed = false
                    let insertIdx = session.wordDeck.isEmpty
                        ? 0
                        : Int.random(in: 0...session.wordDeck.count)
                    session.wordDeck.insert(word, at: insertIdx)
                }
            }
        }

        if scoreDelta != 0 {
            session.teams[teamIdx].score = max(0, session.teams[teamIdx].score + scoreDelta)
        }
    }

    // MARK: - Результаты

    /// Команды, отсортированные по очкам (победители первые)
    var standings: [Team] {
        session.teams.sorted { $0.score > $1.score }
    }

    /// Команда-победитель
    var winner: Team? {
        standings.first
    }

    // MARK: - Приватные методы

    private func endGame() {
        timerService.stop()
        session.state = .gameOver
    }

    /// Сбросить игру для новой партии
    func resetGame() {
        timerService.stop()
        session = GameSession()
    }
}
