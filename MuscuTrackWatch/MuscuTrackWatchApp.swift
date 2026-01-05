import SwiftUI
import WatchConnectivity

@main
struct MuscuTrackWatchApp: App {
    @StateObject private var connectivityManager = WatchConnectivityManager()

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
                .environmentObject(connectivityManager)
        }
    }
}

/// Gestionnaire de la connexion iPhone <-> Watch
class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    @Published var isConnected = false
    @Published var currentSession: WatchWorkoutData?
    @Published var timerSeconds: Int = 0
    @Published var isTimerRunning = false

    private var session: WCSession?

    override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = activationState == .activated
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            self.handleMessage(message)
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            self.handleMessage(applicationContext)
        }
    }

    // MARK: - Message Handling

    private func handleMessage(_ message: [String: Any]) {
        if let sessionData = message["currentSession"] as? Data {
            do {
                currentSession = try JSONDecoder().decode(WatchWorkoutData.self, from: sessionData)
            } catch {
                print("Error decoding session: \(error)")
            }
        }

        if let timer = message["timerSeconds"] as? Int {
            timerSeconds = timer
        }

        if let running = message["isTimerRunning"] as? Bool {
            isTimerRunning = running
        }
    }

    // MARK: - Send to iPhone

    func sendToiPhone(_ message: [String: Any]) {
        guard let session = session, session.isReachable else { return }
        session.sendMessage(message, replyHandler: nil) { error in
            print("Error sending message: \(error)")
        }
    }

    func recordSet(reps: Int, weight: Double) {
        sendToiPhone([
            "action": "recordSet",
            "reps": reps,
            "weight": weight
        ])
    }

    func skipSet() {
        sendToiPhone(["action": "skipSet"])
    }

    func nextExercise() {
        sendToiPhone(["action": "nextExercise"])
    }

    func stopTimer() {
        sendToiPhone(["action": "stopTimer"])
    }

    func addTimerTime(_ seconds: Int) {
        sendToiPhone([
            "action": "addTime",
            "seconds": seconds
        ])
    }
}

/// Données de séance simplifiées pour la Watch
struct WatchWorkoutData: Codable {
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
}
