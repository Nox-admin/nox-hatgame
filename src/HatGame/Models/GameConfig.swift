import Foundation

// MARK: - Игровой режим

enum GameMode: String, CaseIterable, Identifiable {
    case pairs      // Попарный — объясняют по парам по кругу
    case teams      // Командный — N команд, ротация объяснителей внутри команды
    case freeForAll // Все сразу — один объясняет всем

    var id: String { rawValue }

    /// Оригинальный (русский) заголовок — используется где локализация не нужна (логи и т.д.)
    var title: String {
        switch self {
        case .pairs: return "Попарный"
        case .teams: return "Командный"
        case .freeForAll: return "Все сразу"
        }
    }

    /// Локализованный заголовок для отображения в UI
    var localizedTitle: String {
        switch self {
        case .pairs: return L10n.Mode.pairsTitle
        case .teams: return L10n.Mode.teamsTitle
        case .freeForAll: return L10n.Mode.ffaTitle
        }
    }

    var description: String {
        switch self {
        case .pairs: return "Игроки объясняют по парам. Каждый побывает объяснителем."
        case .teams: return "Разбейтесь на команды. Команды соревнуются между собой."
        case .freeForAll: return "Один объясняет — все остальные угадывают. Побеждает тот, кто угадает больше."
        }
    }

    /// Локализованное описание режима для UI
    var localizedDescription: String {
        switch self {
        case .pairs: return L10n.Mode.pairsDesc
        case .teams: return L10n.Mode.teamsDesc
        case .freeForAll: return L10n.Mode.ffaDesc
        }
    }

    var symbolName: String {
        switch self {
        case .pairs: return "person.2.fill"
        case .teams: return "person.3.fill"
        case .freeForAll: return "star.fill"
        }
    }

    var minPlayers: Int {
        switch self {
        case .pairs: return 2
        case .teams: return 4  // минимум 2 команды по 2 игрока
        case .freeForAll: return 2
        }
    }
}

// MARK: - Конфигурация игры

/// Полная конфигурация игры — передаётся в GameEngine
struct GameConfig {
    let players: [Player]
    let mode: GameMode
    let teams: [Team]          // Для .teams mode; для остальных — авто-сгенерированные
    let difficulty: DifficultyLevel
    let turnDuration: Int      // секунды
    let showScoreDuringGame: Bool
    let allowSkip: Bool        // BUG-030: показывать кнопку "Пропустить" во время раунда
    let hatSize: Int           // TASK-027: сколько слов случайно попадает в шляпу

    // MARK: - Фабрики

    /// Попарный режим: авто-создание пар из списка игроков
    static func pairs(players: [Player], difficulty: DifficultyLevel, turnDuration: Int, allowSkip: Bool = false, hatSize: Int = 100) -> GameConfig {
        // Разбиваем на пары: [A,B], [C,D], ...
        // Нечётный игрок присоединяется к последней паре
        var teams: [Team] = []
        var shuffledPlayers = players
        var teamIndex = 1
        while shuffledPlayers.count >= 2 {
            let p1 = shuffledPlayers.removeFirst()
            let p2 = shuffledPlayers.removeFirst()
            teams.append(Team(name: L10n.GameConfig.pairName(teamIndex), players: [p1, p2]))
            teamIndex += 1
        }
        if let odd = shuffledPlayers.first, !teams.isEmpty {
            // Нечётный игрок добавляется в первую пару
            teams[0].players.append(odd)
        }
        return GameConfig(players: players, mode: .pairs, teams: teams,
                          difficulty: difficulty, turnDuration: turnDuration,
                          showScoreDuringGame: false, allowSkip: allowSkip, hatSize: hatSize)
    }

    /// Режим "Все сразу": все игроки в одной группе
    static func freeForAll(players: [Player], difficulty: DifficultyLevel, turnDuration: Int, allowSkip: Bool = false, hatSize: Int = 100) -> GameConfig {
        let team = Team(name: L10n.GameConfig.allPlayersTeam, players: players)
        return GameConfig(players: players, mode: .freeForAll, teams: [team],
                          difficulty: difficulty, turnDuration: turnDuration,
                          showScoreDuringGame: true, allowSkip: allowSkip, hatSize: hatSize)
    }

    /// Командный режим: команды заданы вручную
    static func teamMode(players: [Player], teams: [Team], difficulty: DifficultyLevel, turnDuration: Int, allowSkip: Bool = false, hatSize: Int = 100) -> GameConfig {
        GameConfig(players: players, mode: .teams, teams: teams,
                   difficulty: difficulty, turnDuration: turnDuration,
                   showScoreDuringGame: true, allowSkip: allowSkip, hatSize: hatSize)
    }
}
