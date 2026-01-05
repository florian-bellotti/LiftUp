import Foundation
import Combine
import ActivityKit

/// ViewModel pour une séance en cours
@MainActor
final class SessionViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var session: WorkoutSession
    @Published var currentExerciseIndex: Int = 0
    @Published var previousSession: WorkoutSession?

    @Published var showingExerciseDetail = false
    @Published var showingSummary = false
    @Published var showingCancelConfirmation = false

    // MARK: - Timer

    @Published var isTimerRunning = false
    @Published var timerSeconds = 0
    @Published var targetRestSeconds = 120

    private var timerTask: Task<Void, Never>?

    // MARK: - Dependencies

    private let dataService: DataService
    private let progressionService = ProgressionService()

    // MARK: - Computed Properties

    var currentExercise: SessionExercise? {
        guard currentExerciseIndex < session.sortedExercises.count else { return nil }
        return session.sortedExercises[currentExerciseIndex]
    }

    var exerciseCount: Int {
        session.exercises.count
    }

    var completedExerciseCount: Int {
        session.exercises.filter { $0.isCompleted || $0.isSkipped }.count
    }

    var progress: Double {
        session.progress
    }

    var isLastExercise: Bool {
        currentExerciseIndex >= exerciseCount - 1
    }

    var canGoNext: Bool {
        currentExerciseIndex < exerciseCount - 1
    }

    var canGoPrevious: Bool {
        currentExerciseIndex > 0
    }

    // MARK: - Init

    init(session: WorkoutSession, dataService: DataService) {
        self.session = session
        self.dataService = dataService

        // Trouver le premier exercice non complété
        if let firstIncomplete = session.sortedExercises.firstIndex(where: { !$0.isCompleted && !$0.isSkipped }) {
            currentExerciseIndex = firstIncomplete
        }
    }

    // MARK: - Lifecycle

    func loadPreviousSession() async {
        previousSession = try? await dataService.workoutRepository.getPreviousSession(
            forType: session.sessionType,
            before: session.startedAt
        )
    }

    // MARK: - Navigation

    func nextExercise() {
        guard canGoNext else {
            showingSummary = true
            return
        }

        stopTimer()
        currentExerciseIndex += 1
    }

    func previousExercise() {
        guard canGoPrevious else { return }
        stopTimer()
        currentExerciseIndex -= 1
    }

    func goToExercise(at index: Int) {
        guard index >= 0 && index < exerciseCount else { return }
        stopTimer()
        currentExerciseIndex = index
    }

    // MARK: - Set Management

    func recordSet(_ set: ExerciseSet, reps: Int, weight: Double) {
        set.reps = reps
        set.weight = weight
        set.markCompleted()

        saveSession()

        // Démarrer le timer de repos automatiquement
        if let exercise = currentExercise?.plannedExercise {
            targetRestSeconds = exercise.restTimeSeconds
        }
        startTimer()
    }

    func skipSet(_ set: ExerciseSet) {
        set.markSkipped()
        saveSession()
    }

    func updateSet(_ set: ExerciseSet, reps: Int, weight: Double) {
        set.reps = reps
        set.weight = weight
        saveSession()
    }

    // MARK: - Exercise Management

    func completeCurrentExercise() {
        currentExercise?.markCompleted()
        saveSession()
        nextExercise()
    }

    func skipCurrentExercise() {
        currentExercise?.markSkipped()
        saveSession()
        nextExercise()
    }

    // MARK: - Timer

    func startTimer() {
        timerSeconds = targetRestSeconds
        isTimerRunning = true

        // Démarrer la Live Activity
        if let exercise = currentExercise {
            let exerciseName = exercise.plannedExercise?.exercise?.name ?? "Exercice"
            let completedSets = exercise.sortedSets.filter { $0.isCompleted }.count
            let totalSets = exercise.sortedSets.count

            LiveActivityManager.shared.startTimerActivity(
                exerciseName: exerciseName,
                setNumber: completedSets,
                totalSets: totalSets,
                totalSeconds: targetRestSeconds
            )
        }

        timerTask?.cancel()
        timerTask = Task {
            while !Task.isCancelled && timerSeconds > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if !Task.isCancelled {
                    timerSeconds -= 1
                    // Mettre à jour la Live Activity
                    LiveActivityManager.shared.updateTimer(
                        remainingSeconds: timerSeconds,
                        totalSeconds: targetRestSeconds
                    )
                }
            }
            if !Task.isCancelled {
                isTimerRunning = false
                // Terminer la Live Activity
                LiveActivityManager.shared.finishActivity()
            }
        }
    }

    func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
        isTimerRunning = false
        timerSeconds = 0
        // Arrêter la Live Activity
        LiveActivityManager.shared.stopActivity()
    }

    func addTime(_ seconds: Int) {
        timerSeconds += seconds
        // Mettre à jour la Live Activity avec le nouveau temps
        LiveActivityManager.shared.updateTimer(
            remainingSeconds: timerSeconds,
            totalSeconds: targetRestSeconds + seconds
        )
    }

    var timerDisplay: String {
        let minutes = timerSeconds / 60
        let seconds = timerSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Session Completion

    func completeSession() {
        stopTimer()
        session.complete()
        saveSession()
        showingSummary = true
    }

    func cancelSession() {
        stopTimer()
        showingCancelConfirmation = true
    }

    // MARK: - Previous Data

    func getPreviousSetsForCurrentExercise() -> [ExerciseSet] {
        guard let current = currentExercise,
              let exerciseId = current.plannedExercise?.exercise?.id,
              let previous = previousSession else {
            return []
        }

        let previousExercise = previous.exercises.first {
            $0.plannedExercise?.exercise?.id == exerciseId
        }

        return previousExercise?.sortedSets.filter { $0.isCompleted } ?? []
    }

    func getSuggestionForCurrentExercise() -> ProgressionSuggestion? {
        guard let plannedExercise = currentExercise?.plannedExercise else { return nil }

        let previousSets = getPreviousSetsForCurrentExercise()
        return progressionService.suggestProgression(for: plannedExercise, previousSets: previousSets)
    }

    // MARK: - Analysis

    func getSessionAnalysis() -> SessionAnalysis {
        progressionService.analyzeSession(current: session, previous: previousSession)
    }

    // MARK: - Persistence

    private func saveSession() {
        Task {
            try? await dataService.workoutRepository.saveWorkoutSession(session)
        }
    }

    deinit {
        timerTask?.cancel()
    }
}
