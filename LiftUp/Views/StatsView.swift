import SwiftUI
import Charts

/// Vue de progression par exercice
struct StatsView: View {
    let dataService: DataService
    @Environment(\.dismiss) private var dismiss

    @State private var selectedSessionType: SessionType = .upper
    @State private var allSessions: [WorkoutSession] = []
    @State private var isLoading = true
    @State private var selectedExercise: ExerciseProgression?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header titre
                    headerSection
                        .padding(.horizontal, 20)

                    // Tabs par type de séance
                    sessionTypePicker
                        .padding(.horizontal, 20)

                    if isLoading {
                        Spacer()
                            .frame(height: 100)
                        ProgressView()
                        Spacer()
                            .frame(height: 100)
                    } else if exerciseProgressions.isEmpty {
                        emptyStateView
                            .padding(.top, 40)
                    } else {
                        // Liste des exercices
                        LazyVStack(spacing: 12) {
                            ForEach(exerciseProgressions) { progression in
                                exerciseCard(progression)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .background(Color.appBackground)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadData()
            }
            .sheet(item: $selectedExercise) { progression in
                ExerciseDetailView(progression: progression, sessions: sessionsForSelectedType)
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        Text("Progression")
            .font(.largeTitle.bold())
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 16)
    }

    // MARK: - Session Type Picker

    private var sessionTypePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SessionType.allCases) { type in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedSessionType = type
                        }
                    } label: {
                        Text(type.displayName)
                            .font(.subheadline.weight(selectedSessionType == type ? .semibold : .regular))
                            .foregroundStyle(selectedSessionType == type ? .white : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedSessionType == type ? Color.appPrimary : Color.cardSurface)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Exercise Card

    private func exerciseCard(_ progression: ExerciseProgression) -> some View {
        Button {
            selectedExercise = progression
        } label: {
            iOS26CardView(cornerRadius: 16, padding: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack {
                        Text(progression.exerciseName)
                            .font(.headline)

                        Spacer()

                        if progression.isReadyToIncrease {
                            Text("Prêt à monter")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.success)
                                .clipShape(Capsule())
                        }
                    }

                    // Dernière perf
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(progression.lastWeightFormatted)
                            .font(.title2.weight(.bold).monospacedDigit())

                        Text("×")
                            .font(.title3)
                            .foregroundStyle(.secondary)

                        Text(progression.lastRepsFormatted)
                            .font(.title2.weight(.bold).monospacedDigit())

                        Text("reps")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text("objectif: \(progression.targetRepsMin)-\(progression.targetRepsMax)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    // Barre de progression vers objectif
                    repsProgressBar(progression)

                    // Evolution sur 1, 3, 6 mois
                    HStack(spacing: 0) {
                        evolutionBadge(label: "1 mois", change: progression.change1Month)
                        evolutionBadge(label: "3 mois", change: progression.change3Months)
                        evolutionBadge(label: "6 mois", change: progression.change6Months)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func repsProgressBar(_ progression: ExerciseProgression) -> some View {
        let progress = min(Double(progression.lastReps) / Double(progression.targetRepsMax), 1.5)
        let overTarget = progression.lastReps > progression.targetRepsMax

        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.15))
                    .frame(height: 6)

                // Progress
                RoundedRectangle(cornerRadius: 4)
                    .fill(overTarget ? Color.success : Color.appPrimary)
                    .frame(width: geo.size.width * min(progress, 1.0), height: 6)

                // Objectif min marker
                let minPosition = Double(progression.targetRepsMin) / Double(progression.targetRepsMax)
                Rectangle()
                    .fill(Color.secondary.opacity(0.4))
                    .frame(width: 2, height: 10)
                    .offset(x: geo.size.width * minPosition - 1)
            }
        }
        .frame(height: 10)
    }

    private func evolutionBadge(label: String, change: Double?) -> some View {
        VStack(spacing: 2) {
            if let change = change {
                HStack(spacing: 2) {
                    Image(systemName: change > 0 ? "arrow.up.right" : (change < 0 ? "arrow.down.right" : "arrow.right"))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(change > 0 ? Color.success : (change < 0 ? Color.warning : Color.secondary))

                    Text(change > 0 ? "+\(String(format: "%.1f", change))kg" : (change == 0 ? "=" : "\(String(format: "%.1f", change))kg"))
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(change > 0 ? Color.success : (change < 0 ? Color.warning : Color.secondary))
                }
            } else {
                Text("-")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("Pas encore de données")
                .font(.headline)

            Text("Complète des séances \(selectedSessionType.displayName) pour voir ta progression")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }

    // MARK: - Data

    private var sessionsForSelectedType: [WorkoutSession] {
        allSessions
            .filter { $0.sessionType == selectedSessionType }
            .sorted { $0.startedAt > $1.startedAt }
    }

    private var exerciseProgressions: [ExerciseProgression] {
        let sessions = sessionsForSelectedType
        guard !sessions.isEmpty else { return [] }

        // Récupérer tous les exercices uniques
        var exerciseData: [UUID: ExerciseProgression] = [:]

        for session in sessions {
            for exercise in session.exercises {
                guard let plannedExercise = exercise.plannedExercise,
                      let exerciseInfo = plannedExercise.exercise else { continue }

                let workingSets = exercise.sets.filter { $0.isCompleted && !$0.isWarmup }
                guard !workingSets.isEmpty else { continue }

                // Calculer moyenne poids et reps
                let avgWeight = workingSets.map { $0.weight }.reduce(0, +) / Double(workingSets.count)
                let avgReps = Double(workingSets.map { $0.reps }.reduce(0, +)) / Double(workingSets.count)

                let perfData = PerformanceData(
                    date: session.startedAt,
                    avgWeight: avgWeight,
                    avgReps: avgReps
                )

                if var existing = exerciseData[exerciseInfo.id] {
                    existing.performances.append(perfData)
                    exerciseData[exerciseInfo.id] = existing
                } else {
                    exerciseData[exerciseInfo.id] = ExerciseProgression(
                        exerciseId: exerciseInfo.id,
                        exerciseName: exerciseInfo.name,
                        targetRepsMin: plannedExercise.targetRepsMin,
                        targetRepsMax: plannedExercise.targetRepsMax,
                        performances: [perfData]
                    )
                }
            }
        }

        return exerciseData.values
            .map { progression in
                var p = progression
                p.performances.sort { $0.date > $1.date }
                return p
            }
            .sorted { $0.exerciseName < $1.exerciseName }
    }

    private func loadData() async {
        isLoading = true
        do {
            allSessions = try await dataService.workoutRepository.getAllCompletedSessions()
        } catch {
            print("Error loading sessions: \(error)")
            allSessions = []
        }
        isLoading = false
    }
}

// MARK: - Exercise Detail View

struct ExerciseDetailView: View {
    let progression: ExerciseProgression
    let sessions: [WorkoutSession]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header résumé
                    headerSection

                    // Graphique d'évolution
                    if chartData.count >= 2 {
                        chartSection
                    }

                    // Historique
                    historySection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color.appBackground)
            .navigationTitle(progression.exerciseName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Chart Data

    private var chartData: [PerformanceData] {
        // Inverser pour avoir les plus anciennes en premier (ordre chronologique)
        Array(progression.performances.prefix(20).reversed())
    }

    // MARK: - Chart Section

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Évolution")
                .iOS26SectionTitle()
                .padding(.horizontal, 4)

            iOS26CardView(cornerRadius: 16, padding: 16) {
                VStack(alignment: .leading, spacing: 16) {
                    // Graphique du poids
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Poids (kg)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Chart(chartData) { perf in
                            LineMark(
                                x: .value("Date", perf.date),
                                y: .value("Poids", perf.avgWeight)
                            )
                            .foregroundStyle(Color.appPrimary)
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Date", perf.date),
                                y: .value("Poids", perf.avgWeight)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.appPrimary.opacity(0.3), Color.appPrimary.opacity(0.05)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)

                            PointMark(
                                x: .value("Date", perf.date),
                                y: .value("Poids", perf.avgWeight)
                            )
                            .foregroundStyle(Color.appPrimary)
                            .symbolSize(30)
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .month)) { value in
                                AxisValueLabel(format: .dateTime.month(.abbreviated))
                                    .foregroundStyle(Color.secondary)
                                AxisGridLine()
                                    .foregroundStyle(Color.secondary.opacity(0.2))
                            }
                        }
                        .chartYAxis {
                            AxisMarks { value in
                                AxisValueLabel()
                                    .foregroundStyle(Color.secondary)
                                AxisGridLine()
                                    .foregroundStyle(Color.secondary.opacity(0.2))
                            }
                        }
                        .chartYScale(domain: weightChartDomain)
                        .frame(height: 180)
                    }

                    Divider()

                    // Graphique des reps
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Répétitions")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Spacer()

                            // Légende objectif
                            HStack(spacing: 4) {
                                Rectangle()
                                    .fill(Color.success.opacity(0.3))
                                    .frame(width: 12, height: 8)
                                    .cornerRadius(2)
                                Text("Objectif: \(progression.targetRepsMin)-\(progression.targetRepsMax)")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }

                        Chart(chartData) { perf in
                            // Zone objectif
                            RectangleMark(
                                xStart: .value("Start", chartData.first?.date ?? Date()),
                                xEnd: .value("End", chartData.last?.date ?? Date()),
                                yStart: .value("Min", progression.targetRepsMin),
                                yEnd: .value("Max", progression.targetRepsMax)
                            )
                            .foregroundStyle(Color.success.opacity(0.15))

                            LineMark(
                                x: .value("Date", perf.date),
                                y: .value("Reps", perf.avgReps)
                            )
                            .foregroundStyle(Color.sessionLower)
                            .interpolationMethod(.catmullRom)

                            PointMark(
                                x: .value("Date", perf.date),
                                y: .value("Reps", perf.avgReps)
                            )
                            .foregroundStyle(Color.sessionLower)
                            .symbolSize(30)
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .month)) { value in
                                AxisValueLabel(format: .dateTime.month(.abbreviated))
                                    .foregroundStyle(Color.secondary)
                                AxisGridLine()
                                    .foregroundStyle(Color.secondary.opacity(0.2))
                            }
                        }
                        .chartYAxis {
                            AxisMarks { value in
                                AxisValueLabel()
                                    .foregroundStyle(Color.secondary)
                                AxisGridLine()
                                    .foregroundStyle(Color.secondary.opacity(0.2))
                            }
                        }
                        .chartYScale(domain: repsChartDomain)
                        .frame(height: 120)
                    }
                }
            }
        }
    }

    private var weightChartDomain: ClosedRange<Double> {
        let weights = chartData.map { $0.avgWeight }
        let minWeight = (weights.min() ?? 0) - 2.5
        let maxWeight = (weights.max() ?? 0) + 2.5
        return max(0, minWeight)...maxWeight
    }

    private var repsChartDomain: ClosedRange<Double> {
        let reps = chartData.map { $0.avgReps }
        let minReps = min((reps.min() ?? 0) - 2, Double(progression.targetRepsMin) - 2)
        let maxReps = max((reps.max() ?? 0) + 2, Double(progression.targetRepsMax) + 2)
        return max(0, minReps)...maxReps
    }

    private var headerSection: some View {
        iOS26CardView(cornerRadius: 16, padding: 20) {
            VStack(spacing: 16) {
                // Dernière perf
                VStack(spacing: 4) {
                    Text("Dernière performance")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(progression.lastWeightFormatted)
                            .font(.largeTitle.weight(.bold).monospacedDigit())

                        Text("kg ×")
                            .font(.title3)
                            .foregroundStyle(.secondary)

                        Text(progression.lastRepsFormatted)
                            .font(.largeTitle.weight(.bold).monospacedDigit())

                        Text("reps")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                // Evolution
                HStack(spacing: 0) {
                    evolutionStat(label: "1 mois", change: progression.change1Month)
                    evolutionStat(label: "3 mois", change: progression.change3Months)
                    evolutionStat(label: "6 mois", change: progression.change6Months)
                }
            }
        }
    }

    private func evolutionStat(label: String, change: Double?) -> some View {
        VStack(spacing: 4) {
            if let change = change {
                Text(change > 0 ? "+\(String(format: "%.1f", change))kg" : (change == 0 ? "=" : "\(String(format: "%.1f", change))kg"))
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(change > 0 ? Color.success : (change < 0 ? Color.warning : Color.secondary))
            } else {
                Text("-")
                    .font(.headline)
                    .foregroundStyle(.tertiary)
            }

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Historique")
                .iOS26SectionTitle()
                .padding(.horizontal, 4)

            iOS26CardView(cornerRadius: 16, padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(progression.performances.prefix(20).enumerated()), id: \.element.date) { index, perf in
                        historyRow(perf, isFirst: index == 0)

                        if index < min(progression.performances.count, 20) - 1 {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
            }
        }
    }

    private func historyRow(_ perf: PerformanceData, isFirst: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(perf.dateFormatted)
                    .font(.subheadline.weight(isFirst ? .semibold : .regular))

                Text(perf.relativeDate)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Text("\(String(format: "%.1f", perf.avgWeight))kg × \(String(format: "%.0f", perf.avgReps))")
                .font(.subheadline.weight(.medium).monospacedDigit())
                .foregroundStyle(isFirst ? Color.appPrimary : .primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Data Models

struct ExerciseProgression: Identifiable {
    let id = UUID()
    let exerciseId: UUID
    let exerciseName: String
    let targetRepsMin: Int
    let targetRepsMax: Int
    var performances: [PerformanceData]

    var lastPerformance: PerformanceData? {
        performances.first
    }

    var lastWeight: Double {
        lastPerformance?.avgWeight ?? 0
    }

    var lastReps: Int {
        Int(lastPerformance?.avgReps ?? 0)
    }

    var lastWeightFormatted: String {
        String(format: "%.1f", lastWeight)
    }

    var lastRepsFormatted: String {
        "\(lastReps)"
    }

    var isReadyToIncrease: Bool {
        lastReps > targetRepsMax
    }

    var change1Month: Double? {
        calculateChange(months: 1)
    }

    var change3Months: Double? {
        calculateChange(months: 3)
    }

    var change6Months: Double? {
        calculateChange(months: 6)
    }

    private func calculateChange(months: Int) -> Double? {
        guard let current = performances.first else { return nil }

        let targetDate = Calendar.current.date(byAdding: .month, value: -months, to: Date())!

        // Trouver la perf la plus proche de cette date
        let pastPerf = performances.first { $0.date <= targetDate }

        guard let past = pastPerf else { return nil }

        return current.avgWeight - past.avgWeight
    }
}

struct PerformanceData: Identifiable {
    let id = UUID()
    let date: Date
    let avgWeight: Double
    let avgReps: Double

    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }

    var relativeDate: String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            return "Aujourd'hui"
        } else if calendar.isDateInYesterday(date) {
            return "Hier"
        } else {
            let days = calendar.dateComponents([.day], from: date, to: now).day ?? 0
            if days < 7 {
                return "Il y a \(days) jours"
            } else if days < 30 {
                let weeks = days / 7
                return "Il y a \(weeks) sem."
            } else {
                let months = days / 30
                return "Il y a \(months) mois"
            }
        }
    }
}

#Preview {
    StatsView(dataService: DataService())
}
