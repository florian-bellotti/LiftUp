import Foundation
import SwiftData

/// Une série effectuée pour un exercice
@Model
final class ExerciseSet {
    @Attribute(.unique) var id: UUID

    /// Numéro de la série (1, 2, 3...)
    var setNumber: Int

    /// Nombre de répétitions effectuées
    var reps: Int

    /// Poids utilisé en kg
    var weight: Double

    /// Est-ce une série d'échauffement ?
    var isWarmup: Bool

    /// Série complétée ?
    var isCompleted: Bool

    /// Série skippée ?
    var isSkipped: Bool

    /// Notes pour cette série
    var notes: String?

    /// Timestamp de complétion
    var completedAt: Date?

    /// Lien vers l'exercice de la séance
    @Relationship(inverse: \SessionExercise.sets)
    var sessionExercise: SessionExercise?

    init(
        id: UUID = UUID(),
        setNumber: Int,
        reps: Int = 0,
        weight: Double = 0,
        isWarmup: Bool = false,
        isCompleted: Bool = false,
        isSkipped: Bool = false,
        notes: String? = nil
    ) {
        self.id = id
        self.setNumber = setNumber
        self.reps = reps
        self.weight = weight
        self.isWarmup = isWarmup
        self.isCompleted = isCompleted
        self.isSkipped = isSkipped
        self.notes = notes
    }

    /// Format d'affichage : "10(35)" = 10 reps à 35kg
    var displayFormat: String {
        if weight == 0 {
            return "\(reps)"
        }
        // Affiche le poids sans décimale si c'est un entier
        let weightStr = weight.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", weight)
            : String(format: "%.1f", weight)
        return "\(reps)(\(weightStr))"
    }

    /// Volume de la série (reps * poids)
    var volume: Double {
        return Double(reps) * weight
    }

    func markCompleted() {
        isCompleted = true
        isSkipped = false
        completedAt = Date()
    }

    func markSkipped() {
        isSkipped = true
        isCompleted = false
        completedAt = Date()
    }
}

/// Comparaison avec une série précédente
struct SetComparison {
    let previousSet: ExerciseSet?
    let currentSet: ExerciseSet

    var repsChange: Int {
        guard let previous = previousSet else { return 0 }
        return currentSet.reps - previous.reps
    }

    var weightChange: Double {
        guard let previous = previousSet else { return 0 }
        return currentSet.weight - previous.weight
    }

    var volumeChange: Double {
        guard let previous = previousSet else { return 0 }
        return currentSet.volume - previous.volume
    }

    var isImprovement: Bool {
        return volumeChange > 0 || (volumeChange == 0 && repsChange > 0)
    }

    var isPR: Bool {
        guard let previous = previousSet else { return true }
        return currentSet.weight > previous.weight ||
               (currentSet.weight == previous.weight && currentSet.reps > previous.reps)
    }
}
