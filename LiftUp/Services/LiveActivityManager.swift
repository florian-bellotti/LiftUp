import ActivityKit
import Foundation

/// Gestionnaire des Live Activities pour le timer de repos
@MainActor
final class LiveActivityManager: ObservableObject {
    // MARK: - Singleton

    static let shared = LiveActivityManager()

    // MARK: - Properties

    @Published private(set) var currentActivity: Activity<TimerActivityAttributes>?
    @Published private(set) var isActivityActive = false

    private var updateTask: Task<Void, Never>?

    // MARK: - Init

    private init() {}

    // MARK: - Public Methods

    /// Démarre une Live Activity pour le timer de repos
    func startTimerActivity(
        exerciseName: String,
        setNumber: Int,
        totalSets: Int,
        totalSeconds: Int
    ) {
        // Vérifier que les Live Activities sont supportées
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities ne sont pas activées")
            return
        }

        // Arrêter l'activité précédente si elle existe
        stopActivity()

        let attributes = TimerActivityAttributes(
            exerciseName: exerciseName,
            setNumber: setNumber,
            totalSets: totalSets
        )

        let initialState = TimerActivityAttributes.ContentState(
            remainingSeconds: totalSeconds,
            totalSeconds: totalSeconds,
            isPaused: false
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
            isActivityActive = true
            print("Live Activity démarrée: \(activity.id)")
        } catch {
            print("Erreur lors du démarrage de la Live Activity: \(error)")
        }
    }

    /// Met à jour le temps restant de la Live Activity
    func updateTimer(remainingSeconds: Int, totalSeconds: Int, isPaused: Bool = false) {
        guard let activity = currentActivity else { return }

        let updatedState = TimerActivityAttributes.ContentState(
            remainingSeconds: remainingSeconds,
            totalSeconds: totalSeconds,
            isPaused: isPaused
        )

        Task {
            await activity.update(
                ActivityContent(
                    state: updatedState,
                    staleDate: nil
                )
            )
        }
    }

    /// Arrête la Live Activity
    func stopActivity() {
        guard let activity = currentActivity else { return }

        let finalState = TimerActivityAttributes.ContentState(
            remainingSeconds: 0,
            totalSeconds: 0,
            isPaused: false
        )

        Task {
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )
        }

        currentActivity = nil
        isActivityActive = false
        updateTask?.cancel()
        updateTask = nil
    }

    /// Termine la Live Activity avec un état "terminé"
    func finishActivity() {
        guard let activity = currentActivity else { return }

        let finishedState = TimerActivityAttributes.ContentState(
            remainingSeconds: 0,
            totalSeconds: 0,
            isPaused: false
        )

        Task {
            // Laisser l'activité visible pendant 2 secondes avant de la fermer
            await activity.update(
                ActivityContent(state: finishedState, staleDate: nil)
            )

            try? await Task.sleep(nanoseconds: 2_000_000_000)

            await activity.end(
                ActivityContent(state: finishedState, staleDate: nil),
                dismissalPolicy: .immediate
            )
        }

        currentActivity = nil
        isActivityActive = false
    }

    // MARK: - Helpers

    /// Vérifie si les Live Activities sont disponibles
    var areActivitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }
}
