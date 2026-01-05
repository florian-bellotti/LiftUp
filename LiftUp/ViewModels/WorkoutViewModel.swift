import Foundation
import SwiftData
import Combine

/// ViewModel principal pour la gestion des séances
@MainActor
final class WorkoutViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var currentWeekProgram: WeekProgram?
    @Published var weekSessions: [WorkoutSession] = []
    @Published var selectedSession: SessionTemplate?
    @Published var activeWorkout: WorkoutSession?

    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Dependencies

    private let dataService: DataService
    private let progressionService = ProgressionService()

    // MARK: - Computed Properties

    var currentWeekNumber: Int {
        currentWeekProgram?.weekNumber ?? 1
    }

    var todaySessionType: SessionType? {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        // Convertir weekday (1=Dimanche) en index (0=Lundi)
        let dayIndex = weekday == 1 ? 6 : weekday - 2

        // Vérifier si c'est un jour de semaine (lundi-vendredi)
        guard dayIndex >= 0 && dayIndex <= 4 else { return nil }

        return SessionType.forDay(dayIndex)
    }

    var todaySession: SessionTemplate? {
        guard let dayIndex = todaySessionType?.defaultDayIndex else { return nil }
        return currentWeekProgram?.session(forDay: dayIndex)
    }

    var hasActiveWorkout: Bool {
        activeWorkout != nil && activeWorkout?.isCompleted == false
    }

    var sessionsCompletedThisWeek: Int {
        weekSessions.filter(\.isCompleted).count
    }

    var totalSessionsThisWeek: Int {
        currentWeekProgram?.sessions.count ?? 5
    }

    // MARK: - Init

    init(dataService: DataService) {
        self.dataService = dataService
    }

    // MARK: - Data Loading

    func loadData() async {
        isLoading = true
        error = nil

        do {
            // Charger le programme de la semaine courante
            currentWeekProgram = try await dataService.workoutRepository.getCurrentWeekProgram()

            // Si pas de programme, créer un nouveau basé sur le précédent
            if currentWeekProgram == nil {
                await createNewWeekProgram()
            }

            // Charger les séances de la semaine
            if let program = currentWeekProgram {
                weekSessions = try await dataService.workoutRepository.getWorkoutSessions(forWeek: program.weekNumber)
            }

            // Vérifier s'il y a une séance active non terminée
            activeWorkout = weekSessions.first { !$0.isCompleted }

        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    private func createNewWeekProgram() async {
        // Récupérer le dernier programme
        do {
            let allPrograms = try await dataService.workoutRepository.getAllWeekPrograms()

            if let lastProgram = allPrograms.first {
                // Calculer le lundi de cette semaine
                let calendar = Calendar.current
                let today = Date()
                let weekday = calendar.component(.weekday, from: today)
                let daysFromMonday = weekday == 1 ? 6 : weekday - 2
                let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today)!

                // Dupliquer le programme
                let newProgram = lastProgram.duplicate(
                    forWeek: lastProgram.weekNumber + 1,
                    startDate: calendar.startOfDay(for: monday)
                )

                try await dataService.workoutRepository.saveWeekProgram(newProgram)
                currentWeekProgram = newProgram
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Session Management

    func startSession(from template: SessionTemplate) async -> WorkoutSession? {
        guard let program = currentWeekProgram else { return nil }

        // Créer une nouvelle séance
        let session = WorkoutSession(
            sessionType: template.sessionType,
            weekNumber: program.weekNumber
        )

        // Créer les exercices de la séance
        for plannedExercise in template.sortedExercises {
            let sessionExercise = SessionExercise(
                plannedExercise: plannedExercise,
                orderIndex: plannedExercise.orderIndex
            )

            // Créer les séries d'échauffement (si warmupSets > 0)
            if plannedExercise.warmupSets > 0 {
                for i in 1...plannedExercise.warmupSets {
                    let warmupSet = ExerciseSet(
                        setNumber: i,
                        isWarmup: true
                    )
                    sessionExercise.sets.append(warmupSet)
                }
            }

            // Créer 3 séries de travail
            for i in 1...3 {
                let workSet = ExerciseSet(
                    setNumber: plannedExercise.warmupSets + i
                )
                sessionExercise.sets.append(workSet)
            }

            session.exercises.append(sessionExercise)
        }

        do {
            try await dataService.workoutRepository.saveWorkoutSession(session)
            activeWorkout = session
            weekSessions.append(session)
            return session
        } catch {
            self.error = error.localizedDescription
            return nil
        }
    }

    func completeSession(_ session: WorkoutSession) async {
        session.complete()

        do {
            try await dataService.workoutRepository.saveWorkoutSession(session)
            activeWorkout = nil

            // Mettre à jour la liste
            if let index = weekSessions.firstIndex(where: { $0.id == session.id }) {
                weekSessions[index] = session
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func cancelSession(_ session: WorkoutSession) async {
        do {
            try await dataService.workoutRepository.deleteWorkoutSession(session)
            activeWorkout = nil
            weekSessions.removeAll { $0.id == session.id }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Previous Session Data

    func getPreviousSession(forType sessionType: SessionType) async -> WorkoutSession? {
        do {
            return try await dataService.workoutRepository.getPreviousSession(
                forType: sessionType,
                before: Date()
            )
        } catch {
            return nil
        }
    }

    func getSessionComparison(for session: WorkoutSession) async -> SessionComparison {
        let previous = await getPreviousSession(forType: session.sessionType)
        return SessionComparison(currentSession: session, previousSession: previous)
    }

    func getSessionAnalysis(for session: WorkoutSession) async -> SessionAnalysis {
        let previous = await getPreviousSession(forType: session.sessionType)
        return progressionService.analyzeSession(current: session, previous: previous)
    }

    // MARK: - Progression Suggestions

    func getSuggestion(
        for exercise: PlannedExercise,
        previousSession: WorkoutSession?
    ) -> ProgressionSuggestion {
        // Trouver les séries précédentes pour cet exercice
        var previousSets: [ExerciseSet] = []

        if let previous = previousSession,
           let previousExercise = previous.exercises.first(where: {
               $0.plannedExercise?.exercise?.id == exercise.exercise?.id
           }) {
            previousSets = previousExercise.sortedSets
        }

        return progressionService.suggestProgression(for: exercise, previousSets: previousSets)
    }

    // MARK: - Session Status

    func isSessionCompleted(_ sessionType: SessionType) -> Bool {
        weekSessions.contains { $0.sessionType == sessionType && $0.isCompleted }
    }

    func getCompletedSession(forType sessionType: SessionType) -> WorkoutSession? {
        weekSessions.first { $0.sessionType == sessionType && $0.isCompleted }
    }
}
