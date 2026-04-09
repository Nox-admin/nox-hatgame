import Foundation

/// Команда
struct Team: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var players: [Player]
    var score: Int
    /// Индекс текущего объясняющего игрока (ротация внутри команды)
    var currentExplainerIndex: Int

    init(
        id: UUID = UUID(),
        name: String,
        players: [Player] = [],
        score: Int = 0,
        currentExplainerIndex: Int = 0
    ) {
        self.id = id
        self.name = name
        self.players = players
        self.score = score
        self.currentExplainerIndex = currentExplainerIndex
    }

    /// Текущий объясняющий игрок
    var currentExplainer: Player? {
        guard !players.isEmpty else { return nil }
        return players[currentExplainerIndex % players.count]
    }

    /// Переход к следующему объясняющему
    mutating func rotateExplainer() {
        guard !players.isEmpty else { return }
        currentExplainerIndex = (currentExplainerIndex + 1) % players.count
    }
}
