import ActivityKit
import SwiftUI
import WidgetKit

/// Live Activity pour le timer de repos
struct TimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            // Lock Screen / Banner UI
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI (quand on maintient appuyé sur la Dynamic Island)
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 4) {
                        Image(systemName: "dumbbell.fill")
                            .foregroundStyle(.orange)
                        Text("Série \(context.attributes.setNumber)/\(context.attributes.totalSets)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.displayTime)
                        .font(.title2.monospacedDigit())
                        .fontWeight(.bold)
                        .foregroundStyle(context.state.isAlmostFinished ? .orange : .primary)
                }

                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.exerciseName)
                        .font(.headline)
                        .lineLimit(1)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    // Barre de progression
                    ProgressView(value: context.state.progress)
                        .progressViewStyle(.linear)
                        .tint(progressColor(for: context.state))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                        .padding(.horizontal)

                    if context.state.isFinished {
                        Text("C'est reparti ! 💪")
                            .font(.subheadline.bold())
                            .foregroundStyle(.green)
                            .padding(.top, 8)
                    } else if context.state.isPaused {
                        Text("En pause")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                }
            } compactLeading: {
                // Vue compacte - partie gauche
                Image(systemName: "timer")
                    .foregroundStyle(context.state.isAlmostFinished ? .orange : .blue)
            } compactTrailing: {
                // Vue compacte - partie droite
                Text(context.state.displayTime)
                    .font(.caption.monospacedDigit())
                    .fontWeight(.semibold)
                    .foregroundStyle(context.state.isAlmostFinished ? .orange : .primary)
            } minimal: {
                // Vue minimale (quand il y a plusieurs activités)
                ZStack {
                    Circle()
                        .strokeBorder(
                            context.state.isAlmostFinished ? Color.orange : Color.blue,
                            lineWidth: 2
                        )
                    Text("\(context.state.remainingSeconds)")
                        .font(.caption2.monospacedDigit())
                        .fontWeight(.bold)
                }
            }
        }
    }

    private func progressColor(for state: TimerActivityAttributes.ContentState) -> Color {
        if state.isFinished {
            return .green
        } else if state.isAlmostFinished {
            return .orange
        } else {
            return .blue
        }
    }
}

// MARK: - Lock Screen View

struct LockScreenView: View {
    let context: ActivityViewContext<TimerActivityAttributes>

    var body: some View {
        HStack(spacing: 16) {
            // Timer circulaire
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 6)

                Circle()
                    .trim(from: 0, to: CGFloat(context.state.progress))
                    .stroke(
                        progressGradient,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text(context.state.displayTime)
                        .font(.title2.monospacedDigit())
                        .fontWeight(.bold)
                        .foregroundStyle(context.state.isAlmostFinished ? .orange : .primary)

                    if context.state.isPaused {
                        Image(systemName: "pause.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 80, height: 80)

            // Infos exercice
            VStack(alignment: .leading, spacing: 4) {
                Text("Repos")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(context.attributes.exerciseName)
                    .font(.headline)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Image(systemName: "dumbbell.fill")
                        .font(.caption2)
                    Text("Série \(context.attributes.setNumber)/\(context.attributes.totalSets)")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)

                if context.state.isFinished {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("C'est reparti !")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(.green)
                }
            }

            Spacer()
        }
        .padding()
        .activityBackgroundTint(Color.black.opacity(0.8))
        .activitySystemActionForegroundColor(.white)
    }

    private var progressGradient: AngularGradient {
        if context.state.isFinished {
            return AngularGradient(
                colors: [.green, .green],
                center: .center
            )
        } else if context.state.isAlmostFinished {
            return AngularGradient(
                colors: [.orange, .red],
                center: .center
            )
        } else {
            return AngularGradient(
                colors: [.blue, .cyan],
                center: .center
            )
        }
    }
}

// MARK: - Preview

#Preview("Lock Screen", as: .content, using: TimerActivityAttributes.preview) {
    TimerLiveActivity()
} contentStates: {
    TimerActivityAttributes.ContentState(remainingSeconds: 90, totalSeconds: 120, isPaused: false)
    TimerActivityAttributes.ContentState(remainingSeconds: 8, totalSeconds: 120, isPaused: false)
    TimerActivityAttributes.ContentState(remainingSeconds: 0, totalSeconds: 120, isPaused: false)
}

// MARK: - Preview Data

extension TimerActivityAttributes {
    static var preview: TimerActivityAttributes {
        TimerActivityAttributes(
            exerciseName: "Développé couché",
            setNumber: 2,
            totalSets: 4
        )
    }
}
