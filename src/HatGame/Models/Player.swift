import Foundation

/// Игрок
struct Player: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var teamId: UUID?
    var emoji: String

    init(id: UUID = UUID(), name: String, teamId: UUID? = nil, emoji: String = "") {
        self.id = id
        self.name = name
        self.teamId = teamId
        self.emoji = emoji
    }

    /// Отображаемый аватар: эмодзи если задан, иначе первая буква имени
    var avatarEmoji: String? { emoji.isEmpty ? nil : emoji }
}

// MARK: - Emoji palette
extension Player {
    static let emojiPalette: [String] = [
        "🦊", "🐸", "🎩", "👾", "🦄", "🐯", "🦁", "🐧",
        "🦉", "🐺", "🎃", "👻", "🤖", "👽", "🦸", "🧙",
        "🐉", "🦋", "🌈", "⚡️"
    ]
}
