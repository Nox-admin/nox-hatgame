import Foundation

// MARK: - Результат игры (единый для всех режимов)

enum GameResult {
    case players(standings: [(player: Player, score: Int)], mode: GameMode)
    case teams(standings: [Team])

    var title: String {
        switch self {
        case .players: return "Игра завершена!"
        case .teams:   return "Игра завершена!"
        }
    }

    var winnerName: String? {
        switch self {
        case .players(let standings, _):
            return standings.first?.player.name
        case .teams(let standings):
            return standings.first?.name
        }
    }

    var winnerScore: Int {
        switch self {
        case .players(let standings, _):
            return standings.first?.score ?? 0
        case .teams(let standings):
            return standings.first?.score ?? 0
        }
    }

    var isEmpty: Bool {
        switch self {
        case .players(let s, _): return s.isEmpty
        case .teams(let s):      return s.isEmpty
        }
    }
}
