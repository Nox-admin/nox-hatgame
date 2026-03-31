import Foundation
import Combine

/// Сервис обратного отсчёта для раундов
final class TimerService: ObservableObject {

    // MARK: - Публичные свойства

    /// Оставшееся время в секундах
    @Published private(set) var timeRemaining: Int

    /// Таймер активен
    @Published private(set) var isRunning: Bool = false

    /// Таймер на паузе
    @Published private(set) var isPaused: Bool = false

    /// Колбэк при истечении времени
    var onExpire: (() -> Void)?

    // MARK: - Приватные свойства

    private var timer: Timer?
    private let duration: Int

    // MARK: - Инициализация

    /// - Parameter duration: длительность в секундах (30, 60 или 90)
    init(duration: Int = 60) {
        self.duration = duration
        self.timeRemaining = duration
    }

    // MARK: - Управление таймером

    /// Запустить таймер
    func start() {
        stop()
        timeRemaining = duration
        isRunning = true
        isPaused = false
        scheduleTimer()
    }

    /// Запустить с новой длительностью
    func start(duration newDuration: Int) {
        stop()
        timeRemaining = newDuration
        isRunning = true
        isPaused = false
        scheduleTimer()
    }

    /// Поставить на паузу
    func pause() {
        guard isRunning, !isPaused else { return }
        timer?.invalidate()
        timer = nil
        isPaused = true
    }

    /// Возобновить после паузы
    func resume() {
        guard isRunning, isPaused else { return }
        isPaused = false
        scheduleTimer()
    }

    /// Полностью остановить таймер
    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
    }

    /// Сбросить таймер к начальному значению
    func reset() {
        stop()
        timeRemaining = duration
    }

    // MARK: - Форматирование

    /// Форматированное время "М:СС"
    var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Прогресс от 0.0 до 1.0
    var progress: Double {
        guard duration > 0 else { return 0 }
        return Double(timeRemaining) / Double(duration)
    }

    // MARK: - Приватные методы

    private func scheduleTimer() {
        timer = Timer.scheduledTimer(
            withTimeInterval: 1.0,
            repeats: true
        ) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        guard timeRemaining > 0 else { return }
        timeRemaining -= 1
        if timeRemaining <= 0 {
            // Время вышло!
            stop()
            onExpire?()
        }
    }

    deinit {
        timer?.invalidate()
    }
}

// MARK: - PausableTimerService

extension TimerService: PausableTimerService {}
