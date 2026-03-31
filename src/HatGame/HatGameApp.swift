import SwiftUI
import SwiftData

@main
struct HatGameApp: App {
    @StateObject private var languageManager = LanguageManager.shared
    @StateObject private var gameViewModel = GameViewModel()
    @StateObject private var setupViewModel = TeamSetupViewModel()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            GameSettingsEntity.self  // BUG-008: GameSettings теперь plain struct, @Model — GameSettingsEntity
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Не удалось создать ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            // id: языка пересоздаёт всё дерево вьюх при смене языка,
            // гарантируя перечитывание всех L10n-строк
            ContentView()
                .id(languageManager.currentLanguage.rawValue)
                .environmentObject(languageManager)
                .environmentObject(gameViewModel)
                .environmentObject(setupViewModel)
        }
        .modelContainer(sharedModelContainer)
    }
}
