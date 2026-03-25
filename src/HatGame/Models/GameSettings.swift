import Foundation
import SwiftData

// MARK: - Plain struct (используется в игровой логике и ViewModels)

/// Настройки игры — plain struct, безопасен в Preview и тестах (BUG-007 fix)
struct GameSettings {
    /// Длительность раунда в секундах
    var roundDuration: Int
    /// Количество слов в колоде
    var wordsCount: Int
    /// Уровень сложности (nil = все уровни / микс)
    var difficulty: WordLevel?
    /// Разрешить пропуск слов
    var allowSkipping: Bool
    /// Штраф за пропуск (-1 очко)
    var penaltyForSkip: Bool

    init(
        roundDuration: Int = 60,
        wordsCount: Int = 30,
        difficulty: WordLevel? = nil,
        allowSkipping: Bool = true,
        penaltyForSkip: Bool = false
    ) {
        self.roundDuration = roundDuration
        self.wordsCount = wordsCount
        self.difficulty = difficulty
        self.allowSkipping = allowSkipping
        self.penaltyForSkip = penaltyForSkip
    }

    /// Доступные варианты длительности раунда
    static let availableDurations = [15, 30, 45, 60, 90]

    /// Настройки по умолчанию — безопасно создаётся без ModelContext
    static let defaults = GameSettings()
}

// MARK: - SwiftData entity (только для персистентности в SettingsView)

/// Персистентная модель настроек — используется только для сохранения/загрузки,
/// не передаётся напрямую в игровую логику
@Model
final class GameSettingsEntity {
    var roundDuration: Int = 60
    var wordsCount: Int = 30
    var difficultyRaw: String? = nil
    var allowSkipping: Bool = true
    var penaltyForSkip: Bool = false

    init() {}

    /// Конвертировать в plain struct для использования в логике
    func toSettings() -> GameSettings {
        GameSettings(
            roundDuration: roundDuration,
            wordsCount: wordsCount,
            difficulty: difficultyRaw.flatMap(WordLevel.init),
            allowSkipping: allowSkipping,
            penaltyForSkip: penaltyForSkip
        )
    }

    /// Обновить из plain struct
    func update(from settings: GameSettings) {
        roundDuration = settings.roundDuration
        wordsCount = settings.wordsCount
        difficultyRaw = settings.difficulty?.rawValue
        allowSkipping = settings.allowSkipping
        penaltyForSkip = settings.penaltyForSkip
    }
}
