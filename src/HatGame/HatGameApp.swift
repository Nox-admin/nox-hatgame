import SwiftUI
import SwiftData

@main
struct HatGameApp: App {
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
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
