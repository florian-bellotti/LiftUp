import Foundation
import SwiftData

/// Type de séance d'entraînement
enum SessionType: String, Codable, CaseIterable, Identifiable {
    case upper = "UPPER"
    case lower = "LOWER"
    case pull = "PULL"
    case legs = "LEGS"
    case push = "PUSH"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .upper: return "Upper Body"
        case .lower: return "Lower Body"
        case .pull: return "Pull"
        case .legs: return "Legs"
        case .push: return "Push"
        }
    }

    var icon: String {
        switch self {
        case .upper: return "figure.arms.open"
        case .lower: return "figure.walk"
        case .pull: return "arrow.down.to.line"
        case .legs: return "figure.run"
        case .push: return "arrow.up.to.line"
        }
    }

    var color: String {
        switch self {
        case .upper: return "sessionUpper"
        case .lower: return "sessionLower"
        case .pull: return "sessionPull"
        case .legs: return "sessionLegs"
        case .push: return "sessionPush"
        }
    }

    /// Ordre par défaut des séances dans la semaine (Lundi → Vendredi)
    var defaultDayIndex: Int {
        switch self {
        case .upper: return 0  // Lundi
        case .lower: return 1  // Mardi
        case .pull: return 2   // Mercredi
        case .legs: return 3   // Jeudi
        case .push: return 4   // Vendredi
        }
    }

    /// Retourne le type de séance pour un jour donné (0 = Lundi)
    static func forDay(_ dayIndex: Int) -> SessionType? {
        return Self.allCases.first { $0.defaultDayIndex == dayIndex }
    }
}

/// Catégorie de muscle ciblé par un exercice
enum MuscleGroup: String, Codable, CaseIterable {
    case chest = "Pectoraux"
    case back = "Dos"
    case shoulders = "Épaules"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case forearms = "Avant-bras"
    case quadriceps = "Quadriceps"
    case hamstrings = "Ischio-jambiers"
    case glutes = "Fessiers"
    case calves = "Mollets"
    case core = "Abdominaux"
    case traps = "Trapèzes"
    case lats = "Grand dorsal"
    case rearDelts = "Deltoïdes postérieurs"
}
