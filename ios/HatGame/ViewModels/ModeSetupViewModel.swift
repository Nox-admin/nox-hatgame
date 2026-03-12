import Foundation
import SwiftUI

/// ViewModel для ModeSelectionView + TeamBuilderView
@MainActor
final class ModeSetupViewModel: ObservableObject {

    // MARK: - Входные данные

    let players: [Player]

    // MARK: - Выбор режима

    @Published var selectedMode: GameMode = .pairs

    // MARK: - Настройки игры

    @Published var difficulty: DifficultyLevel = .medium
    @Published var turnDurationIndex: Int = 3  // 60с по умолчанию
    @Published var allowSkip: Bool = false      // BUG-030: кнопка "Пропустить" вкл/выкл
    @Published var hatSizeIndex: Int = 3        // TASK-027: индекс в allowedHatSizes, 100 по умолчанию

    static let allowedDurations = [15, 30, 45, 60, 90]
    static let allowedHatSizes = [30, 50, 75, 100, 150, 200]

    var turnDuration: Int {
        Self.allowedDurations[turnDurationIndex]
    }

    // MARK: - Командный режим: сборка команд

    /// Команды (только для .teams mode)
    @Published var teams: [TeamDraft] = []

    /// Игроки не распределённые по командам
    var unassignedPlayers: [Player] {
        let assignedIds = Set(teams.flatMap { $0.players.map(\.id) })
        return players.filter { !assignedIds.contains($0.id) }
    }

    // MARK: - Инициализация

    init(players: [Player]) {
        self.players = players
        resetTeams()
    }

    // MARK: - Управление командами

    func resetTeams() {
        // По умолчанию: 2 пустые команды
        teams = [
            TeamDraft(name: "Команда 1"),
            TeamDraft(name: "Команда 2")
        ]
    }

    func addTeam() {
        let number = teams.count + 1
        teams.append(TeamDraft(name: "Команда \(number)"))
    }

    func removeTeam(at index: Int) {
        guard teams.count > 2 else { return }
        teams.remove(at: index)
    }

    func renameTeam(at index: Int, to name: String) {
        guard teams.indices.contains(index) else { return }
        teams[index].name = name
    }

    // MARK: - Управление игроками в командах

    func assignPlayer(_ player: Player, to teamIndex: Int) {
        guard teams.indices.contains(teamIndex) else { return }
        // Убираем из других команд (на всякий случай)
        removePlayerFromAllTeams(player)
        teams[teamIndex].players.append(player)
    }

    func removePlayerFromTeam(_ player: Player, teamIndex: Int) {
        guard teams.indices.contains(teamIndex) else { return }
        teams[teamIndex].players.removeAll { $0.id == player.id }
    }

    func removePlayerFromAllTeams(_ player: Player) {
        for i in teams.indices {
            teams[i].players.removeAll { $0.id == player.id }
        }
    }

    func autoDistribute() {
        // Сброс и автораспределение равномерно по командам
        for i in teams.indices { teams[i].players = [] }
        let shuffled = players.shuffled()
        for (idx, player) in shuffled.enumerated() {
            let teamIdx = idx % teams.count
            teams[teamIdx].players.append(player)
        }
    }

    // MARK: - Валидация

    var canProceed: Bool {
        switch selectedMode {
        case .pairs:
            return players.count >= 2
        case .teams:
            return isTeamConfigValid
        case .freeForAll:
            return players.count >= 2
        }
    }

    var isTeamConfigValid: Bool {
        guard teams.count >= 2 else { return false }
        guard unassignedPlayers.isEmpty else { return false }
        guard teams.allSatisfy({ $0.players.count >= 1 }) else { return false }
        return true
    }

    var validationMessage: String? {
        switch selectedMode {
        case .teams:
            if teams.count < 2 { return "Нужно минимум 2 команды" }
            if !unassignedPlayers.isEmpty { return "Распредели всех игроков по командам" }
            if let empty = teams.first(where: { $0.players.isEmpty }) {
                return "В команде «\(empty.name)» нет игроков"
            }
            return nil
        default:
            return players.count < 2 ? "Нужно минимум 2 игрока" : nil
        }
    }

    // MARK: - Сборка GameConfig

    var hatSize: Int { Self.allowedHatSizes[hatSizeIndex] }

    func buildConfig() -> GameConfig {
        switch selectedMode {
        case .pairs:
            return .pairs(players: players, difficulty: difficulty,
                          turnDuration: turnDuration, allowSkip: allowSkip, hatSize: hatSize)
        case .freeForAll:
            return .freeForAll(players: players, difficulty: difficulty,
                               turnDuration: turnDuration, allowSkip: allowSkip, hatSize: hatSize)
        case .teams:
            let builtTeams = teams.map { draft in
                Team(name: draft.name, players: draft.players)
            }
            return .teamMode(players: players, teams: builtTeams,
                             difficulty: difficulty, turnDuration: turnDuration,
                             allowSkip: allowSkip, hatSize: hatSize)
        }
    }
}

// MARK: - TeamDraft — изменяемая черновая команда

struct TeamDraft: Identifiable {
    let id: UUID = UUID()
    var name: String
    var players: [Player] = []
}
