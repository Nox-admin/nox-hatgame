import Foundation
import SwiftUI

/// Слово для игры
struct Word: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    let level: WordLevel
    let category: String
    var isGuessed: Bool

    init(
        id: UUID = UUID(),
        text: String,
        level: WordLevel = .easy,
        category: String = "",
        isGuessed: Bool = false
    ) {
        self.id = id
        self.text = text
        self.level = level
        self.category = category
        self.isGuessed = isGuessed
    }
}

/// Уровень сложности слова
enum WordLevel: String, Codable, CaseIterable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"

    var displayName: String {
        switch self {
        case .easy: return "Лёгкий"
        case .medium: return "Средний"
        case .hard: return "Сложный"
        }
    }

    var difficultyColor: Color {
        switch self {
        case .easy: return .green
        case .medium: return .yellow
        case .hard: return .red
        }
    }
}
