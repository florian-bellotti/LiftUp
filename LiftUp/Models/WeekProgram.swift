import Foundation
import SwiftData

/// Programme d'une semaine complète
@Model
final class WeekProgram {
    @Attribute(.unique) var id: UUID

    /// Numéro de la semaine (1, 2, 3...)
    var weekNumber: Int

    /// Date de début de la semaine (lundi)
    var startDate: Date

    /// Templates des séances de la semaine
    @Relationship(deleteRule: .cascade)
    var sessions: [SessionTemplate]

    /// Notes pour cette semaine
    var notes: String?

    /// Programme actif ?
    var isActive: Bool

    init(
        id: UUID = UUID(),
        weekNumber: Int,
        startDate: Date = Date(),
        sessions: [SessionTemplate] = [],
        notes: String? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.weekNumber = weekNumber
        self.startDate = startDate
        self.sessions = sessions
        self.notes = notes
        self.isActive = isActive
    }

    /// Retourne les séances triées par jour
    var sortedSessions: [SessionTemplate] {
        sessions.sorted { $0.dayIndex < $1.dayIndex }
    }

    /// Retourne la séance pour un jour donné
    func session(forDay dayIndex: Int) -> SessionTemplate? {
        sessions.first { $0.dayIndex == dayIndex }
    }

    /// Retourne la séance du jour actuel
    var todaySession: SessionTemplate? {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        // Convertir weekday (1=Dimanche) en index (0=Lundi)
        let dayIndex = weekday == 1 ? 6 : weekday - 2
        return session(forDay: dayIndex)
    }

    /// Duplique le programme pour une nouvelle semaine
    func duplicate(forWeek newWeekNumber: Int, startDate: Date) -> WeekProgram {
        let newProgram = WeekProgram(
            weekNumber: newWeekNumber,
            startDate: startDate,
            notes: notes,
            isActive: true
        )

        for session in sessions {
            let newSession = SessionTemplate(
                sessionType: session.sessionType,
                dayIndex: session.dayIndex
            )

            for exercise in session.exercises {
                let newExercise = PlannedExercise(
                    exercise: exercise.exercise,
                    warmupSets: exercise.warmupSets,
                    targetRepsMin: exercise.targetRepsMin,
                    targetRepsMax: exercise.targetRepsMax,
                    restTimeSeconds: exercise.restTimeSeconds,
                    orderIndex: exercise.orderIndex,
                    notes: exercise.notes
                )
                newSession.exercises.append(newExercise)
            }

            newProgram.sessions.append(newSession)
        }

        return newProgram
    }
}

/// Extension pour les calculs de date
extension WeekProgram {
    /// Retourne la date du jour spécifié (0 = Lundi)
    func date(forDay dayIndex: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: dayIndex, to: startDate) ?? startDate
    }

    /// Retourne le nom du jour
    static func dayName(forIndex index: Int) -> String {
        let days = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"]
        guard index >= 0 && index < days.count else { return "" }
        return days[index]
    }

    /// Retourne le nom court du jour
    static func shortDayName(forIndex index: Int) -> String {
        let days = ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"]
        guard index >= 0 && index < days.count else { return "" }
        return days[index]
    }
}

/// Statistiques du programme
struct ProgramStats {
    let weekProgram: WeekProgram
    let completedSessions: [WorkoutSession]

    var totalExercises: Int {
        weekProgram.sessions.reduce(0) { $0 + $1.exercises.count }
    }

    var completedSessionsCount: Int {
        completedSessions.count
    }

    var totalSessionsCount: Int {
        weekProgram.sessions.count
    }

    var completionRate: Double {
        guard totalSessionsCount > 0 else { return 0 }
        return Double(completedSessionsCount) / Double(totalSessionsCount)
    }

    var totalVolumeThisWeek: Double {
        completedSessions.reduce(0) { $0 + $1.totalVolume }
    }

    var totalSetsThisWeek: Int {
        completedSessions.reduce(0) { $0 + $1.totalSets }
    }
}
