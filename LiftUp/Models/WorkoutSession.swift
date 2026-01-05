import Foundation
import SwiftData

/// Template de séance (définition du programme)
@Model
final class SessionTemplate {
    @Attribute(.unique) var id: UUID

    /// Type de séance
    var sessionType: SessionType

    /// Liste des exercices planifiés
    @Relationship(deleteRule: .cascade)
    var exercises: [PlannedExercise]

    /// Semaine du programme
    @Relationship(inverse: \WeekProgram.sessions)
    var weekProgram: WeekProgram?

    /// Ordre dans la semaine
    var dayIndex: Int

    init(
        id: UUID = UUID(),
        sessionType: SessionType,
        exercises: [PlannedExercise] = [],
        dayIndex: Int? = nil
    ) {
        self.id = id
        self.sessionType = sessionType
        self.exercises = exercises
        self.dayIndex = dayIndex ?? sessionType.defaultDayIndex
    }

    var sortedExercises: [PlannedExercise] {
        exercises.sorted { $0.orderIndex < $1.orderIndex }
    }
}

/// Exercice effectué pendant une séance (avec les séries réelles)
@Model
final class SessionExercise {
    @Attribute(.unique) var id: UUID

    /// Référence vers l'exercice planifié
    var plannedExercise: PlannedExercise?

    /// Séries effectuées
    @Relationship(deleteRule: .cascade)
    var sets: [ExerciseSet]

    /// Exercice complété ?
    var isCompleted: Bool

    /// Exercice skippé ?
    var isSkipped: Bool

    /// Ordre dans la séance
    var orderIndex: Int

    /// Notes pour cet exercice dans cette séance
    var notes: String?

    /// Séance parente
    @Relationship(inverse: \WorkoutSession.exercises)
    var workoutSession: WorkoutSession?

    init(
        id: UUID = UUID(),
        plannedExercise: PlannedExercise? = nil,
        sets: [ExerciseSet] = [],
        isCompleted: Bool = false,
        isSkipped: Bool = false,
        orderIndex: Int = 0,
        notes: String? = nil
    ) {
        self.id = id
        self.plannedExercise = plannedExercise
        self.sets = sets
        self.isCompleted = isCompleted
        self.isSkipped = isSkipped
        self.orderIndex = orderIndex
        self.notes = notes
    }

    var sortedSets: [ExerciseSet] {
        sets.sorted { $0.setNumber < $1.setNumber }
    }

    var completedSets: [ExerciseSet] {
        sets.filter { $0.isCompleted && !$0.isWarmup }
    }

    var totalVolume: Double {
        completedSets.reduce(0) { $0 + $1.volume }
    }

    var bestSet: ExerciseSet? {
        completedSets.max { $0.volume < $1.volume }
    }

    func markCompleted() {
        isCompleted = true
        isSkipped = false
    }

    func markSkipped() {
        isSkipped = true
        isCompleted = false
        // Marquer toutes les séries non complétées comme skippées
        for exerciseSet in sets where !exerciseSet.isCompleted {
            exerciseSet.markSkipped()
        }
    }
}

/// Séance d'entraînement effectuée
@Model
final class WorkoutSession {
    @Attribute(.unique) var id: UUID

    /// Type de séance (stocké comme String pour compatibilité SwiftData)
    var sessionTypeRaw: String

    /// Type de séance (propriété calculée)
    var sessionType: SessionType {
        get { SessionType(rawValue: sessionTypeRaw) ?? .upper }
        set { sessionTypeRaw = newValue.rawValue }
    }

    /// Numéro de la semaine
    var weekNumber: Int

    /// Date de début de la séance
    var startedAt: Date

    /// Date de fin de la séance
    var completedAt: Date?

    /// Exercices effectués
    @Relationship(deleteRule: .cascade)
    var exercises: [SessionExercise]

    /// Séance terminée ?
    var isCompleted: Bool

    /// Notes générales sur la séance
    var notes: String?

    /// Durée totale en secondes (calculée à la fin)
    var durationSeconds: Int?

    init(
        id: UUID = UUID(),
        sessionType: SessionType,
        weekNumber: Int,
        startedAt: Date = Date(),
        exercises: [SessionExercise] = [],
        isCompleted: Bool = false,
        notes: String? = nil
    ) {
        self.id = id
        self.sessionTypeRaw = sessionType.rawValue
        self.weekNumber = weekNumber
        self.startedAt = startedAt
        self.exercises = exercises
        self.isCompleted = isCompleted
        self.notes = notes
    }

    var sortedExercises: [SessionExercise] {
        exercises.sorted { $0.orderIndex < $1.orderIndex }
    }

    var completedExercises: [SessionExercise] {
        exercises.filter { $0.isCompleted }
    }

    var skippedExercises: [SessionExercise] {
        exercises.filter { $0.isSkipped }
    }

    var totalVolume: Double {
        exercises.reduce(0) { $0 + $1.totalVolume }
    }

    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.completedSets.count }
    }

    var progress: Double {
        guard !exercises.isEmpty else { return 0 }
        let completed = exercises.filter { $0.isCompleted || $0.isSkipped }.count
        return Double(completed) / Double(exercises.count)
    }

    var durationDisplay: String {
        guard let duration = durationSeconds else {
            let elapsed = Int(Date().timeIntervalSince(startedAt))
            return formatDuration(elapsed)
        }
        return formatDuration(duration)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)min"
        }
        return "\(minutes) min"
    }

    func complete() {
        isCompleted = true
        completedAt = Date()
        durationSeconds = Int(completedAt!.timeIntervalSince(startedAt))
    }
}

/// Résumé de comparaison entre deux séances
struct SessionComparison {
    let currentSession: WorkoutSession
    let previousSession: WorkoutSession?

    var volumeChange: Double {
        guard let previous = previousSession else { return 0 }
        return currentSession.totalVolume - previous.totalVolume
    }

    var volumeChangePercent: Double {
        guard let previous = previousSession, previous.totalVolume > 0 else { return 0 }
        return (volumeChange / previous.totalVolume) * 100
    }

    var improvements: [ExerciseImprovement] {
        guard let previous = previousSession else { return [] }

        var results: [ExerciseImprovement] = []

        for currentExercise in currentSession.completedExercises {
            guard let plannedExercise = currentExercise.plannedExercise,
                  let exercise = plannedExercise.exercise else { continue }

            // Trouver l'exercice correspondant dans la séance précédente
            let previousExercise = previous.exercises.first {
                $0.plannedExercise?.exercise?.id == exercise.id
            }

            if let prevEx = previousExercise {
                let currentBest = currentExercise.bestSet
                let previousBest = prevEx.bestSet

                if let current = currentBest, let prev = previousBest {
                    let volumeChange = current.volume - prev.volume
                    let weightChange = current.weight - prev.weight
                    let repsChange = current.reps - prev.reps

                    if volumeChange > 0 || weightChange > 0 || repsChange > 0 {
                        results.append(ExerciseImprovement(
                            exerciseName: exercise.name,
                            previousBest: prev.displayFormat,
                            currentBest: current.displayFormat,
                            volumeChange: volumeChange,
                            weightChange: weightChange,
                            repsChange: repsChange,
                            isPR: current.weight > prev.weight
                        ))
                    }
                }
            }
        }

        return results.sorted { $0.volumeChange > $1.volumeChange }
    }
}

struct ExerciseImprovement: Identifiable {
    let id = UUID()
    let exerciseName: String
    let previousBest: String
    let currentBest: String
    let volumeChange: Double
    let weightChange: Double
    let repsChange: Int
    let isPR: Bool
}
