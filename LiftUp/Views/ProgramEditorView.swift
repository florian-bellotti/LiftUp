import SwiftUI
import SwiftData

/// Vue pour éditer le programme d'entraînement de la semaine - Style iOS 26
struct ProgramEditorView: View {
    @Bindable var weekProgram: WeekProgram
    let dataService: DataService
    @Environment(\.dismiss) private var dismiss

    @State private var selectedSession: SessionTemplate?
    @State private var showingAddExercise = false
    @State private var editingExercise: PlannedExercise?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Info semaine
                    weekInfoSection

                    // Sessions
                    ForEach(weekProgram.sortedSessions) { session in
                        sessionSection(session)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color.appBackground)
            .navigationTitle("Modifier le programme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Enregistrer") {
                        save()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(item: $editingExercise) { exercise in
                ExerciseEditorView(
                    plannedExercise: exercise,
                    dataService: dataService
                )
            }
            .sheet(isPresented: $showingAddExercise) {
                if let session = selectedSession {
                    AddExerciseView(
                        sessionTemplate: session,
                        dataService: dataService
                    )
                }
            }
        }
    }

    // MARK: - Week Info Section

    private var weekInfoSection: some View {
        iOS26CardView(cornerRadius: 16, padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Semaine \(weekProgram.weekNumber)")
                        .font(.headline)

                    Spacer()

                    iOS26Badge(text: "\(weekProgram.sessions.count) séances", color: .appPrimary, size: .small)
                }

                if let notes = weekProgram.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Session Section

    private func sessionSection(_ session: SessionTemplate) -> some View {
        let color = Color.forSessionType(session.sessionType)

        return VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                iOS26IconView(icon: session.sessionType.icon, color: color, size: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(session.sessionType.displayName)
                        .font(.headline)

                    Text(WeekProgram.dayName(forIndex: session.dayIndex))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(session.exercises.count) exercices")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)

            // Exercises list
            iOS26CardView(cornerRadius: 12, padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(session.sortedExercises.enumerated()), id: \.element.id) { index, exercise in
                        exerciseRow(exercise, index: index, session: session)

                        if index < session.sortedExercises.count - 1 {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }

                    // Add button
                    Button {
                        selectedSession = session
                        showingAddExercise = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(color)

                            Text("Ajouter un exercice")
                                .font(.subheadline)
                                .foregroundStyle(color)

                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func exerciseRow(_ exercise: PlannedExercise, index: Int, session: SessionTemplate) -> some View {
        let color = Color.forSessionType(session.sessionType)

        return Button {
            editingExercise = exercise
        } label: {
            HStack(spacing: 12) {
                // Number badge
                Text("\(index + 1)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(color)
                    .clipShape(Circle())

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.exercise?.name ?? "Exercice")
                        .font(.subheadline)
                        .foregroundStyle(.primary)

                    HStack(spacing: 6) {
                        Text("\(exercise.warmupSets) échauff.")
                        Text("•")
                        Text("\(exercise.targetRepsDisplay) reps")
                        Text("•")
                        Text(exercise.restTimeDisplay)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                deleteExercise(exercise, from: session)
            } label: {
                Label("Supprimer", systemImage: "trash")
            }
        }
    }

    // MARK: - Actions

    private func deleteExercise(_ exercise: PlannedExercise, from session: SessionTemplate) {
        session.exercises.removeAll { $0.id == exercise.id }

        // Reindex remaining exercises
        for (index, ex) in session.sortedExercises.enumerated() {
            ex.orderIndex = index
        }
    }

    private func save() {
        Task {
            try? await dataService.workoutRepository.saveWeekProgram(weekProgram)
            dismiss()
        }
    }
}

// MARK: - Exercise Editor View

struct ExerciseEditorView: View {
    @Bindable var plannedExercise: PlannedExercise
    let dataService: DataService
    @Environment(\.dismiss) private var dismiss

    @State private var warmupSets: Int
    @State private var targetRepsMin: Int
    @State private var targetRepsMax: Int
    @State private var restTimeSeconds: Int
    @State private var notes: String

    init(plannedExercise: PlannedExercise, dataService: DataService) {
        self.plannedExercise = plannedExercise
        self.dataService = dataService
        _warmupSets = State(initialValue: plannedExercise.warmupSets)
        _targetRepsMin = State(initialValue: plannedExercise.targetRepsMin)
        _targetRepsMax = State(initialValue: plannedExercise.targetRepsMax)
        _restTimeSeconds = State(initialValue: plannedExercise.restTimeSeconds)
        _notes = State(initialValue: plannedExercise.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Exercise name
                    iOS26CardView(cornerRadius: 12, padding: 16) {
                        HStack {
                            Text("Exercice")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(plannedExercise.exercise?.name ?? "Non défini")
                                .font(.subheadline.weight(.medium))
                        }
                    }

                    // Warmup sets
                    iOS26CardView(cornerRadius: 12, padding: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Séries d'échauffement")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Stepper("\(warmupSets) série\(warmupSets > 1 ? "s" : "")", value: $warmupSets, in: 0...5)
                                .font(.subheadline.weight(.medium))
                        }
                    }

                    // Target reps
                    iOS26CardView(cornerRadius: 12, padding: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Répétitions cibles")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            HStack {
                                Text("Min")
                                    .font(.subheadline)
                                Spacer()
                                Picker("", selection: $targetRepsMin) {
                                    ForEach(1...30, id: \.self) { num in
                                        Text("\(num)").tag(num)
                                    }
                                }
                                .pickerStyle(.menu)
                            }

                            Divider()

                            HStack {
                                Text("Max")
                                    .font(.subheadline)
                                Spacer()
                                Picker("", selection: $targetRepsMax) {
                                    ForEach(targetRepsMin...30, id: \.self) { num in
                                        Text("\(num)").tag(num)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                        }
                    }

                    // Rest time
                    iOS26CardView(cornerRadius: 12, padding: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Temps de repos")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Picker("Durée", selection: $restTimeSeconds) {
                                ForEach(TimerViewModel.presetRestTimes, id: \.seconds) { preset in
                                    Text(preset.label).tag(preset.seconds)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    // Notes
                    iOS26CardView(cornerRadius: 12, padding: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Notes")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            TextField("Ajouter des notes...", text: $notes, axis: .vertical)
                                .lineLimit(3...6)
                                .font(.subheadline)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color.appBackground)
            .navigationTitle("Modifier l'exercice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Enregistrer") {
                        save()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func save() {
        plannedExercise.warmupSets = warmupSets
        plannedExercise.targetRepsMin = targetRepsMin
        plannedExercise.targetRepsMax = max(targetRepsMin, targetRepsMax)
        plannedExercise.restTimeSeconds = restTimeSeconds
        plannedExercise.notes = notes.isEmpty ? nil : notes
        dismiss()
    }
}

// MARK: - Add Exercise View

struct AddExerciseView: View {
    let sessionTemplate: SessionTemplate
    let dataService: DataService
    @Environment(\.dismiss) private var dismiss

    @State private var exercises: [Exercise] = []
    @State private var searchText = ""

    var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return exercises
        }
        return exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredExercises, id: \.id) { exercise in
                        Button {
                            addExercise(exercise)
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Color.appPrimary.opacity(0.1))
                                        .frame(width: 44, height: 44)

                                    Image(systemName: "figure.strengthtraining.traditional")
                                        .font(.system(size: 18))
                                        .foregroundStyle(Color.appPrimary)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(exercise.name)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)

                                    Text(exercise.muscleGroups.map(\.rawValue).joined(separator: ", "))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(Color.appPrimary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Divider()
                            .padding(.leading, 76)
                    }
                }
            }
            .background(Color.appBackground)
            .searchable(text: $searchText, prompt: "Rechercher un exercice")
            .navigationTitle("Ajouter un exercice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
            .task {
                do {
                    exercises = try await dataService.exerciseRepository.getAllExercises()
                } catch {
                    print("Error loading exercises: \(error)")
                }
            }
        }
    }

    private func addExercise(_ exercise: Exercise) {
        let newPlannedExercise = PlannedExercise(
            exercise: exercise,
            warmupSets: 2,
            targetRepsMin: 8,
            targetRepsMax: 12,
            restTimeSeconds: 120,
            orderIndex: sessionTemplate.exercises.count
        )

        sessionTemplate.exercises.append(newPlannedExercise)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    ProgramEditorView(
        weekProgram: WeekProgram(weekNumber: 16),
        dataService: DataService()
    )
}
