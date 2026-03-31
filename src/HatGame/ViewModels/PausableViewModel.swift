import Foundation

/// Протокол для ViewModel которые управляют игровым таймером (gameplay VMs).
/// Убирает 3-строчный boilerplate из PairsGameViewModel,
/// TeamsGameViewModel и FreeForAllGameViewModel.
///
/// **GameViewModel намеренно не сконформирован** — это навигационный
/// координатор (home/settings/navigation), у него нет таймера и он
/// никогда не управляет паузой напрямую. Gameplay pause делегируется
/// mode-specific VM через PausableViewModel.
///
/// Реализация по умолчанию через extension требует доступа к timerService,
/// isPaused и isPausedBySystem — их предоставляют конкретные VM.
@MainActor
protocol PausableViewModel: AnyObject {
    var isPaused: Bool { get set }
    var isPausedBySystem: Bool { get set }
    var pauseTimerService: PausableTimerService { get }
}

/// Тонкий протокол над TimerService — позволяет не зависеть от конкретного типа.
protocol PausableTimerService {
    func pause()
    func resume()
}

extension PausableViewModel {
    func pauseGame() {
        pauseTimerService.pause()
        isPaused = true
        isPausedBySystem = false
    }

    func pauseBySystem() {
        pauseTimerService.pause()
        isPaused = true
        isPausedBySystem = true
    }

    func resumeGame() {
        pauseTimerService.resume()
        isPaused = false
        isPausedBySystem = false
    }
}
