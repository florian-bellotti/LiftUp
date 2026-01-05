import SwiftUI

// MARK: - Main View

struct ExerciseView: View {
    let sessionExercise: SessionExercise
    @ObservedObject var viewModel: SessionViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var currentSetIndex: Int = 0
    @State private var reps: Int = 10
    @State private var weight: Double = 0
    @State private var showingTimer = false
    @State private var showingWeightKeypad = false
    @State private var showingRepsKeypad = false
    @State private var dragOffset: CGFloat = 0

    private var sessionColor: Color {
        .appPrimary
    }

    private var exercise: Exercise? {
        sessionExercise.plannedExercise?.exercise
    }

    private var plannedExercise: PlannedExercise? {
        sessionExercise.plannedExercise
    }

    private var workingSets: [ExerciseSet] {
        sessionExercise.sortedSets.filter { !$0.isWarmup }
    }

    private var currentSet: ExerciseSet? {
        guard currentSetIndex < workingSets.count else { return nil }
        return workingSets[currentSetIndex]
    }

    private var previousSets: [ExerciseSet] {
        viewModel.getPreviousSetsForCurrentExercise().filter { !$0.isWarmup }
    }

    private var previousSet: ExerciseSet? {
        guard currentSetIndex < previousSets.count else { return nil }
        return previousSets[currentSetIndex]
    }

