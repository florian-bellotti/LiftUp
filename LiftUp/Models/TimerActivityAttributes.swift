import ActivityKit
import Foundation

/// Attributs pour la Live Activity du timer de repos
struct TimerActivityAttributes: ActivityAttributes {
    /// Données statiques (ne changent pas pendant la durée de la Live Activity)
    public struct ContentState: Codable, Hashable {
        /// Secondes restantes
        var remainingSeconds: Int
        /// Secondes totales du timer
        var totalSeconds: Int
        /// Indique si le timer est en pause
        var isPaused: Bool

        var progress: Double {
            guard totalSeconds > 0 else { return 0 }
            return 1.0 - (Double(remainingSeconds) / Double(totalSeconds))
        }

        var displayTime: String {
            let minutes = remainingSeconds / 60
            let seconds = remainingSeconds % 60
            return String(format: "%d:%02d", minutes, seconds)
        }

        var isFinished: Bool {
            remainingSeconds <= 0
        }

        var isAlmostFinished: Bool {
            remainingSeconds <= 10 && remainingSeconds > 0
        }
    }

    /// Nom de l'exercice en cours
    var exerciseName: String
    /// Numéro de la série
    var setNumber: Int
    /// Nombre total de séries
    var totalSets: Int
}
