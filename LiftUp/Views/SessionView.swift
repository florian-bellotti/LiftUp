import SwiftUI

/// Vue principale d'une séance en cours - Style iOS 26
struct SessionView: View {
    @StateObject private var viewModel: SessionViewModel
    @Environment(\.dismiss) private var dismiss

    let onCancel: (() -> Void)?

    init(session: WorkoutSession, dataService: DataService, onCancel: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: SessionViewModel(session: session, dataService: dataService))
        self.onCancel = onCancel
    }

    var body: some View {
        ZStack {
            // Background
            backgroundView

            // Main content
            VStack(spacing: 0) {
                // Header
                headerView
                    .padding(.top, 8)

                // Progress section
                progressSection
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                // Exercise list
                exerciseList

                // Bottom action
                if let exercise = viewModel.currentExercise {
                    bottomActionBar(exercise: exercise)
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .task {
            await viewModel.loadPreviousSession()
        }
        .fullScreenCover(isPresented: $viewModel.showingExerciseDetail) {
            if let exercise = viewModel.currentExercise {
                ExerciseView(
                    sessionExercise: exercise,
                    viewModel: viewModel
                )
            }
        }
        .fullScreenCover(isPresented: $viewModel.showingSummary) {
            SessionSummaryView(
                session: viewModel.session,
                analysis: viewModel.getSessionAnalysis()
            ) {
                dismiss()
            }
        }
        .confirmationDialog(
            "Annuler la séance ?",
            isPresented: $viewModel.showingCancelConfirmation,
            titleVisibility: .visible
        ) {
            Button("Annuler la séance", role: .destructive) {
                onCancel?()
                dismiss()
            }
            Button("Continuer", role: .cancel) {}
        } message: {
            Text("Ta progression sera perdue.")
        }
    }

    // MARK: - Background

    private var backgroundView: some View {
        ZStack {
            Color.appBackground

            // Gradient subtil avec la couleur de la séance
            LinearGradient(
                colors: [
                    Color.appPrimary.opacity(0.08),
                    Color.appBackground
                ],
                startPoint: .top,
                endPoint: .center
            )
        }
        .ignoresSafeArea()
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Button {
                viewModel.cancelSession()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .background(Color.cardSurface)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
            }

            Spacer()

            VStack(spacing: 2) {
                Text(viewModel.session.sessionType.displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(viewModel.session.durationDisplay)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Menu {
                Button("Terminer", systemImage: "checkmark.circle") {
                    viewModel.completeSession()
                }

                Button("Annuler", systemImage: "trash", role: .destructive) {
                    viewModel.cancelSession()
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .background(Color.cardSurface)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        iOS26CardView(cornerRadius: 16, padding: 16) {
            VStack(spacing: 12) {
                // Stats row
                HStack(spacing: 0) {
                    statItem(
                        icon: "dumbbell.fill",
                        value: "\(viewModel.completedExerciseCount)/\(viewModel.exerciseCount)",
                        label: "Exercices"
                    )

                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 1, height: 32)

                    statItem(
                        icon: "flame.fill",
                        value: "\(viewModel.session.totalSets)",
                        label: "Séries"
                    )
                }

                // Progress bar
                ProgressBar(
                    progress: viewModel.progress,
                    color: .appPrimary,
                    height: 6
                )
            }
        }
    }

    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.subheadline.weight(.semibold).monospacedDigit())
            }

            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Exercise List

    private var exerciseList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(Array(viewModel.session.sortedExercises.enumerated()), id: \.element.id) { index, exercise in
                        ExerciseCard(
                            exercise: exercise,
                            index: index,
                            isSelected: index == viewModel.currentExerciseIndex,
                            sessionType: viewModel.session.sessionType
                        ) {
                            viewModel.goToExercise(at: index)
                            viewModel.showingExerciseDetail = true
                        }
                        .id(exercise.id)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .onChange(of: viewModel.currentExerciseIndex) { _, newIndex in
                if let exercise = viewModel.session.sortedExercises[safe: newIndex] {
                    withAnimation {
                        proxy.scrollTo(exercise.id, anchor: .center)
                    }
                }
            }
        }
    }

    // MARK: - Bottom Action Bar (Mini Player Style)

    private func bottomActionBar(exercise: SessionExercise) -> some View {
        VStack(spacing: 0) {
            // Timer mini si actif
            if viewModel.isTimerRunning {
                miniTimerBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Action button
            Button {
                viewModel.showingExerciseDetail = true
            } label: {
                HStack(spacing: 12) {
                    // Exercise icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.appPrimary)
                            .frame(width: 44, height: 44)

                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 18))
                            .foregroundStyle(.white)
                    }

                    // Exercise info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.plannedExercise?.exercise?.name ?? "Exercice")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Text("Série \(exercise.completedSets.count + 1) sur \(exercise.sets.filter { !$0.isWarmup }.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Play button
                    Image(systemName: "play.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.appPrimary)
                        .clipShape(Circle())
                }
                .padding(12)
                .background(Color.cardSurface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: -4)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(
            LinearGradient(
                colors: [Color.appBackground.opacity(0), Color.appBackground],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 60)
            .offset(y: -60)
            .allowsHitTesting(false),
            alignment: .top
        )
    }

    private var miniTimerBar: some View {
        HStack(spacing: 12) {
            // Timer
            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .font(.caption)
                    .foregroundStyle(Color.info)

                Text(viewModel.timerDisplay)
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.primary)
            }

            Spacer()

            // Controls
            HStack(spacing: 12) {
                Button {
                    viewModel.addTime(-15)
                } label: {
                    Text("-15")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Capsule())
                }

                Button {
                    viewModel.addTime(15)
                } label: {
                    Text("+15")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Capsule())
                }

                Button {
                    viewModel.stopTimer()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.info.opacity(0.08))
    }

    // MARK: - Helpers

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        }
        return String(format: "%.0f kg", volume)
    }
}

