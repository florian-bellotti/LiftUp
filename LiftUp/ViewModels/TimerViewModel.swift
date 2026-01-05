import Foundation
import Combine
import UserNotifications

/// ViewModel dédié au timer de repos
@MainActor
final class TimerViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var remainingSeconds: Int = 0
    @Published var totalSeconds: Int = 0
    @Published var isRunning = false
    @Published var isPaused = false

    // MARK: - Private

    private var timerTask: Task<Void, Never>?
    private var startTime: Date?
    private var pausedTime: Date?

    // MARK: - Computed Properties

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return 1.0 - (Double(remainingSeconds) / Double(totalSeconds))
    }

    var displayTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var isFinished: Bool {
        remainingSeconds <= 0 && totalSeconds > 0
    }

    // MARK: - Timer Control

    func start(seconds: Int) {
        totalSeconds = seconds
        remainingSeconds = seconds
        isRunning = true
        isPaused = false
        startTime = Date()

        runTimer()
    }

    func pause() {
        guard isRunning && !isPaused else { return }
        timerTask?.cancel()
        isPaused = true
        pausedTime = Date()
    }

    func resume() {
        guard isRunning && isPaused else { return }
        isPaused = false
        runTimer()
    }

    func stop() {
        timerTask?.cancel()
        timerTask = nil
        isRunning = false
        isPaused = false
        remainingSeconds = 0
        totalSeconds = 0
    }

    func addTime(_ seconds: Int) {
        remainingSeconds += seconds
        totalSeconds += seconds
    }

    func reset() {
        remainingSeconds = totalSeconds
        if isRunning && !isPaused {
            timerTask?.cancel()
            runTimer()
        }
    }

    // MARK: - Private

    private func runTimer() {
        timerTask?.cancel()
        timerTask = Task {
            while !Task.isCancelled && remainingSeconds > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if !Task.isCancelled {
                    remainingSeconds -= 1
                }
            }
            if !Task.isCancelled && remainingSeconds <= 0 {
                await timerFinished()
            }
        }
    }

    private func timerFinished() async {
        isRunning = false

        // Envoyer une notification locale
        await sendNotification()

        // TODO: Vibration haptic feedback
    }

    private func sendNotification() async {
        let content = UNMutableNotificationContent()
        content.title = "Repos terminé"
        content.body = "C'est reparti ! 💪"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        try? await UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Notification Permissions

    func requestNotificationPermission() {
        Task {
            let center = UNUserNotificationCenter.current()
            try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        }
    }

    deinit {
        timerTask?.cancel()
    }
}

// MARK: - Preset Rest Times

extension TimerViewModel {
    static let presetRestTimes: [(label: String, seconds: Int)] = [
        ("1 min", 60),
        ("1:30", 90),
        ("2 min", 120),
        ("2:30", 150),
        ("3 min", 180),
        ("4 min", 240),
        ("5 min", 300)
    ]
}
