import Foundation
import SwiftData

/// Définition d'un exercice dans le catalogue
@Model
final class Exercise {
    /// Identifiant unique
    @Attribute(.unique) var id: UUID

    /// Nom de l'exercice
    var name: String

    /// Nom de l'image associée (dans le catalogue d'assets)
    var imageName: String

    /// Groupes musculaires ciblés
    var muscleGroups: [MuscleGroup]

    /// Description/instructions de l'exercice
    var exerciseDescription: String

    /// Équipement nécessaire
    var equipment: String?

    /// Date de création
    var createdAt: Date

    /// Indique si c'est un exercice personnalisé (vs pré-défini)
    var isCustom: Bool

    init(
        id: UUID = UUID(),
        name: String,
        imageName: String = "exercise_placeholder",
        muscleGroups: [MuscleGroup] = [],
        description: String = "",
        equipment: String? = nil,
        isCustom: Bool = false
    ) {
        self.id = id
        self.name = name
        self.imageName = imageName
        self.muscleGroups = muscleGroups
        self.exerciseDescription = description
        self.equipment = equipment
        self.createdAt = Date()
        self.isCustom = isCustom
    }
}

/// Exercice planifié dans une séance (avec paramètres spécifiques)
@Model
final class PlannedExercise {
    @Attribute(.unique) var id: UUID

    /// Référence vers l'exercice du catalogue
    var exercise: Exercise?

    /// Nombre de séries d'échauffement
    var warmupSets: Int

    /// Plage de répétitions cible (min)
    var targetRepsMin: Int

    /// Plage de répétitions cible (max)
    var targetRepsMax: Int

    /// Temps de repos en secondes
    var restTimeSeconds: Int

    /// Ordre dans la séance
    var orderIndex: Int

    /// Notes spécifiques pour cet exercice
    var notes: String?

    /// Séance à laquelle appartient cet exercice planifié
    @Relationship(inverse: \SessionTemplate.exercises)
    var sessionTemplate: SessionTemplate?

    init(
        id: UUID = UUID(),
        exercise: Exercise? = nil,
        warmupSets: Int = 1,
        targetRepsMin: Int = 8,
        targetRepsMax: Int = 12,
        restTimeSeconds: Int = 120,
        orderIndex: Int = 0,
        notes: String? = nil
    ) {
        self.id = id
        self.exercise = exercise
        self.warmupSets = warmupSets
        self.targetRepsMin = targetRepsMin
        self.targetRepsMax = targetRepsMax
        self.restTimeSeconds = restTimeSeconds
        self.orderIndex = orderIndex
        self.notes = notes
    }

    var targetRepsDisplay: String {
        if targetRepsMin == targetRepsMax {
            return "\(targetRepsMin)"
        }
        return "\(targetRepsMin)-\(targetRepsMax)"
    }

    var restTimeDisplay: String {
        let minutes = restTimeSeconds / 60
        let seconds = restTimeSeconds % 60
        if seconds == 0 {
            return "\(minutes) min"
        }
        return "\(minutes):\(String(format: "%02d", seconds)) min"
    }
}
