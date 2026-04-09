import Foundation
import SwiftUI
import Combine

/// Результат слова в ходе (для экрана TurnEnd)
struct TurnWordResult: Identifiable, Equatable {
    let id: UUID
    let text: String
    var guessed: Bool
}

/// Главная ViewModel — связывает UI с игровым движком.
///
/// **Намеренно не реализует PausableViewModel** (TASK-006).
/// GameViewModel — навигационный координатор: управляет `navigationState`
/// и создаёт mode-specific VM (PairsGameViewModel, TeamsGameViewModel,
/// FreeForAllGameViewModel). У него нет таймера и он никогда не вызывается
/// с паузой. Pause/resume реализован в mode-specific VM через PausableViewModel.
@MainActor
final class GameViewModel: ObservableObject {

    // MARK: - Навигация

    @Published var navigationState: NavigationState = .home

    // MARK: - Игровой движок и сервисы

    @Published var engine: GameEngine
    @Published var settings: GameSettings

    // MARK: - Pending players (between PlayerSetup and ModeSelection)

    @Published var pendingPlayers: [Player] = []

    // MARK: - Mode-specific ViewModels

    @Published var pairsViewModel: PairsGameViewModel? = nil
    @Published var teamsViewModel: TeamsGameViewModel? = nil
    @Published var freeForAllViewModel: FreeForAllGameViewModel? = nil

    // MARK: - Turn results

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Инициализация

    init() {
        let settings = GameSettings.defaults
        self.settings = settings
        self.engine = GameEngine(settings: settings)
    }

    // MARK: - Навигация

    func navigateTo(_ state: NavigationState) {
        navigationState = state
    }

    /// Запуск игры из GameConfig (режим + команды + настройки)
    func startGame(with config: GameConfig) {
        // TASK-027: случайно выбираем hatSize слов; если слов меньше — берём все
        let deck = DeckService.loadDeck(level: config.difficulty.wordLevel, count: config.hatSize)
        engine.updateSettings(GameSettings(
            roundDuration: config.turnDuration,
            wordsCount: deck.count
        ))

        // Сброс предыдущих mode VM
        pairsViewModel = nil
        teamsViewModel = nil
        freeForAllViewModel = nil

        switch config.mode {
        case .pairs:
            let vm = PairsGameViewModel(config: config, deck: deck)
            pairsViewModel = vm
            // BUG-022: pipe child VM changes into GameViewModel so ContentView re-renders
            vm.objectWillChange
                .sink { [weak self] _ in self?.objectWillChange.send() }
                .store(in: &cancellables)
            navigationState = .pairsWaiting

        case .teams:
            let vm = TeamsGameViewModel(config: config)
            teamsViewModel = vm
            vm.objectWillChange
                .sink { [weak self] _ in self?.objectWillChange.send() }
                .store(in: &cancellables)
            navigationState = .teamsWaiting

        case .freeForAll:
            let vm = FreeForAllGameViewModel(config: config)
            freeForAllViewModel = vm
            vm.objectWillChange
                .sink { [weak self] _ in self?.objectWillChange.send() }
                .store(in: &cancellables)
            navigationState = .freeForAllWaiting
        }
    }

    func openSettings() {
        navigationState = .settings
    }

    func goHome() {
        engine.resetGame()
        pairsViewModel = nil
        teamsViewModel = nil
        freeForAllViewModel = nil
        navigationState = .home
    }

}
