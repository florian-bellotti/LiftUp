import SwiftUI

/// Vue d'accueil de l'app Watch
struct WatchHomeView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager

    var body: some View {
        NavigationStack {
            if let session = connectivity.currentSession {
                WatchSessionView(session: session)
            } else {
                noSessionView
            }
        }
    }

    private var noSessionView: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("Pas de séance")
                .font(.headline)

            Text("Démarre une séance sur ton iPhone")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if !connectivity.isConnected {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Non connecté")
                        .font(.caption2)
                }
                .padding(.top)
            }
        }
        .padding()
    }
}

/// Vue de séance sur Watch
struct WatchSessionView: View {
    let session: WatchWorkoutData
    @EnvironmentObject var connectivity: WatchConnectivityManager

    @State private var reps: Int = 10
    @State private var weight: Double = 0
    @State private var showingInput = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Header
                VStack(spacing: 4) {
                    Text(session.sessionType)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text(session.currentExerciseName)
                        .font(.headline)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)

                    Text("Exercice \(session.currentExerciseIndex + 1)/\(session.totalExercises)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Divider()

                // Timer si actif
                if connectivity.isTimerRunning {
                    timerSection
                } else {
                    // Set info
                    setInfoSection
                }

                // Actions
                actionButtons
            }
            .padding()
        }
        .navigationTitle("Série \(session.currentSetNumber)")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingInput) {
            WatchSetInputView(
                reps: $reps,
                weight: $weight,
                targetReps: session.targetReps,
                suggestedReps: session.suggestedReps,
                suggestedWeight: session.suggestedWeight,
                onSave: {
                    connectivity.recordSet(reps: reps, weight: weight)
                    showingInput = false
                }
            )
        }
        .onAppear {
            reps = session.suggestedReps
            weight = session.suggestedWeight
        }
    }

    private var timerSection: some View {
        VStack(spacing: 8) {
            // Timer display
            Text(formatTime(connectivity.timerSeconds))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .monospacedDigit()

            Text("Repos")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Timer controls
            HStack(spacing: 12) {
                Button {
                    connectivity.addTimerTime(-15)
                } label: {
                    Text("-15")
                        .font(.caption2)
                }

                Button {
                    connectivity.stopTimer()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }

                Button {
                    connectivity.addTimerTime(15)
                } label: {
                    Text("+15")
                        .font(.caption2)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var setInfoSection: some View {
        VStack(spacing: 8) {
            Text("Objectif: \(session.targetReps) reps")
                .font(.caption)

            if let previous = session.previousSetDisplay {
                HStack {
                    Text("Dernière fois:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(previous)
                        .font(.caption.bold())
                }
            }

            // Suggestion
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                    .font(.caption2)
                Text("\(session.suggestedReps) @ \(formatWeight(session.suggestedWeight))")
                    .font(.caption)
            }
            .padding(6)
            .background(Color.yellow.opacity(0.2))
            .clipShape(Capsule())
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 8) {
            Button {
                showingInput = true
            } label: {
                Label("Enregistrer", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)

            HStack {
                Button {
                    connectivity.skipSet()
                } label: {
                    Image(systemName: "forward.fill")
                }
                .buttonStyle(.bordered)

                Button {
                    connectivity.nextExercise()
                } label: {
                    Image(systemName: "chevron.right.2")
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func formatWeight(_ weight: Double) -> String {
        if weight == 0 { return "0kg" }
        return weight.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0fkg", weight)
            : String(format: "%.1fkg", weight)
    }
}

/// Vue de saisie simplifiée pour Watch
struct WatchSetInputView: View {
    @Binding var reps: Int
    @Binding var weight: Double
    let targetReps: String
    let suggestedReps: Int
    let suggestedWeight: Double
    let onSave: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Reps
                VStack(spacing: 4) {
                    Text("Répétitions")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    HStack {
                        Button {
                            if reps > 1 { reps -= 1 }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title3)
                        }
                        .buttonStyle(.plain)

                        Text("\(reps)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .frame(width: 60)

                        Button {
                            reps += 1
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Weight
                VStack(spacing: 4) {
                    Text("Poids (kg)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    HStack {
                        Button {
                            if weight >= 2.5 { weight -= 2.5 }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title3)
                        }
                        .buttonStyle(.plain)

                        Text(formatWeight(weight))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .frame(width: 70)

                        Button {
                            weight += 2.5
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Save button
                Button(action: onSave) {
                    Text("Valider")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .padding()
        }
    }

    private func formatWeight(_ weight: Double) -> String {
        if weight == 0 { return "0" }
        return weight.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", weight)
            : String(format: "%.1f", weight)
    }
}

#Preview {
    WatchHomeView()
        .environmentObject(WatchConnectivityManager())
}
