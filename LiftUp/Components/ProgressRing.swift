import SwiftUI

// MARK: - iOS 26 Progress Ring

/// Anneau de progression circulaire style iOS 26
struct ProgressRing: View {
    let progress: Double
    let color: Color
    var lineWidth: CGFloat = 6
    var size: CGFloat = 60

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)

            // Progress ring
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Progress Ring With Content

/// Anneau de progression avec contenu au centre
struct ProgressRingWithContent<Content: View>: View {
    let progress: Double
    let color: Color
    var lineWidth: CGFloat = 6
    var size: CGFloat = 100
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            ProgressRing(
                progress: progress,
                color: color,
                lineWidth: lineWidth,
                size: size
            )

            content()
        }
    }
}

// MARK: - iOS 26 Circular Timer

/// Timer circulaire avec animation style iOS 26
struct CircularTimer: View {
    let remainingSeconds: Int
    let totalSeconds: Int
    let color: Color
    var size: CGFloat = 120
    var lineWidth: CGFloat = 8

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(remainingSeconds) / Double(totalSeconds)
    }

    var timeDisplay: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        ZStack {
            // Background circle with subtle fill
            Circle()
                .fill(Color.cardSurface)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)

            // Progress ring background
            Circle()
                .stroke(color.opacity(0.12), lineWidth: lineWidth)
                .padding(lineWidth / 2)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .padding(lineWidth / 2)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: remainingSeconds)

            // Time display
            VStack(spacing: 4) {
                Text(timeDisplay)
                    .font(.system(size: size / 4, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)

                if remainingSeconds <= 10 && remainingSeconds > 0 {
                    Text("PRÊT ?")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(color)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - iOS 26 Progress Bar

/// Barre de progression horizontale style iOS 26
struct ProgressBar: View {
    let progress: Double
    let color: Color
    var height: CGFloat = 6
    var cornerRadius: CGFloat = 3

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(color.opacity(0.12))

                // Progress
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(color)
                    .frame(width: geometry.size.width * min(progress, 1.0))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progress)
            }
        }
        .frame(height: height)
    }
}

// MARK: - iOS 26 Set Indicator

/// Indicateur de séries (dots) style iOS 26
struct SetIndicator: View {
    let totalSets: Int
    let completedSets: Int
    let currentSet: Int?
    let color: Color
    var dotSize: CGFloat = 8
    var spacing: CGFloat = 6

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<totalSets, id: \.self) { index in
                Circle()
                    .fill(fillColor(for: index))
                    .frame(width: dotSize, height: dotSize)
                    .overlay {
                        if index == currentSet {
                            Circle()
                                .stroke(color, lineWidth: 2)
                                .frame(width: dotSize + 4, height: dotSize + 4)
                        }
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: completedSets)
            }
        }
    }

    private func fillColor(for index: Int) -> Color {
        if index < completedSets {
            return color
        } else if index == currentSet {
            return color.opacity(0.4)
        }
        return color.opacity(0.15)
    }
}

// MARK: - iOS 26 Mini Progress Indicator

/// Petit indicateur de progression inline
struct MiniProgressIndicator: View {
    let completed: Int
    let total: Int
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Text("\(completed)/\(total)")
                .font(.caption.weight(.medium).monospacedDigit())
                .foregroundStyle(.secondary)

            Circle()
                .fill(completed == total ? Color.success : color.opacity(0.3))
                .frame(width: 8, height: 8)
                .overlay {
                    if completed == total {
                        Image(systemName: "checkmark")
                            .font(.system(size: 5, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
        }
    }
}

// MARK: - iOS 26 Week Progress

/// Indicateur de progression de la semaine style iOS 26
struct WeekProgressIndicator: View {
    let sessions: [(type: SessionType, isCompleted: Bool, isToday: Bool)]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(sessions.enumerated()), id: \.offset) { _, session in
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(session.isCompleted ? Color.forSessionType(session.type) : Color.forSessionType(session.type).opacity(0.15))
                            .frame(width: 40, height: 40)

                        if session.isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        } else {
                            Image(systemName: session.type.icon)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(session.isToday ? Color.forSessionType(session.type) : .secondary)
                        }
                    }
                    .overlay {
                        if session.isToday && !session.isCompleted {
                            Circle()
                                .stroke(Color.forSessionType(session.type), lineWidth: 2)
                                .frame(width: 46, height: 46)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Progress Components") {
    ScrollView {
        VStack(spacing: 30) {
            // Progress Rings
            HStack(spacing: 20) {
                ProgressRing(progress: 0.3, color: .blue)
                ProgressRing(progress: 0.6, color: .green)
                ProgressRing(progress: 0.9, color: .orange)
            }

            // Progress Ring with Content
            ProgressRingWithContent(progress: 0.75, color: .purple, size: 100) {
                VStack {
                    Text("75%")
                        .font(.title2.bold())
                    Text("3/4")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Circular Timer
            CircularTimer(remainingSeconds: 90, totalSeconds: 120, color: .blue)

            // Progress Bars
            VStack(spacing: 12) {
                ProgressBar(progress: 0.4, color: .green)
                ProgressBar(progress: 0.7, color: .orange)
                ProgressBar(progress: 1.0, color: .blue)
            }
            .padding(.horizontal)

            // Set Indicator
            SetIndicator(
                totalSets: 5,
                completedSets: 2,
                currentSet: 2,
                color: .blue
            )

            // Mini Progress
            HStack(spacing: 16) {
                MiniProgressIndicator(completed: 2, total: 4, color: .blue)
                MiniProgressIndicator(completed: 4, total: 4, color: .green)
            }

            // Week Progress
            WeekProgressIndicator(sessions: [
                (.upper, true, false),
                (.lower, true, false),
                (.pull, false, true),
                (.legs, false, false),
                (.push, false, false)
            ])
        }
        .padding()
    }
    .background(Color.appBackground)
}
