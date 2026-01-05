import SwiftUI

/// Vue de l'historique des séances
struct HistoryView: View {
    let dataService: DataService
    @Environment(\.dismiss) private var dismiss

    @State private var sessions: [WorkoutSession] = []
    @State private var selectedMonth: Date = Date()
    @State private var selectedSession: WorkoutSession?
    @State private var isLoading = true
    @State private var sessionToDelete: WorkoutSession?
    @State private var showDeleteConfirmation = false

    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header titre
                    headerSection

                    // Calendrier mensuel
                    calendarSection

                    // Liste des séances du mois
                    sessionsListSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(Color.appBackground)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadSessions()
            }
            .onChange(of: selectedMonth) { _, _ in
                Task {
                    await loadSessions()
                }
            }
            .sheet(item: $selectedSession) { session in
                SessionDetailView(session: session, dataService: dataService) {
                    // Callback après suppression depuis le détail
                    Task {
                        await loadSessions()
                    }
                }
            }
            .alert("Supprimer la séance ?", isPresented: $showDeleteConfirmation) {
                Button("Annuler", role: .cancel) {
                    sessionToDelete = nil
                }
                Button("Supprimer", role: .destructive) {
                    if let session = sessionToDelete {
                        Task {
                            await deleteSession(session)
                        }
                    }
                }
            } message: {
                if let session = sessionToDelete {
                    Text("La séance \(session.sessionType.displayName) du \(formatDeleteDate(session.startedAt)) sera définitivement supprimée.")
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        Text("Historique")
            .font(.largeTitle.bold())
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 16)
    }

    // MARK: - Calendar Section

    private var calendarSection: some View {
        VStack(spacing: 16) {
            // Navigation mois
            HStack {
                Button {
                    withAnimation {
                        selectedMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 36, height: 36)
                        .background(Color.cardSurface)
                        .clipShape(Circle())
                }

                Spacer()

                Text(monthYearString)
                    .font(.headline)

                Spacer()

                Button {
                    withAnimation {
                        selectedMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 36, height: 36)
                        .background(Color.cardSurface)
                        .clipShape(Circle())
                }
                .disabled(isCurrentMonth)
                .opacity(isCurrentMonth ? 0.3 : 1)
            }

            // Grille du calendrier
            iOS26CardView(cornerRadius: 16, padding: 16) {
                VStack(spacing: 12) {
                    // Jours de la semaine
                    HStack(spacing: 0) {
                        ForEach(["L", "M", "M", "J", "V", "S", "D"], id: \.self) { day in
                            Text(day)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }

                    // Grille des jours
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
                        ForEach(daysInMonth, id: \.self) { date in
                            if let date = date {
                                dayCell(date)
                            } else {
                                Color.clear
                                    .frame(height: 36)
                            }
                        }
                    }
                }
            }

            // Légende
            HStack(spacing: 12) {
                ForEach(SessionType.allCases) { type in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.forSessionType(type))
                            .frame(width: 8, height: 8)
                        Text(type.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func dayCell(_ date: Date) -> some View {
        let sessionsOnDay = sessionsForDate(date)
        let isToday = calendar.isDateInToday(date)
        let dayNumber = calendar.component(.day, from: date)

        return VStack(spacing: 2) {
            ZStack {
                if isToday {
                    Circle()
                        .fill(Color.appPrimary)
                        .frame(width: 28, height: 28)
                }

                Text("\(dayNumber)")
                    .font(.subheadline.weight(isToday ? .bold : .regular).monospacedDigit())
                    .foregroundStyle(isToday ? .white : .primary)
            }
            .frame(height: 28)

            // Indicateurs de séances
            HStack(spacing: 2) {
                ForEach(sessionsOnDay.prefix(3), id: \.id) { session in
                    Circle()
                        .fill(Color.forSessionType(session.sessionType))
                        .frame(width: 5, height: 5)
                }
            }
            .frame(height: 8)
        }
        .frame(height: 40)
        .contentShape(Rectangle())
        .onTapGesture {
            if let firstSession = sessionsOnDay.first {
                selectedSession = firstSession
            }
        }
    }

    // MARK: - Sessions List Section

    private var sessionsListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Séances")
                    .iOS26SectionTitle()

                Spacer()

                Text("\(sessions.count) séance\(sessions.count > 1 ? "s" : "")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else if sessions.isEmpty {
                emptyStateView
            } else {
                // Grouper par jour
                ForEach(groupedSessions.keys.sorted().reversed(), id: \.self) { date in
                    if let daySessions = groupedSessions[date] {
                        daySessionsGroup(date: date, sessions: daySessions)
                    }
                }
            }
        }
    }

    private func daySessionsGroup(date: Date, sessions: [WorkoutSession]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(dayHeaderString(date))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            VStack(spacing: 8) {
                ForEach(sessions) { session in
                    sessionCard(session)
                }
            }
        }
    }

    private func sessionCard(_ session: WorkoutSession) -> some View {
        let color = Color.forSessionType(session.sessionType)

        return Button {
            selectedSession = session
        } label: {
            iOS26CardView(cornerRadius: 12, padding: 0) {
                HStack(spacing: 12) {
                    // Icône
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(color.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: session.sessionType.icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(color)
                    }

                    // Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.sessionType.displayName)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)

                        HStack(spacing: 8) {
                            Label(session.durationDisplay, systemImage: "clock")
                            Label("\(session.totalSets) séries", systemImage: "flame")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Heure
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(timeString(session.startedAt))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)

                        if session.exercises.count > 0 {
                            Text("\(session.exercises.count) exos")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(12)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                sessionToDelete = session
                showDeleteConfirmation = true
            } label: {
                Label("Supprimer", systemImage: "trash")
            }
        }
    }

    private var emptyStateView: some View {
        iOS26CardView(cornerRadius: 16, padding: 32) {
            VStack(spacing: 12) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)

                Text("Aucune séance")
                    .font(.headline)

                Text("Tu n'as pas encore fait de séance ce mois-ci")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Helpers

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: selectedMonth).capitalized
    }

    private var isCurrentMonth: Bool {
        calendar.isDate(selectedMonth, equalTo: Date(), toGranularity: .month)
    }

    private var daysInMonth: [Date?] {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth))!
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!

        // Premier jour de la semaine (1 = dimanche, 2 = lundi, etc.)
        var weekday = calendar.component(.weekday, from: startOfMonth)
        // Convertir pour que lundi = 0
        weekday = weekday == 1 ? 6 : weekday - 2

        var days: [Date?] = Array(repeating: nil, count: weekday)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }

        return days
    }

    private func sessionsForDate(_ date: Date) -> [WorkoutSession] {
        sessions.filter { calendar.isDate($0.startedAt, inSameDayAs: date) }
    }

    private var groupedSessions: [Date: [WorkoutSession]] {
        Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.startedAt)
        }
    }

    private func dayHeaderString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")

        if calendar.isDateInToday(date) {
            return "Aujourd'hui"
        } else if calendar.isDateInYesterday(date) {
            return "Hier"
        } else {
            formatter.dateFormat = "EEEE d MMMM"
            return formatter.string(from: date).capitalized
        }
    }

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    // MARK: - Data Loading

    private func loadSessions() async {
        isLoading = true
        do {
            sessions = try await dataService.workoutRepository.getCompletedSessions(forMonth: selectedMonth)
        } catch {
            print("Error loading sessions: \(error)")
            sessions = []
        }
        isLoading = false
    }

    // MARK: - Delete

    private func deleteSession(_ session: WorkoutSession) async {
        do {
            try await dataService.workoutRepository.deleteWorkoutSession(session)
            // Retirer de la liste locale
            sessions.removeAll { $0.id == session.id }
            sessionToDelete = nil
        } catch {
            print("Error deleting session: \(error)")
        }
    }

    private func formatDeleteDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }
}

