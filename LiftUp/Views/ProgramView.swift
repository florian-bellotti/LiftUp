import SwiftUI
import SwiftData

/// Vue unifiée du programme - combine la visualisation, le lancement et l'édition des séances
struct ProgramView: View {
    let dataService: DataService
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: WorkoutViewModel

    /// Callback optionnel pour lancer une séance (nil = mode Tab, non-nil = mode sheet)
    let onStartSession: ((SessionTemplate) -> Void)?

    /// Mode d'affichage : true si affiché dans une sheet
    private var isSheet: Bool { onStartSession != nil }

    @State private var isEditing = false
    @State private var editingExercise: PlannedExercise?
    @State private var showingAddExercise = false
    @State private var selectedSession: SessionTemplate?
    @State private var showingSession = false

    init(dataService: DataService, onStartSession: ((SessionTemplate) -> Void)?) {
        self.dataService = dataService
        self.onStartSession = onStartSession
        _viewModel = StateObject(wrappedValue: WorkoutViewModel(dataService: dataService))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header titre
                    headerSection

                    // Header avec progression
                    weekHeader

                    // Liste des séances
                    ForEach(viewModel.currentWeekProgram?.sortedSessions ?? []) { template in
                        sessionSection(template)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(Color.appBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isSheet {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Fermer") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(isEditing ? "OK" : "Modifier") {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isEditing.toggle()
                            }
                        }
                        .fontWeight(isEditing ? .semibold : .regular)
                    }
                }
            }
            .task {
                await viewModel.loadData()
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
            .fullScreenCover(isPresented: $showingSession) {
                if let session = viewModel.activeWorkout {
                    SessionView(session: session, dataService: dataService) {
                        Task {
                            await viewModel.cancelSession(session)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .center) {
            Text("Programme")
                .font(.largeTitle.bold())

            Spacer()

            if !isSheet {
                Button(isEditing ? "OK" : "Modifier") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isEditing.toggle()
                    }
                }
                .font(.body)
                .fontWeight(isEditing ? .semibold : .regular)
                .foregroundStyle(Color.appPrimary)
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Week Header

    private var weekHeader: some View {
        iOS26CardView(cornerRadius: 16, padding: 16) {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Progression")
                            .font(.headline)

                        Text("\(viewModel.sessionsCompletedThisWeek) sur \(viewModel.totalSessionsThisWeek) séances")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    ProgressRingWithContent(
                        progress: Double(viewModel.sessionsCompletedThisWeek) / Double(max(viewModel.totalSessionsThisWeek, 1)),
                        color: .appPrimary,
                        lineWidth: 5,
                        size: 60
                    ) {
                        Text("\(Int((Double(viewModel.sessionsCompletedThisWeek) / Double(max(viewModel.totalSessionsThisWeek, 1))) * 100))%")
                            .font(.caption.bold().monospacedDigit())
                    }
                }

                // Mini calendrier de la semaine
                HStack(spacing: 0) {
                    ForEach(0..<5, id: \.self) { dayIndex in
                        dayCell(dayIndex)
                    }
                }
            }
        }
    }

    private func dayCell(_ dayIndex: Int) -> some View {
        let sessionType = SessionType.forDay(dayIndex)
        let isCompleted = sessionType.map { viewModel.isSessionCompleted($0) } ?? false
        let isToday = dayIndex == currentDayIndex
        let date = viewModel.currentWeekProgram?.date(forDay: dayIndex) ?? Date()

        return VStack(spacing: 6) {
            Text(WeekProgram.shortDayName(forIndex: dayIndex))
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)

            ZStack {
                Circle()
                    .fill(isToday ? Color.appPrimary : (isCompleted ? Color.success.opacity(0.15) : Color.clear))
                    .frame(width: 32, height: 32)

                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(isToday ? .white : .primary)
            }

            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.success)
            } else {
                Color.clear
                    .frame(height: 10)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var currentDayIndex: Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return weekday == 1 ? 6 : weekday - 2
    }

    // MARK: - Session Section

    private func sessionSection(_ template: SessionTemplate) -> some View {
        let color = Color.forSessionType(template.sessionType)
        let isCompleted = viewModel.isSessionCompleted(template.sessionType)
        let isActive = viewModel.activeWorkout?.sessionType == template.sessionType &&
                       !(viewModel.activeWorkout?.isCompleted ?? true)
        let isToday = viewModel.todaySessionType == template.sessionType

        return VStack(alignment: .leading, spacing: 0) {
            // Header de la séance
            HStack(spacing: 12) {
                iOS26IconView(icon: template.sessionType.icon, color: color, size: 36)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(template.sessionType.displayName)
                            .font(.headline)

                        if isCompleted {
                            iOS26Badge(text: "FAIT", color: .success, size: .small)
                        } else if isActive {
                            iOS26Badge(text: "EN COURS", color: .orange, size: .small)
                        } else if isToday {
                            iOS26Badge(text: "AUJOURD'HUI", color: color, size: .small)
                        }
                    }

                    Text("\(WeekProgram.dayName(forIndex: template.dayIndex)) • \(template.exercises.count) exercices")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Bouton de lancement
                Button {
                    if let onStart = onStartSession {
                        onStart(template)
                        dismiss()
                    } else {
                        // Mode Tab : lancer directement
                        Task {
                            if viewModel.hasActiveWorkout {
                                showingSession = true
                            } else if let _ = await viewModel.startSession(from: template) {
                                showingSession = true
                            }
                        }
                    }
                } label: {
                    Image(systemName: isActive ? "play.fill" : "play.circle.fill")
                        .font(.system(size: isActive ? 18 : 28))
                        .foregroundStyle(isActive ? .white : color)
                        .frame(width: 44, height: 44)
                        .background(isActive ? color : color.opacity(0.001))
                        .clipShape(Circle())
                }
                .disabled(viewModel.hasActiveWorkout && !isActive)
                .opacity(viewModel.hasActiveWorkout && !isActive ? 0.4 : 1)
            }
            .padding(16)
            .background(Color.cardSurface)

            // Liste des exercices
            VStack(spacing: 0) {
                ForEach(Array(template.sortedExercises.enumerated()), id: \.element.id) { index, exercise in
                    exerciseRow(exercise, index: index, color: color, session: template)
                        .onDrag {
                            guard isEditing else { return NSItemProvider() }
                            return NSItemProvider(object: exercise.id.uuidString as NSString)
                        }
                        .onDrop(of: [.text], delegate: ExerciseDropDelegate(
                            item: exercise,
                            items: template.sortedExercises,
                            session: template,
                            isEditing: isEditing,
                            onReorder: { reorderExercises(in: template) }
                        ))

                    if index < template.sortedExercises.count - 1 {
                        Divider()
                            .padding(.leading, isEditing ? 68 : 52)
                    }
                }

                // Bouton ajouter exercice (visible uniquement en mode édition)
                if isEditing {
                    Button {
                        selectedSession = template
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
            .background(Color.cardSurface.opacity(0.5))
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.secondary.opacity(0.1), lineWidth: 1)
        )
    }

    private func exerciseRow(_ exercise: PlannedExercise, index: Int, color: Color, session: SessionTemplate) -> some View {
        HStack(spacing: 12) {
            // Drag handle (visible en mode édition)
            if isEditing {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .frame(width: 20)
            }

            // Numéro
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

            if isEditing {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            if isEditing {
                editingExercise = exercise
            }
        }
        .contextMenu(isEditing ? ContextMenu {
            Button(role: .destructive) {
                deleteExercise(exercise, from: session)
            } label: {
                Label("Supprimer", systemImage: "trash")
            }
        } : nil)
    }

    // MARK: - Actions

    private func deleteExercise(_ exercise: PlannedExercise, from session: SessionTemplate) {
        session.exercises.removeAll { $0.id == exercise.id }

        // Reindex remaining exercises
        for (index, ex) in session.sortedExercises.enumerated() {
            ex.orderIndex = index
        }

        // Sauvegarder
        Task {
            if let program = viewModel.currentWeekProgram {
                try? await dataService.workoutRepository.saveWeekProgram(program)
            }
        }
    }

    private func reorderExercises(in session: SessionTemplate) {
        // Mettre à jour les orderIndex après réorganisation
        for (index, exercise) in session.sortedExercises.enumerated() {
            exercise.orderIndex = index
        }

        // Sauvegarder
        Task {
            if let program = viewModel.currentWeekProgram {
                try? await dataService.workoutRepository.saveWeekProgram(program)
            }
        }
    }
}

// MARK: - Drop Delegate pour réorganiser les exercices

struct ExerciseDropDelegate: DropDelegate {
    let item: PlannedExercise
    let items: [PlannedExercise]
    let session: SessionTemplate
    let isEditing: Bool
    let onReorder: () -> Void

    func performDrop(info: DropInfo) -> Bool {
        return true
    }

    func dropEntered(info: DropInfo) {
        guard isEditing else { return }

        guard let draggedItem = info.itemProviders(for: [.text]).first else { return }

        draggedItem.loadObject(ofClass: NSString.self) { reading, _ in
            guard let idString = reading as? String,
                  let draggedId = UUID(uuidString: idString) else { return }

            DispatchQueue.main.async {
                guard let fromIndex = items.firstIndex(where: { $0.id == draggedId }),
                      let toIndex = items.firstIndex(where: { $0.id == item.id }),
                      fromIndex != toIndex else { return }

                withAnimation(.easeInOut(duration: 0.2)) {
                    // Swap orderIndex values
                    let fromOrder = items[fromIndex].orderIndex
                    items[fromIndex].orderIndex = items[toIndex].orderIndex
                    items[toIndex].orderIndex = fromOrder
                }

                onReorder()
            }
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: isEditing ? .move : .cancel)
    }
}

#Preview {
    ProgramView(dataService: DataService(), onStartSession: nil)
}
