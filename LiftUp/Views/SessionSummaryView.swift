import SwiftUI

/// Vue de résumé à la fin d'une séance - Style iOS 26
struct SessionSummaryView: View {
    let session: WorkoutSession
    let analysis: SessionAnalysis
    let onDismiss: () -> Void

    @State private var showConfetti = false

    private var sessionColor: Color {
        Color.forSessionType(session.sessionType)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header avec animation
                    headerSection

                    // Stats principales
                    mainStatsSection

                    // PRs et améliorations
                    if analysis.hasPRs {
                        prsSection
                    }

                    // Améliorations
                    if !analysis.improvements.isEmpty {
                        improvementsSection
                    }

                    // Régressions (si présentes)
                    if !analysis.regressions.isEmpty {
                        regressionsSection
                    }

                    // Détail des exercices
                    exercisesDetailSection

                    // Action
                    iOS26Button("Terminer", icon: "checkmark", color: .success) {
                        onDismiss()
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color.appBackground)
            .navigationTitle("Séance terminée")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: generateShareText()) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .onAppear {
                if analysis.hasPRs {
                    showConfetti = true
                }
            }
            .overlay {
                if showConfetti {
                    ConfettiView()
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 20) {
            // Icône animée
            ZStack {
                Circle()
                    .fill(sessionColor.opacity(0.12))
                    .frame(width: 100, height: 100)

                if analysis.hasPRs {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.yellow)
                        .symbolEffect(.bounce, options: .repeating)
                } else if analysis.isPositive {
                    Image(systemName: "hand.thumbsup.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.success)
                } else {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 44))
                        .foregroundStyle(sessionColor)
                }
            }

            VStack(spacing: 6) {
                Text(session.sessionType.displayName)
                    .font(.title2.weight(.bold))

                Text(analysis.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 12)
    }

    // MARK: - Main Stats

    private var mainStatsSection: some View {
        iOS26CardView(cornerRadius: 16, padding: 16) {
            HStack(spacing: 0) {
                statItem(
                    value: session.durationDisplay,
                    label: "Durée",
                    icon: "timer"
                )

                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 1, height: 44)

                statItem(
                    value: "\(session.completedExercises.count)/\(session.exercises.count)",
                    label: "Exercices",
                    icon: "dumbbell.fill"
                )

                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 1, height: 44)

                statItem(
                    value: "\(session.totalSets)",
                    label: "Séries",
                    icon: "repeat"
                )

                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 1, height: 44)

                statItem(
                    value: formatVolume(session.totalVolume),
                    label: "Volume",
                    icon: "scalemass.fill"
                )
            }
        }
    }

    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline.weight(.semibold).monospacedDigit())

            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - PRs Section

    private var prsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.yellow)
                Text("Nouveaux records !")
                    .font(.headline)
            }

            VStack(spacing: 8) {
                ForEach(analysis.prs, id: \.self) { pr in
                    iOS26AccentCardView(color: .yellow, cornerRadius: 12, padding: 12) {
                        HStack {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow)

                            Text(pr)
                                .font(.subheadline)

                            Spacer()

                            iOS26Badge(text: "PR", color: .yellow, size: .small)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Improvements Section

    private var improvementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundStyle(Color.success)
                Text("Améliorations")
                    .font(.headline)
            }

            VStack(spacing: 6) {
                ForEach(analysis.improvements, id: \.self) { improvement in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(Color.success)

                        Text(improvement)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()
                    }
                    .padding(12)
                    .background(Color.success.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
    }

    // MARK: - Regressions Section

    private var regressionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundStyle(Color.warning)
                Text("À surveiller")
                    .font(.headline)
            }

            VStack(spacing: 6) {
                ForEach(analysis.regressions, id: \.self) { regression in
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(Color.warning)

                        Text(regression)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()
                    }
                    .padding(12)
                    .background(Color.warning.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
    }

    // MARK: - Exercises Detail

    private var exercisesDetailSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Détail des exercices")
                .sectionTitleStyle()

            iOS26CardView(cornerRadius: 12, padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(session.sortedExercises.enumerated()), id: \.element.id) { index, exercise in
                        exerciseDetailRow(exercise)

                        if index < session.sortedExercises.count - 1 {
                            Divider()
                                .padding(.leading, 44)
                        }
                    }
                }
            }
        }
    }

    private func exerciseDetailRow(_ exercise: SessionExercise) -> some View {
        let isCompleted = exercise.isCompleted
        let isSkipped = exercise.isSkipped

        return HStack(spacing: 12) {
            // Status icon
            Image(systemName: isSkipped ? "arrow.right.circle.fill" : (isCompleted ? "checkmark.circle.fill" : "circle"))
                .font(.body)
                .foregroundColor(isSkipped ? Color.warning : (isCompleted ? Color.success : Color.gray.opacity(0.5)))

            // Exercise name
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.plannedExercise?.exercise?.name ?? "Exercice")
                    .font(.subheadline)
                    .foregroundStyle(isSkipped ? .secondary : .primary)

                if !exercise.completedSets.isEmpty {
                    Text(exercise.completedSets.map(\.displayFormat).joined(separator: " • "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Volume
            if exercise.totalVolume > 0 {
                Text(formatVolume(exercise.totalVolume))
                    .font(.caption.weight(.medium).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Helpers

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        }
        return String(format: "%.0f kg", volume)
    }

    private func generateShareText() -> String {
        var text = "Séance \(session.sessionType.displayName) terminée !\n\n"
        text += "Durée: \(session.durationDisplay)\n"
        text += "Exercices: \(session.completedExercises.count)/\(session.exercises.count)\n"
        text += "Volume: \(formatVolume(session.totalVolume))\n"

        if analysis.hasPRs {
            text += "\nNouveaux records:\n"
            for pr in analysis.prs {
                text += "• \(pr)\n"
            }
        }

        text += "\n#LiftUp"
        return text
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var particles: [(id: Int, x: CGFloat, y: CGFloat, rotation: Double, color: Color)] = []

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                for particle in particles {
                    let rect = CGRect(
                        x: particle.x * size.width,
                        y: particle.y * size.height,
                        width: 8,
                        height: 8
                    )

                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(particle.color)
                    )
                }
            }
        }
        .onAppear {
            createParticles()
        }
    }

    private func createParticles() {
        let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]

        for i in 0..<50 {
            let particle = (
                id: i,
                x: CGFloat.random(in: 0...1),
                y: CGFloat.random(in: -0.2...0),
                rotation: Double.random(in: 0...360),
                color: colors.randomElement()!
            )
            particles.append(particle)
        }

        // Animate particles falling
        withAnimation(.easeIn(duration: 3)) {
            for i in particles.indices {
                particles[i].y += 1.5
            }
        }

        // Remove after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            particles.removeAll()
        }
    }
}

// MARK: - Preview

#Preview {
    SessionSummaryView(
        session: WorkoutSession(sessionType: .upper, weekNumber: 16, isCompleted: true),
        analysis: SessionAnalysis(
            improvements: ["Bench Press: +2 reps à 80kg", "Pull-up: meilleur volume"],
            regressions: ["Curl: volume en baisse"],
            prs: ["Squat: 100kg (+5kg)"],
            volumeChange: 500,
            volumeChangePercent: 8.5,
            summary: "Excellente séance ! 1 nouveau record personnel !"
        ),
        onDismiss: {}
    )
}
