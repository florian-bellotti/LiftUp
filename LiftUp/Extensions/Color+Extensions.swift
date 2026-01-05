import SwiftUI

extension Color {
    // MARK: - iOS 26 Liquid Glass Colors

    /// Couleur primaire de l'app - Bleu élégant
    static let appPrimary = Color(hex: "0A84FF")

    /// Backgrounds iOS 26 style
    static let appBackground = Color(uiColor: .systemGroupedBackground)
    static let appSecondaryBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let appTertiaryBackground = Color(uiColor: .tertiarySystemGroupedBackground)

    /// Surface pour les cartes flottantes (blanc pur)
    static let cardSurface = Color(uiColor: .systemBackground)

    // MARK: - Session Colors (Palette élégante et cohérente)

    /// Palette monochrome avec des teintes de bleu/gris élégantes
    static let sessionUpper = Color(hex: "0A84FF") // Bleu Apple
    static let sessionLower = Color(hex: "5E5CE6") // Indigo doux
    static let sessionPull = Color(hex: "64D2FF")  // Cyan clair
    static let sessionLegs = Color(hex: "FF9F0A")  // Ambre chaud
    static let sessionPush = Color(hex: "FF453A")  // Corail

    static func forSessionType(_ type: SessionType) -> Color {
        switch type {
        case .upper: return .sessionUpper
        case .lower: return .sessionLower
        case .pull: return .sessionPull
        case .legs: return .sessionLegs
        case .push: return .sessionPush
        }
    }

    // MARK: - Status Colors

    static let success = Color(hex: "34C759")
    static let warning = Color(hex: "FF9500")
    static let error = Color(hex: "FF3B30")
    static let info = Color(hex: "007AFF")

    // MARK: - Progress Colors

    static let progressComplete = Color(hex: "34C759")
    static let progressPartial = Color(hex: "FF9500")
    static let progressNone = Color(hex: "8E8E93").opacity(0.3)

    // MARK: - iOS 26 Liquid Glass Colors

    /// Glass effect sur fond clair
    static let liquidGlassLight = Color.white.opacity(0.7)
    /// Glass effect sur fond sombre
    static let liquidGlassDark = Color.black.opacity(0.3)
    /// Bordure subtile pour glass
    static let liquidGlassBorder = Color.white.opacity(0.5)
    /// Ombre douce iOS 26
    static let liquidGlassShadow = Color.black.opacity(0.08)

    // MARK: - Text Colors

    static let textPrimary = Color(uiColor: .label)
    static let textSecondary = Color(uiColor: .secondaryLabel)
    static let textTertiary = Color(uiColor: .tertiaryLabel)

    // MARK: - Gradient Helpers

    static func sessionGradient(_ type: SessionType) -> LinearGradient {
        let baseColor = forSessionType(type)
        return LinearGradient(
            colors: [baseColor, baseColor.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var appGradient: LinearGradient {
        LinearGradient(
            colors: [.appPrimary, .appPrimary.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Gradient pour les icônes style iOS 26
    static func iconGradient(_ color: Color) -> LinearGradient {
        LinearGradient(
            colors: [color.opacity(0.9), color],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Hex Color Init

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
