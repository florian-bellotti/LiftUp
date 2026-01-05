import SwiftUI

/// Ligne représentant un exercice dans la liste de la séance
struct ExerciseRowView: View {
    let sessionExercise: SessionExercise
    let index: Int
    let isSelected: Bool
    let onTap: () -> Void

    private var exercise: Exercise? {
        sessionExercise.plannedExercise?.exercise
    }

    private var plannedExercise: PlannedExercise? {
        sessionExercise.plannedExercise
    }

    private var completedSets: Int {
        sessionExercise.sets.filter { $0.isCompleted && !$0.isWarmup }.count
    }

    private var totalWorkingSets: Int {
        sessionExercise.sets.filter { !$0.isWarmup }.count
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Image de l'exercice
                exerciseImage

                // Infos
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise?.name ?? "Exercice")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    HStack(spacing: 8) {
                        // Objectif
                        if let planned = plannedExercise {
                            Text("\(planned.targetRepsDisplay) reps")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        // Progression des séries
                        SetIndicator(
                            totalSets: totalWorkingSets,
                            completedSets: completedSets,
                            currentSet: sessionExercise.isCompleted ? nil : completedSets,
                            color: statusColor,
                            dotSize: 8,
                            spacing: 4
                        )
                    }

                    // Résumé des séries complétées
                    if !sessionExercise.completedSets.isEmpty {
                        Text(setsPreview)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Status indicator
                statusIndicator
            }
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? statusColor.opacity(0.15) : Color.appSecondaryBackground)
                    .overlay {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(statusColor.opacity(0.4), lineWidth: 2)
                        }
                    }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Exercise Image

    private var exerciseImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(statusColor.opacity(0.2))
                .frame(width: 56, height: 56)

            if let imageName = exercise?.imageName, imageName != "exercise_placeholder" {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
            } else {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title2)
                    .foregroundStyle(statusColor)
            }

            // Badge numéro
            Text("\(index + 1)")
                .font(.caption2.bold())
                .foregroundStyle(.white)
                .padding(4)
                .background(statusColor)
                .clipShape(Circle())
                .offset(x: -24, y: -24)
        }
    }

    // MARK: - Status

    private var statusColor: Color {
        if sessionExercise.isCompleted {
            return Color.appPrimary
        } else if sessionExercise.isSkipped {
            return Color.warning
        } else if completedSets > 0 {
            return Color.appPrimary.opacity(0.7)
        }
        return Color.secondary
    }

    private var statusIndicator: some View {
        Group {
            if sessionExercise.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.appPrimary)
            } else if sessionExercise.isSkipped {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.warning)
            } else {
                Image(systemName: "chevron.right")
                    .font(.body)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Sets Preview

    private var setsPreview: String {
        let completed = sessionExercise.completedSets
        guard !completed.isEmpty else { return "" }

        return completed
            .map { $0.displayFormat }
            .joined(separator: " • ")
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        ExerciseRowView(
            sessionExercise: SessionExercise(),
            index: 0,
            isSelected: true,
            onTap: {}
        )

        ExerciseRowView(
            sessionExercise: SessionExercise(isCompleted: true),
            index: 1,
            isSelected: false,
            onTap: {}
        )

        ExerciseRowView(
            sessionExercise: SessionExercise(isSkipped: true),
            index: 2,
            isSelected: false,
            onTap: {}
        )
    }
    .padding()
}
