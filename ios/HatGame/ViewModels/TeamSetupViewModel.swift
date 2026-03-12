import Foundation
import SwiftUI

/// ViewModel для настройки игроков и параметров партии
@MainActor
final class TeamSetupViewModel: ObservableObject {

    // MARK: - Игроки

    @Published var players: [Player] = [
        Player(name: "Игрок 1"),
        Player(name: "Игрок 2"),
        Player(name: "Игрок 3"),
        Player(name: "Игрок 4")
    ]

    @Published var editingPlayerIndex: Int? = nil
    @Published var errorMessage: String?

    // MARK: - Параметры

    // BUG-012: wordsPerPlayer убран — в "Шляпе" используются ВСЕ слова выбранного уровня из общей шляпы
    @Published var turnDurationIndex: Int = 3 // index into allowedDurations → 60s
    @Published var difficulty: DifficultyLevel = .medium

    static let allowedDurations = [15, 30, 45, 60, 90]
    static let playerAvatars = ["person.fill", "person.fill", "person.fill", "person.fill", "person.fill", "person.fill"]

    var turnDuration: Int {
        Self.allowedDurations[turnDurationIndex]
    }

    // MARK: - Управление игроками

    func addPlayer() {
        let number = players.count + 1
        players.append(Player(name: "Игрок \(number)"))
    }

    func removePlayer(at index: Int) {
        guard players.count > 2 else {
            errorMessage = "Минимум 2 игрока"
            return
        }
        players.remove(at: index)
    }

    func removePlayer(at offsets: IndexSet) {
        guard players.count - offsets.count >= 2 else {
            errorMessage = "Минимум 2 игрока"
            return
        }
        players.remove(atOffsets: offsets)
    }

    func renamePlayer(at index: Int, to name: String) {
        guard players.indices.contains(index) else { return }
        players[index].name = name
    }

    func avatarEmoji(for index: Int) -> String {
        Self.playerAvatars[index % Self.playerAvatars.count]
    }

    // MARK: - Stepper helpers

    func incrementDuration() {
        if turnDurationIndex < Self.allowedDurations.count - 1 {
            turnDurationIndex += 1
        }
    }

    func decrementDuration() {
        if turnDurationIndex > 0 {
            turnDurationIndex -= 1
        }
    }

    // MARK: - Валидация

    var isValid: Bool {
        players.count >= 2 &&
        players.allSatisfy { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
    }
}