    var body: some View {
        ZStack {
            // Background
            backgroundView
                .ignoresSafeArea()

            // Content
            VStack(spacing: 0) {
                // Header
                headerView

                Spacer()

                // Central content
                if showingTimer && viewModel.isTimerRunning {
                    timerView
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.85).combined(with: .opacity),
                            removal: .scale(scale: 1.1).combined(with: .opacity)
                        ))
                } else {
                    inputView
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.85).combined(with: .opacity),
                            removal: .scale(scale: 1.1).combined(with: .opacity)
                        ))
                }

                Spacer()

                // Bottom actions
                bottomActionsView
            }
            .padding(.top, 16)
            .padding(.bottom, 16)
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingTimer)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewModel.isTimerRunning)
        .onAppear { setupInitialValues() }
        .onChange(of: currentSetIndex) { _, _ in setupInitialValues() }
        .sheet(isPresented: $showingWeightKeypad) {
            NumberInputSheet(
                title: "Poids",
                subtitle: "kg",
                value: $weight,
                isDecimal: true,
                accentColor: sessionColor
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(32)
        }
        .sheet(isPresented: $showingRepsKeypad) {
            NumberInputSheet(
                title: "Répétitions",
                subtitle: nil,
                value: Binding(
                    get: { Double(reps) },
                    set: { reps = Int($0) }
                ),
                isDecimal: false,
                accentColor: sessionColor
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(32)
        }
        .gesture(dismissGesture)
    }

    // MARK: - Background

    private var backgroundView: some View {
        ZStack {
            Color.appBackground

            // Gradient subtil avec la couleur de la séance
            LinearGradient(
                colors: [
                    sessionColor.opacity(0.08),
                    Color.appBackground
                ],
                startPoint: .top,
                endPoint: .center
            )
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 24) {
            // Drag indicator
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 40, height: 4)

            // Exercise info
            VStack(spacing: 8) {
                Text(exercise?.name ?? "Exercice")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                if let planned = plannedExercise {
                    Text("Objectif: \(planned.targetRepsDisplay) reps")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 32)

            // Progress pills
            progressPillsView
        }
        .frame(maxWidth: .infinity)
    }

    private var progressPillsView: some View {
        HStack(spacing: 8) {
            ForEach(0..<workingSets.count, id: \.self) { index in
                ProgressPill(
                    index: index,
                    isCompleted: workingSets[index].isCompleted,
                    isCurrent: index == currentSetIndex,
                    accentColor: sessionColor
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        currentSetIndex = index
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background {
            Capsule()
                .fill(Color.cardSurface)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        }
    }

    // MARK: - Input View

    private var inputView: some View {
        VStack(spacing: 24) {
            // Previous session badge
            if viewModel.isLoadingPreviousSession {
                loadingPreviousBadge
            } else if let prev = previousSet {
                previousBadge(prev)
            }

            // Input cards
            HStack(spacing: 12) {
                InputCard(
                    label: "REPS",
                    value: "\(reps)",
                    accentColor: sessionColor,
                    onTap: { showingRepsKeypad = true },
                    onIncrement: {
                        withAnimation(.spring(response: 0.25)) { reps += 1 }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    },
                    onDecrement: {
                        if reps > 1 {
                            withAnimation(.spring(response: 0.25)) { reps -= 1 }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                )

                InputCard(
                    label: "KG",
                    value: formatWeight(weight),
                    accentColor: sessionColor,
                    onTap: { showingWeightKeypad = true },
                    onIncrement: {
                        withAnimation(.spring(response: 0.25)) { weight += 2.5 }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    },
                    onDecrement: {
                        if weight >= 2.5 {
                            withAnimation(.spring(response: 0.25)) { weight -= 2.5 }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
    }

    private var loadingPreviousBadge: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.8)

            Text("Chargement dernière séance...")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background {
            Capsule()
                .fill(Color.secondary.opacity(0.1))
        }
    }

    private func previousBadge(_ prevSet: ExerciseSet) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(sessionColor)

            Text("Dernière séance")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            Text("•")
                .foregroundStyle(.tertiary)

            Text("\(prevSet.reps) reps")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)

            if prevSet.weight > 0 {
                Text("×")
                    .foregroundStyle(.tertiary)

                Text("\(formatWeight(prevSet.weight)) kg")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background {
            Capsule()
                .fill(sessionColor.opacity(0.1))
        }
    }

    // MARK: - Timer View

    private var timerView: some View {
        VStack(spacing: 32) {
            // Timer ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 12)
                    .frame(width: 220, height: 220)

                // Progress ring
                Circle()
                    .trim(from: 0, to: 1 - CGFloat(viewModel.timerSeconds) / CGFloat(max(viewModel.targetRestSeconds, 1)))
                    .stroke(
                        sessionColor,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 220, height: 220)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: viewModel.timerSeconds)

                // Center content
                VStack(spacing: 6) {
                    Text(viewModel.timerDisplay)
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .monospacedDigit()

                    Text("REPOS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                        .tracking(2)

                    // Prochaine série - données de la dernière fois
                    if let prev = previousSet {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 10))
                            Text("\(prev.reps) × \(formatWeight(prev.weight))kg")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(sessionColor)
                        .padding(.top, 4)
                    }
                }
            }

            // Timer controls
            HStack(spacing: 20) {
                TimerControlButton(text: "-15") {
                    viewModel.addTime(-15)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }

                Button {
                    viewModel.stopTimer()
                    showingTimer = false
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 64, height: 64)
                        .background {
                            Circle()
                                .fill(Color.cardSurface)
                                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
                        }
                }

                TimerControlButton(text: "+15") {
                    viewModel.addTime(15)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
        }
    }

    // MARK: - Bottom Actions

    private var bottomActionsView: some View {
        VStack(spacing: 12) {
            // Main action button
            Button {
                validateCurrentSet()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))

                    Text("Valider la série")
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(sessionColor)
                }
            }

            // Secondary actions
            HStack(spacing: 32) {
                Button {
                    skipCurrentSet()
                } label: {
                    Label("Passer", systemImage: "forward.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Button {
                    dismiss()
                } label: {
                    Label("Fermer", systemImage: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
    }

    // MARK: - Gestures

    private var dismissGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if value.translation.height > 0 {
                    dragOffset = value.translation.height
                }
            }
            .onEnded { value in
                if value.translation.height > 120 {
                    dismiss()
                }
                withAnimation(.spring(response: 0.3)) {
                    dragOffset = 0
                }
            }
    }

    // MARK: - Actions

    private func setupInitialValues() {
        if currentSetIndex < previousSets.count {
            let prev = previousSets[currentSetIndex]
            reps = prev.reps
            weight = prev.weight
        } else if let suggestion = viewModel.getSuggestionForCurrentExercise() {
            reps = suggestion.suggestedReps
            weight = suggestion.suggestedWeight
        }
    }

    private func validateCurrentSet() {
        guard let set = currentSet else { return }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        viewModel.recordSet(set, reps: reps, weight: weight)

        let isLastSet = currentSetIndex >= workingSets.count - 1

        if !isLastSet {
            showingTimer = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                currentSetIndex += 1
            }
        } else {
            sessionExercise.markCompleted()
            viewModel.stopTimer()
            dismiss()
        }
    }

    private func skipCurrentSet() {
        guard let set = currentSet else { return }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        set.markSkipped()

        let isLastSet = currentSetIndex >= workingSets.count - 1
        if !isLastSet {
            withAnimation { currentSetIndex += 1 }
        } else {
            sessionExercise.markCompleted()
            dismiss()
        }
    }

    private func formatWeight(_ weight: Double) -> String {
        if weight == 0 { return "0" }
        return weight.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", weight)
            : String(format: "%.1f", weight)
    }
}

// MARK: - Progress Pill

private struct ProgressPill: View {
    let index: Int
    let isCompleted: Bool
    let isCurrent: Bool
    let accentColor: Color

    var body: some View {
        ZStack {
            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
            } else {
                Text("\(index + 1)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(isCurrent ? .white : .secondary)
            }
        }
        .frame(width: 36, height: 36)
        .background {
            Circle()
                .fill(backgroundColor)
        }
        .overlay {
            // Anneau blanc pour la série en cours
            if isCurrent {
                Circle()
                    .strokeBorder(.white, lineWidth: 3)
                    .shadow(color: accentColor.opacity(0.5), radius: 4, x: 0, y: 0)
            }
        }
        .scaleEffect(isCurrent ? 1.15 : 1.0)
        .animation(.spring(response: 0.3), value: isCurrent)
    }

    private var backgroundColor: Color {
        if isCurrent {
            return accentColor
        } else if isCompleted {
            return accentColor.opacity(0.5)
        } else {
            return Color.secondary.opacity(0.12)
        }
    }
}

// MARK: - Input Card

private struct InputCard: View {
    let label: String
    let value: String
    let accentColor: Color
    let onTap: () -> Void
    let onIncrement: () -> Void
    let onDecrement: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
                .tracking(2)

            Button(action: onTap) {
                Text(value)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }

            HStack(spacing: 16) {
                StepperButton(icon: "minus", color: accentColor, action: onDecrement)
                StepperButton(icon: "plus", color: accentColor, action: onIncrement)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.cardSurface)
                .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
        }
    }
}

// MARK: - Stepper Button

private struct StepperButton: View {
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background {
                    Circle()
                        .fill(color.opacity(0.12))
                }
        }
    }
}

