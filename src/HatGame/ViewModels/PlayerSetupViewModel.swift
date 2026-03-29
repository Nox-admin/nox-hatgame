import Foundation
import SwiftUI
import Combine

/// ViewModel для экрана ввода игроков — переиспользуется во всех игровых режимах v2
@MainActor
final class PlayerSetupViewModel: ObservableObject {

    // MARK: - Игроки

    @Published var players: [Player] = [
        Player(name: "Игрок 1"),
        Player(name: "Игрок 2")
    ]

    @Published var validationError: String? = nil

    // MARK: - Валидация

    /// Минимальное кол-во игроков
    let minPlayers = 2

    /// Можно начинать игру
    var canProceed: Bool {
        players.count >= minPlayers &&
        players.allSatisfy { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty } &&
        !hasDuplicateNames
    }

    /// Есть дублирующиеся имена
    var hasDuplicateNames: Bool {
        let names = players.map { $0.name.trimmingCharacters(in: .whitespaces).lowercased() }
        return Set(names).count != names.count
    }

    /// Можно удалить игрока (останется ≥ minPlayers)
    func canRemove(at index: Int) -> Bool {
        players.count > minPlayers
    }

    // MARK: - CRUD

    func addPlayer() {
        let number = players.count + 1
        var name = "Игрок \(number)"
        // Гарантируем уникальность имени по умолчанию
        var suffix = number
        let existingNames = Set(players.map { $0.name })
        while existingNames.contains(name) {
            suffix += 1
            name = "Игрок \(suffix)"
        }
        withAnimation(.spring(duration: 0.3)) {
            players.append(Player(name: name, emoji: ""))
        }
    }

    func setEmoji(_ emoji: String, at index: Int) {
        guard players.indices.contains(index) else { return }
        players[index].emoji = (players[index].emoji == emoji) ? "" : emoji
    }

    func removePlayer(at index: Int) {
        guard canRemove(at: index) else {
            validationError = "Нельзя удалить — нужно минимум \(minPlayers) игрока"
            return
        }
        withAnimation(.spring(duration: 0.3)) {
            players.remove(at: index)
        }
    }

    func renamePlayer(at index: Int, to newName: String) {
        guard players.indices.contains(index) else { return }
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        players[index].name = trimmed
        validateNames()
    }

    func movePlayer(from source: IndexSet, to destination: Int) {
        players.move(fromOffsets: source, toOffset: destination)
    }

    // MARK: - Валидация имён

    func validateNames() {
        if hasDuplicateNames {
            validationError = "У игроков не должно быть одинаковых имён"
        } else if players.contains(where: { $0.name.trimmingCharacters(in: .whitespaces).isEmpty }) {
            validationError = "Введи имя для каждого игрока"
        } else {
            validationError = nil
        }
    }

    func isDuplicateName(at index: Int) -> Bool {
        let name = players[index].name.trimmingCharacters(in: .whitespaces).lowercased()
        guard !name.isEmpty else { return false }
        let count = players.filter {
            $0.name.trimmingCharacters(in: .whitespaces).lowercased() == name
        }.count
        return count > 1
    }

    // MARK: - Аватары

    private static let avatarColors: [Color] = [
        .hatGold, .hatWarm, .hatSuccess, Color(hex: 0x7B6CF6),
        Color(hex: 0x4ECDC4), Color(hex: 0xFF6B9D), Color(hex: 0xA8E063), .hatDanger
    ]

    func avatarColor(for index: Int) -> Color {
        Self.avatarColors[index % Self.avatarColors.count]
    }
}
