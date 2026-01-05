import Foundation

/// Service de calcul des suggestions de progression
final class ProgressionService {

    /// Suggère une progression basée sur les performances précédentes
    func suggestProgression(
        for exercise: PlannedExercise,
        previousSets: [ExerciseSet]
    ) -> ProgressionSuggestion {
        guard !previousSets.isEmpty else {
            return ProgressionSuggestion(
                suggestedWeight: 0,
                suggestedReps: exercise.targetRepsMin,
                reason: .firstTime
            )
        }

        // Analyser les séries précédentes (hors échauffement)
        let workingSets = previousSets.filter { !$0.isWarmup && $0.isCompleted }

        guard !workingSets.isEmpty else {
            return ProgressionSuggestion(
                suggestedWeight: 0,
                suggestedReps: exercise.targetRepsMin,
                reason: .firstTime
            )
        }

        let avgReps = Double(workingSets.reduce(0) { $0 + $1.reps }) / Double(workingSets.count)
        let lastWeight = workingSets.last?.weight ?? 0
        let maxReps = workingSets.map(\.reps).max() ?? 0

        // Logique de progression
        // Si toutes les séries sont au max des reps cibles → augmenter le poids
        if avgReps >= Double(exercise.targetRepsMax) {
            let weightIncrease = calculateWeightIncrease(currentWeight: lastWeight)
            return ProgressionSuggestion(
                suggestedWeight: lastWeight + weightIncrease,
                suggestedReps: exercise.targetRepsMin,
                reason: .reachedMaxReps
            )
        }

        // Si on est dans la plage cible → maintenir
        if avgReps >= Double(exercise.targetRepsMin) {
            return ProgressionSuggestion(
                suggestedWeight: lastWeight,
                suggestedReps: min(maxReps + 1, exercise.targetRepsMax),
                reason: .progressInReps
            )
        }

        // Si en dessous de la plage → même poids, objectif min
        return ProgressionSuggestion(
            suggestedWeight: lastWeight,
            suggestedReps: exercise.targetRepsMin,
            reason: .maintainWeight
        )
    }

    /// Calcule l'incrément de poids approprié
    private func calculateWeightIncrease(currentWeight: Double) -> Double {
        // Pour les petits poids (haltères), +1-2kg
        // Pour les gros poids (barre), +2.5-5kg
        if currentWeight < 20 {
            return 1.0
        } else if currentWeight < 40 {
            return 2.0
        } else if currentWeight < 80 {
            return 2.5
        } else {
            return 5.0
        }
    }

    /// Analyse la performance d'une séance par rapport à la précédente
    func analyzeSession(
        current: WorkoutSession,
        previous: WorkoutSession?
    ) -> SessionAnalysis {
        var improvements: [String] = []
        var regressions: [String] = []
        var prs: [String] = []

        guard let previous = previous else {
            return SessionAnalysis(
                improvements: [],
                regressions: [],
                prs: [],
                volumeChange: 0,
                volumeChangePercent: 0,
                summary: "Première séance de ce type ! Bonne base établie."
            )
        }

        let volumeChange = current.totalVolume - previous.totalVolume
        let volumeChangePercent = previous.totalVolume > 0
            ? (volumeChange / previous.totalVolume) * 100
            : 0

        // Comparer chaque exercice
        for currentEx in current.completedExercises {
            guard let plannedEx = currentEx.plannedExercise,
                  let exercise = plannedEx.exercise else { continue }

            // Trouver l'exercice correspondant dans la séance précédente
            let previousEx = previous.exercises.first {
                $0.plannedExercise?.exercise?.id == exercise.id && $0.isCompleted
            }

            guard let prevEx = previousEx else { continue }

            // Comparer les meilleures séries
            if let currentBest = currentEx.bestSet,
               let previousBest = prevEx.bestSet {

                if currentBest.weight > previousBest.weight {
                    prs.append("\(exercise.name): \(currentBest.weight)kg (+\(currentBest.weight - previousBest.weight)kg)")
                    improvements.append("\(exercise.name): PR de poids !")
                } else if currentBest.weight == previousBest.weight && currentBest.reps > previousBest.reps {
                    improvements.append("\(exercise.name): +\(currentBest.reps - previousBest.reps) reps à \(currentBest.weight)kg")
                } else if currentBest.volume > previousBest.volume {
                    improvements.append("\(exercise.name): meilleur volume")
                } else if currentBest.volume < previousBest.volume * 0.9 {
                    regressions.append("\(exercise.name): volume en baisse")
                }
            }
        }

        // Générer le résumé
        let summary = generateSummary(
            improvements: improvements.count,
            regressions: regressions.count,
            prs: prs.count,
            volumeChangePercent: volumeChangePercent
        )

        return SessionAnalysis(
            improvements: improvements,
            regressions: regressions,
            prs: prs,
            volumeChange: volumeChange,
            volumeChangePercent: volumeChangePercent,
            summary: summary
        )
    }

    private func generateSummary(
        improvements: Int,
        regressions: Int,
        prs: Int,
        volumeChangePercent: Double
    ) -> String {
        if prs > 0 {
            return "Excellente séance ! \(prs) nouveau\(prs > 1 ? "x" : "") record\(prs > 1 ? "s" : "") personnel\(prs > 1 ? "s" : "") !"
        }

        if volumeChangePercent > 5 {
            return "Très bonne progression ! Volume en hausse de \(String(format: "%.1f", volumeChangePercent))%"
        }

        if improvements > regressions {
            return "Bonne séance avec \(improvements) amélioration\(improvements > 1 ? "s" : "")."
        }

        if regressions > improvements {
            return "Séance difficile. Pense à bien récupérer."
        }

        return "Séance stable, bon maintien des performances."
    }
}

/// Suggestion de progression pour un exercice
struct ProgressionSuggestion {
    let suggestedWeight: Double
    let suggestedReps: Int
    let reason: ProgressionReason

    var displayText: String {
        if suggestedWeight == 0 {
            return "\(suggestedReps) reps"
        }
        let weightStr = suggestedWeight.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", suggestedWeight)
            : String(format: "%.1f", suggestedWeight)
        return "\(suggestedReps) reps @ \(weightStr)kg"
    }
}

enum ProgressionReason {
    case firstTime
    case reachedMaxReps
    case progressInReps
    case maintainWeight

    var explanation: String {
        switch self {
        case .firstTime:
            return "Première fois - commence léger pour trouver ton poids de travail"
        case .reachedMaxReps:
            return "Tu as atteint le max de reps, augmente le poids !"
        case .progressInReps:
            return "Continue à progresser en reps avant d'augmenter"
        case .maintainWeight:
            return "Maintiens ce poids jusqu'à atteindre les reps cibles"
        }
    }
}

/// Analyse d'une séance
struct SessionAnalysis {
    let improvements: [String]
    let regressions: [String]
    let prs: [String]
    let volumeChange: Double
    let volumeChangePercent: Double
    let summary: String

    var hasPRs: Bool { !prs.isEmpty }
    var isPositive: Bool { improvements.count >= regressions.count }
}
