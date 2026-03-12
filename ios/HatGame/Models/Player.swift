import Foundation

/// Игрок
struct Player: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var teamId: UUID?

    init(id: UUID = UUID(), name: String, teamId: UUID? = nil) {
        self.id = id
        self.name = name
        self.teamId = teamId
    }
}