// MARK: - Session Detail View

struct SessionDetailView: View {
    let session: WorkoutSession
    let dataService: DataService
    var onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    sessionHeader

                    // Stats
                    statsSection

                    // Exercices
                    exercisesSection

                    // Bouton supprimer
                    deleteButton
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color.appBackground)
            .navigationTitle(session.sessionType.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
            .alert("Supprimer la séance ?", isPresented: $showDeleteConfirmation) {
                Button("Annuler", role: .cancel) { }
                Button("Supprimer", role: .destructive) {
                    Task {
                        await deleteSession()
                    }
                }
            } message: {
                Text("Cette action est irréversible. Toutes les données de cette séance seront perdues.")
            }
        }
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Supprimer cette séance")
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(.top, 20)
    }

    private func deleteSession() async {
        do {
            try await dataService.workoutRepository.deleteWorkoutSession(session)
            onDelete?()
            dismiss()
        } catch {
            print("Error deleting session: \(error)")
        }
    }

    private var sessionHeader: some View {
        let color = Color.forSessionType(session.sessionType)

        return iOS26CardView(cornerRadius: 16, padding: 20) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 72, height: 72)

                    Image(systemName: session.sessionType.icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(color)
                }

                VStack(spacing: 4) {
                    Text(dateString)
                        .font(.headline)

                    Text("Semaine \(session.weekNumber)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var statsSection: some View {
        iOS26CardView(cornerRadius: 16, padding: 16) {
            HStack(spacing: 0) {
                statItem(icon: "clock", value: session.durationDisplay, label: "Durée")

                Divider().frame(height: 40)

                statItem(icon: "flame", value: "\(session.totalSets)", label: "Séries")

                Divider().frame(height: 40)

                statItem(icon: "dumbbell", value: "\(session.exercises.count)", label: "Exercices")
            }
        }
    }

    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exercices")
                .iOS26SectionTitle()
                .padding(.horizontal, 4)

            iOS26CardView(cornerRadius: 12, padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(session.sortedExercises.enumerated()), id: \.element.id) { index, exercise in
                        exerciseRow(exercise, index: index)

                        if index < session.exercises.count - 1 {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
            }
        }
    }

    private func exerciseRow(_ exercise: SessionExercise, index: Int) -> some View {
        let color = Color.forSessionType(session.sessionType)

        return HStack(spacing: 12) {
            Text("\(index + 1)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(color)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.plannedExercise?.exercise?.name ?? "Exercice")
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                if !exercise.completedSets.isEmpty {
                    Text(exercise.completedSets.map { $0.displayFormat }.joined(separator: " • "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            if exercise.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.success)
            } else if exercise.isSkipped {
                Image(systemName: "forward.fill")
                    .foregroundStyle(Color.warning)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE d MMMM yyyy"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: session.startedAt).capitalized
    }
}

// MARK: - SessionType Extension

extension SessionType {
    var shortName: String {
        switch self {
        case .upper: return "Up"
        case .lower: return "Lo"
        case .push: return "Pu"
        case .pull: return "Pl"
        case .legs: return "Le"
        }
    }
}

#Preview {
    HistoryView(dataService: DataService())
}
