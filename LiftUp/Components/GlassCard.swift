import SwiftUI

// MARK: - iOS 26 Card Component

/// Carte iOS 26 style avec fond blanc flottant
struct iOS26CardView<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 16
    var padding: CGFloat = 16

    init(
        cornerRadius: CGFloat = 16,
        padding: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.cardSurface)
                    .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
                    .shadow(color: .black.opacity(0.02), radius: 1, x: 0, y: 1)
            }
    }
}

// MARK: - iOS 26 Accent Card

/// Carte avec accent coloré style iOS 26
struct iOS26AccentCardView<Content: View>: View {
    let color: Color
    let content: Content
    var cornerRadius: CGFloat = 16
    var padding: CGFloat = 16

    init(
        color: Color,
        cornerRadius: CGFloat = 16,
        padding: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.color = color
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.cardSurface)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [color.opacity(0.12), color.opacity(0.04)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .shadow(color: color.opacity(0.12), radius: 12, x: 0, y: 4)
                    .shadow(color: .black.opacity(0.04), radius: 1, x: 0, y: 1)
            }
    }
}

// MARK: - iOS 26 Icon Button

/// Icône style iOS 26 (comme dans la bibliothèque Apple Music)
struct iOS26IconView: View {
    let icon: String
    let color: Color
    var size: CGFloat = 28

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.55, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.95), color],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
    }
}

// MARK: - iOS 26 Row View

/// Row style iOS 26 pour les listes
struct iOS26RowView<Leading: View, Trailing: View>: View {
    let title: String
    let leading: Leading
    let trailing: Trailing
    let action: () -> Void

    init(
        title: String,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() },
        action: @escaping () -> Void
    ) {
        self.title = title
        self.leading = leading()
        self.trailing = trailing()
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                leading

                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)

                Spacer()

                trailing

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - iOS 26 Primary Button

/// Bouton principal iOS 26
struct iOS26Button: View {
    let title: String
    let icon: String?
    let color: Color
    let style: ButtonStyle
    let action: () -> Void

    enum ButtonStyle {
        case filled
        case tinted
        case plain
    }

    init(
        _ title: String,
        icon: String? = nil,
        color: Color = .appPrimary,
        style: ButtonStyle = .filled,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.color = color
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.body.weight(.semibold))
                }
                Text(title)
                    .font(.body.weight(.semibold))
            }
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: style == .plain ? nil : .infinity)
            .padding(.vertical, style == .plain ? 8 : 14)
            .padding(.horizontal, style == .plain ? 12 : 0)
            .background {
                if style != .plain {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(backgroundColor)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var foregroundColor: Color {
        switch style {
        case .filled: return .white
        case .tinted: return color
        case .plain: return color
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .filled: return color
        case .tinted: return color.opacity(0.12)
        case .plain: return .clear
        }
    }
}

// MARK: - iOS 26 Badge

/// Badge style iOS 26
struct iOS26Badge: View {
    let text: String
    let color: Color
    var size: BadgeSize = .regular

    enum BadgeSize {
        case small, regular

        var font: Font {
            switch self {
            case .small: return .caption2.weight(.semibold)
            case .regular: return .caption.weight(.semibold)
            }
        }

        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6)
            case .regular: return EdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10)
            }
        }
    }

    var body: some View {
        Text(text)
            .font(size.font)
            .foregroundStyle(color)
            .padding(size.padding)
            .background {
                Capsule()
                    .fill(color.opacity(0.12))
            }
    }
}

// MARK: - iOS 26 Floating Player Bar (Mini Player Style)

/// Barre flottante style mini player iOS 26
struct iOS26FloatingBar<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background {
                Capsule()
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 8)
            }
    }
}

// MARK: - Legacy Aliases (pour compatibilité)

typealias GlassCard = iOS26CardView
typealias ColoredGlassCard = iOS26AccentCardView
typealias GlassBadge = iOS26Badge

/// Bouton glass legacy
struct GlassButton: View {
    let title: String
    let icon: String?
    let color: Color
    let action: () -> Void

    init(
        _ title: String,
        icon: String? = nil,
        color: Color = .accentColor,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.color = color
        self.action = action
    }

    var body: some View {
        iOS26Button(title, icon: icon, color: color, style: .tinted, action: action)
    }
}

/// Bouton principal legacy
struct PrimaryButton: View {
    let title: String
    let icon: String?
    let color: Color
    let action: () -> Void

    init(
        _ title: String,
        icon: String? = nil,
        color: Color = .accentColor,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.color = color
        self.action = action
    }

    var body: some View {
        iOS26Button(title, icon: icon, color: color, style: .filled, action: action)
    }
}

// MARK: - Previews

#Preview("iOS 26 Cards") {
    ScrollView {
        VStack(spacing: 20) {
            iOS26CardView {
                VStack(alignment: .leading) {
                    Text("iOS 26 Card")
                        .font(.headline)
                    Text("Clean white floating card")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            iOS26AccentCardView(color: .blue) {
                VStack(alignment: .leading) {
                    Text("Accent Card")
                        .font(.headline)
                    Text("With blue tint")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 16) {
                iOS26IconView(icon: "music.note.list", color: .red)
                iOS26IconView(icon: "person.2.fill", color: .red)
                iOS26IconView(icon: "rectangle.stack.fill", color: .red)
            }

            HStack {
                iOS26Badge(text: "NEW", color: .green)
                iOS26Badge(text: "PR", color: .yellow, size: .small)
            }

            iOS26Button("Primary Action", icon: "play.fill", color: .appPrimary, action: {})
            iOS26Button("Tinted Button", icon: "star.fill", color: .blue, style: .tinted, action: {})

            iOS26FloatingBar {
                HStack {
                    Circle()
                        .fill(.gray.opacity(0.3))
                        .frame(width: 44, height: 44)

                    VStack(alignment: .leading) {
                        Text("Now Playing")
                            .font(.subheadline.weight(.medium))
                        Text("Artist Name")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "play.fill")
                        .font(.title2)

                    Image(systemName: "forward.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }
    .background(Color.appBackground)
}
