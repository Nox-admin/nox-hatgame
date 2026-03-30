import Foundation
import Combine

// MARK: - AppLanguage

enum AppLanguage: String, CaseIterable, Identifiable {
    case russian = "ru"
    case english = "en"
    case chinese = "zh-Hans"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .russian: return "Русский"
        case .english: return "English"
        case .chinese: return "中文"
        }
    }

    var flag: String {
        switch self {
        case .russian: return "🇷🇺"
        case .english: return "🇬🇧"
        case .chinese: return "🇨🇳"
        }
    }

    /// Имя JSON-файла с набором слов для данного языка
    var wordsFileName: String {
        switch self {
        case .russian: return "words"
        case .english: return "words_en"
        case .chinese: return "words_zh"
        }
    }
}

// MARK: - LanguageManager

/// Управляет текущим языком приложения в рантайме.
/// Использует `AppleLanguages` в UserDefaults для переопределения системного языка.
/// Требует перезапуска сессии (restartRequired = true) для применения к `String(localized:)`.
final class LanguageManager: ObservableObject {

    static let shared = LanguageManager()

    @Published private(set) var currentLanguage: AppLanguage

    /// После смены языка нужен перезапуск приложения для применения локализации
    @Published var restartRequired = false

    private init() {
        // Читаем сохранённый язык
        let saved = UserDefaults.standard.string(forKey: "app_language") ?? "ru"
        self.currentLanguage = AppLanguage(rawValue: saved) ?? .russian
        // Применяем к системе
        Self.applyLanguage(self.currentLanguage.rawValue)
    }

    func setLanguage(_ language: AppLanguage) {
        guard language != currentLanguage else { return }
        currentLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: "app_language")
        Self.applyLanguage(language.rawValue)
        restartRequired = true
    }

    // MARK: - Internal

    private static func applyLanguage(_ code: String) {
        UserDefaults.standard.set([code], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
    }

    /// Bundle для текущего языка — для ручной локализации строк
    var currentBundle: Bundle {
        let code = currentLanguage.rawValue
        if let path = Bundle.main.path(forResource: code, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        return Bundle.main
    }
}

// MARK: - String extension (convenience)

extension String {
    /// Локализует строку через LanguageManager с учётом текущего языка.
    /// Используй как: `"home.title".localized`
    var localized: String {
        let manager = LanguageManager.shared
        let bundle = manager.currentBundle
        let result = bundle.localizedString(forKey: self, value: nil, table: nil)
        return result.isEmpty ? self : result
    }

    /// Локализует строку с подстановкой аргументов.
    func localized(with arguments: CVarArg...) -> String {
        String(format: localized, arguments: arguments)
    }
}
