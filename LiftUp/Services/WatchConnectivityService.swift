import Foundation
import WatchConnectivity

/// Service de connectivité avec l'Apple Watch (côté iPhone)
final class WatchConnectivityService: NSObject, ObservableObject {
    static let shared = WatchConnectivityService()

    @Published var isWatchAppInstalled = false
    @Published var isReachable = false

    private var session: WCSession?

    private override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    // MARK: - Send Data to Watch

    /// Envoie les données de la séance courante à la Watch
    func sendSessionData(_ data: WatchWorkoutDataDTO) {
        guard let session = session, session.isReachable else { return }

        do {
            let encoded = try JSONEncoder().encode(data)
            session.sendMessage(["currentSession": encoded], replyHandler: nil) { error in
                print("Error sending session to watch: \(error)")
            }
        } catch {
            print("Error encoding session data: \(error)")
        }
    }

    /// Envoie l'état du timer à la Watch
    func sendTimerState(seconds: Int, isRunning: Bool) {
        guard let session = session, session.isReachable else { return }

        session.sendMessage([
            "timerSeconds": seconds,
            "isTimerRunning": isRunning
        ], replyHandler: nil) { error in
            print("Error sending timer to watch: \(error)")
        }
    }

    /// Notifie la Watch que la séance est terminée
    func sendSessionEnded() {
        guard let session = session, session.isReachable else { return }

        session.sendMessage(["sessionEnded": true], replyHandler: nil, errorHandler: nil)
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityService: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isWatchAppInstalled = session.isWatchAppInstalled
            self.isReachable = session.isReachable
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            self.handleWatchMessage(message)
        }
    }

    private func handleWatchMessage(_ message: [String: Any]) {
        guard let action = message["action"] as? String else { return }

        // Ces actions seront relayées via NotificationCenter vers le SessionViewModel
        switch action {
        case "recordSet":
            if let reps = message["reps"] as? Int,
               let weight = message["weight"] as? Double {
                NotificationCenter.default.post(
                    name: .watchRecordSet,
                    object: nil,
                    userInfo: ["reps": reps, "weight": weight]
                )
            }

        case "skipSet":
            NotificationCenter.default.post(name: .watchSkipSet, object: nil)

        case "nextExercise":
            NotificationCenter.default.post(name: .watchNextExercise, object: nil)

        case "stopTimer":
            NotificationCenter.default.post(name: .watchStopTimer, object: nil)

        case "addTime":
            if let seconds = message["seconds"] as? Int {
                NotificationCenter.default.post(
                    name: .watchAddTime,
                    object: nil,
                    userInfo: ["seconds": seconds]
                )
            }

        default:
            break
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let watchRecordSet = Notification.Name("watchRecordSet")
    static let watchSkipSet = Notification.Name("watchSkipSet")
    static let watchNextExercise = Notification.Name("watchNextExercise")
    static let watchStopTimer = Notification.Name("watchStopTimer")
    static let watchAddTime = Notification.Name("watchAddTime")
}

// MARK: - DTO for Watch

struct WatchWorkoutDataDTO: Codable {
    let sessionType: String
    let currentExerciseName: String
    let currentExerciseIndex: Int
    let totalExercises: Int
    let currentSetNumber: Int
    let totalSets: Int
    let targetReps: String
    let previousSetDisplay: String?
    let suggestedWeight: Double
    let suggestedReps: Int

    init(from sessionExercise: SessionExercise, sessionType: SessionType, exerciseIndex: Int, totalExercises: Int, suggestion: ProgressionSuggestion?, previousSet: ExerciseSet?) {
        self.sessionType = sessionType.displayName
        self.currentExerciseName = sessionExercise.plannedExercise?.exercise?.name ?? "Exercice"
        self.currentExerciseIndex = exerciseIndex
        self.totalExercises = totalExercises

        let incompleteSets = sessionExercise.sortedSets.filter { !$0.isCompleted && !$0.isSkipped && !$0.isWarmup }
        self.currentSetNumber = incompleteSets.first?.setNumber ?? 1
        self.totalSets = sessionExercise.sets.filter { !$0.isWarmup }.count

        self.targetReps = sessionExercise.plannedExercise?.targetRepsDisplay ?? "8-12"
        self.previousSetDisplay = previousSet?.displayFormat
        self.suggestedWeight = suggestion?.suggestedWeight ?? 0
        self.suggestedReps = suggestion?.suggestedReps ?? 10
    }
}
