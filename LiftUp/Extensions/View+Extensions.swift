import SwiftUI

// MARK: - iOS 26 Liquid Glass Effects

extension View {
    /// Carte iOS 26 style - Fond blanc flottant avec ombre douce
    func iOS26Card(cornerRadius: CGFloat = 16) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.cardSurface)
                    .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
                    .shadow(color: .black.opacity(0.02), radius: 1, x: 0, y: 1)
            }
    }

    /// Carte avec accent coloré iOS 26
    func iOS26AccentCard(color: Color, cornerRadius: CGFloat = 16) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.15), color.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color.cardSurface.opacity(0.5))
                    }
                    .shadow(color: color.opacity(0.15), radius: 12, x: 0, y: 4)
            }
    }

    /// Effet Liquid Glass iOS 26 (pour overlays flottants)
    func liquidGlass(cornerRadius: CGFloat = 24) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            }
    }

    /// Mini player / floating bar style iOS 26
    func floatingBar() -> some View {
        self
            .background {
                Capsule()
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 8)
            }
    }

    /// Liste groupée iOS 26
    func iOS26ListSection(cornerRadius: CGFloat = 12) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.cardSurface)
            }
    }

    /// Icône colorée style iOS 26 (comme les icônes de la bibliothèque Apple Music)
    func iOS26Icon(color: Color, size: CGFloat = 28) -> some View {
        self
            .font(.system(size: size * 0.6, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                    .fill(Color.iconGradient(color))
            )
    }

    /// Row style iOS 26 avec chevron
    func iOS26Row() -> some View {
        self
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
    }
}

// MARK: - Conditional Modifiers

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    @ViewBuilder
    func ifLet<T, Content: View>(_ optional: T?, transform: (Self, T) -> Content) -> some View {
        if let value = optional {
            transform(self, value)
        } else {
            self
        }
    }
}

// MARK: - iOS 26 Animation Helpers

extension View {
    func iOS26Spring() -> some View {
        self.animation(.spring(response: 0.35, dampingFraction: 0.7), value: UUID())
    }

    func smoothTransition() -> some View {
        self.animation(.easeInOut(duration: 0.25), value: UUID())
    }
}

// MARK: - Haptic Feedback

extension View {
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred()
        }
    }

    func lightHaptic() -> some View {
        self.sensoryFeedback(.impact(flexibility: .soft), trigger: UUID())
    }
}

// MARK: - Shimmer Loading Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.4),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + phase * geometry.size.width * 2)
                }
            }
            .mask(content)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - iOS 26 Typography

extension View {
    /// Large title style iOS 26 (comme "Bibliothèque" dans Apple Music)
    func iOS26LargeTitle() -> some View {
        self
            .font(.system(size: 34, weight: .bold, design: .default))
    }

    /// Section title iOS 26
    func iOS26SectionTitle() -> some View {
        self
            .font(.system(size: 22, weight: .bold))
    }

    /// Caption style iOS 26
    func iOS26Caption() -> some View {
        self
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }
}

// MARK: - Legacy Support (pour compatibilité)

extension View {
    func glassCard() -> some View {
        self
            .padding()
            .iOS26Card()
    }

    func cardStyle(cornerRadius: CGFloat = 12) -> some View {
        self.iOS26Card(cornerRadius: cornerRadius)
    }

    func sectionTitleStyle() -> some View {
        self
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.5)
    }

    func largeTitleStyle() -> some View {
        self.iOS26LargeTitle()
    }
}
