import SwiftUI

/// Vue pour saisir les reps et le poids d'une série
struct SetInputView: View {
    let exerciseSet: ExerciseSet
    let targetReps: String
    let onSave: (Int, Double) -> Void
    let onCancel: () -> Void

    @State private var reps: Int
    @State private var weight: Double
    @FocusState private var focusedField: Field?

    private enum Field {
        case reps, weight
    }

    init(
        exerciseSet: ExerciseSet,
        targetReps: String,
        onSave: @escaping (Int, Double) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.exerciseSet = exerciseSet
        self.targetReps = targetReps
        self.onSave = onSave
        self.onCancel = onCancel
        _reps = State(initialValue: exerciseSet.reps > 0 ? exerciseSet.reps : 10)
        _weight = State(initialValue: exerciseSet.weight)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 4) {
                    Text("Série \(exerciseSet.setNumber)")
                        .font(.headline)

                    if exerciseSet.isWarmup {
                        GlassBadge(text: "ÉCHAUFFEMENT", color: .orange)
                    } else {
                        Text("Objectif: \(targetReps) reps")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                // Input section
                HStack(spacing: 20) {
                    // Reps input
                    VStack(spacing: 8) {
                        Text("Répétitions")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 12) {
                            Button {
                                if reps > 1 { reps -= 1 }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(.secondary)
                            }

                            Text("\(reps)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .frame(minWidth: 80)
                                .contentTransition(.numericText())

                            Button {
                                reps += 1
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(Color.accentColor)
                            }
                        }

                        // Quick reps buttons
                        HStack(spacing: 8) {
                            ForEach([6, 8, 10, 12, 15], id: \.self) { value in
                                Button("\(value)") {
                                    withAnimation { reps = value }
                                }
                                .font(.caption.bold())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(reps == value ? Color.accentColor : Color.gray.opacity(0.2))
                                .foregroundStyle(reps == value ? .white : .primary)
                                .clipShape(Capsule())
                            }
                        }
                    }

                    Divider()
                        .frame(height: 100)

                    // Weight input
                    VStack(spacing: 8) {
                        Text("Poids (kg)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 12) {
                            Button {
                                if weight >= 2.5 { weight -= 2.5 }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(.secondary)
                            }

                            Text(weightDisplay)
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .frame(minWidth: 100)
                                .contentTransition(.numericText())

                            Button {
                                weight += 2.5
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(Color.accentColor)
                            }
                        }

                        // Quick weight adjustment
                        HStack(spacing: 8) {
                            ForEach([-5.0, -1.0, 1.0, 5.0], id: \.self) { delta in
                                Button(delta > 0 ? "+\(Int(delta))" : "\(Int(delta))") {
                                    withAnimation {
                                        weight = max(0, weight + delta)
                                    }
                                }
                                .font(.caption.bold())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.gray.opacity(0.2))
                                .clipShape(Capsule())
                            }
                        }
                    }
                }

                Spacer()

                // Preview
                GlassCard {
                    HStack {
                        Text("Résultat:")
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text("\(reps)(\(weightDisplay))")
                            .font(.title2.bold().monospacedDigit())
                    }
                }

                // Save button
                PrimaryButton("Valider", icon: "checkmark", color: .green) {
                    onSave(reps, weight)
                }
            }
            .padding()
            .background(Color.appBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") {
                        onCancel()
                    }
                }
            }
        }
    }

    private var weightDisplay: String {
        if weight == 0 {
            return "0"
        }
        return weight.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", weight)
            : String(format: "%.1f", weight)
    }
}

// MARK: - Preview

#Preview {
    SetInputView(
        exerciseSet: ExerciseSet(setNumber: 1),
        targetReps: "8-12",
        onSave: { _, _ in },
        onCancel: {}
    )
}