// MARK: - Exercise Card (iOS 26 Style)

struct ExerciseCard: View {
    let exercise: SessionExercise
    let index: Int
    let isSelected: Bool
    let sessionType: SessionType
    let onTap: () -> Void

    private var exerciseInfo: Exercise? {
        exercise.plannedExercise?.exercise
    }

    private var completedWorkingSets: Int {
        exercise.sets.filter { $0.isCompleted && !$0.isWarmup }.count
    }

    private var totalWorkingSets: Int {
        exercise.sets.filter { !$0.isWarmup }.count
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Number/Status badge
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(statusColor.opacity(isSelected ? 1 : 0.15))
                        .frame(width: 40, height: 40)

                    if exercise.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(isSelected ? .white : statusColor)
                    } else if exercise.isSkipped {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(isSelected ? .white : statusColor)
                    } else {
                        Text("\(index + 1)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(isSelected ? .white : statusColor)
                    }
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(exerciseInfo?.name ?? "Exercice")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        // Sets indicator
                        if totalWorkingSets > 0 {
                            HStack(spacing: 3) {
                                ForEach(0..<min(totalWorkingSets, 6), id: \.self) { setIndex in
                                    Circle()
                                        .fill(setIndex < completedWorkingSets ? statusColor : statusColor.opacity(0.2))
                                        .frame(width: 6, height: 6)
                                }
                            }
                        }

                        if !exercise.completedSets.isEmpty {
                            Text("•")
                                .foregroundStyle(.tertiary)

                            Text(exercise.completedSets.prefix(2).map { $0.displayFormat }.joined(separator: " "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer(minLength: 8)

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.cardSurface)
                    .shadow(color: isSelected ? statusColor.opacity(0.15) : .black.opacity(0.04), radius: isSelected ? 8 : 4, x: 0, y: 2)
            }
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(statusColor.opacity(0.3), lineWidth: 1.5)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var statusColor: Color {
        if exercise.isCompleted {
            return .appPrimary
        } else if exercise.isSkipped {
            return .warning
        } else if isSelected {
            return .appPrimary
        }
        return .secondary
    }
}

// MARK: - Array Extension

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview

#Preview {
    SessionView(
        session: WorkoutSession(sessionType: .upper, weekNumber: 16),
        dataService: DataService()
    )
}