// MARK: - Timer Control Button

private struct TimerControlButton: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(width: 72, height: 48)
                .background {
                    Capsule()
                        .fill(Color.cardSurface)
                        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
                }
        }
    }
}

// MARK: - Number Input Sheet

private struct NumberInputSheet: View {
    let title: String
    let subtitle: String?
    @Binding var value: Double
    let isDecimal: Bool
    let accentColor: Color

    @Environment(\.dismiss) private var dismiss
    @State private var inputString: String = ""

    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Spacer()

                VStack(spacing: 2) {
                    Text(title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.primary)

                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
            .overlay(alignment: .trailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary.opacity(0.5))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            // Display
            Text(inputString.isEmpty ? "0" : inputString)
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)

            // Keypad
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(1...9, id: \.self) { num in
                    KeypadButton(text: "\(num)") {
                        inputString += "\(num)"
                    }
                }

                if isDecimal {
                    KeypadButton(text: ",") {
                        if !inputString.contains(".") {
                            inputString += inputString.isEmpty ? "0." : "."
                        }
                    }
                } else {
                    Color.clear.frame(height: 64)
                }

                KeypadButton(text: "0") {
                    if !inputString.isEmpty || isDecimal {
                        inputString += "0"
                    }
                }

                KeypadButton(text: "⌫", isDestructive: true) {
                    if !inputString.isEmpty {
                        inputString.removeLast()
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color.appBackground)
        .onAppear {
            if value > 0 {
                if isDecimal {
                    inputString = value.truncatingRemainder(dividingBy: 1) == 0
                        ? String(format: "%.0f", value)
                        : String(format: "%.1f", value)
                } else {
                    inputString = String(Int(value))
                }
            }
        }
        .onChange(of: inputString) { _, newValue in
            // Mise à jour en temps réel
            if let newDouble = Double(newValue) {
                value = newDouble
            } else if newValue.isEmpty {
                value = 0
            }
        }
    }
}

// MARK: - Keypad Button

private struct KeypadButton: View {
    let text: String
    var isDestructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button {
            action()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Text(text)
                .font(.system(size: 28, weight: .medium, design: .rounded))
                .foregroundStyle(isDestructive ? Color.red : .primary)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.cardSurface)
                        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
                }
        }
    }
}

// MARK: - Preview

#Preview {
    ExerciseView(
        sessionExercise: SessionExercise(),
        viewModel: SessionViewModel(
            session: WorkoutSession(sessionType: .upper, weekNumber: 16),
            dataService: DataService()
        )
    )
}
