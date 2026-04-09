import Foundation

/// Игровая сессия — хранит всё состояние текущей игры
struct GameSession: Identifiable, Equatable {
    let id: UUID
    var teams: [Team]
    var currentRound: Int
    var currentTeamIndex: Int
    var wordDeck: [Word]           // Оставшиеся слова в шляпе
    var guessedWords: [Word]       // Угаданные слова (для статистики)
    var skippedWordsThisTurn: [Word] // Пропущенные в текущем ходе
    var roundScore: Int            // Очки за текущий ход
    var state: GameState

    init(
        id: UUID = UUID(),
        teams: [Team] = [],
        currentRound: Int = 1,
        currentTeamIndex: Int = 0,
        wordDeck: [Word] = [],
        state: GameState = .setup
    ) {
        self.id = id
        self.teams = teams
        self.currentRound = currentRound
        self.currentTeamIndex = currentTeamIndex
        self.wordDeck = wordDeck
        self.guessedWords = []
        self.skippedWordsThisTurn = []
        self.roundScore = 0
        self.state = state
    }

    /// Текущая команда
    var currentTeam: Team? {
        guard !teams.isEmpty else { return nil }
        return teams[currentTeamIndex % teams.count]
    }

    /// Текущее слово (верхнее в колоде)
    var currentWord: Word? {
        wordDeck.first
    }

    /// Осталось слов в шляпе
    var wordsRemaining: Int {
        wordDeck.count
    }
}

/// Состояние игры (конечный автомат)
enum GameState: String, Equatable {
    case setup       // Настройка команд и параметров
    case playing     // Идёт раунд — объяснение слов
    case roundEnd    // Раунд завершён — показ результатов хода
    case gameOver    // Все слова угаданы — финальные результаты
}
