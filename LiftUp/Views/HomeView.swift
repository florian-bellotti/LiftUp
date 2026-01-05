import SwiftUI

/// Vue d'accueil principale - Style épuré avec header
struct HomeView: View {
    @EnvironmentObject private var dataService: DataService
    @StateObject private var viewModel: WorkoutViewModel

    @State private var activeSession: WorkoutSession?

    init(dataService: DataService) {
        _viewModel = StateObject(wrappedValue: WorkoutViewModel(dataService: dataService))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header avec salutation
                    headerSection

                    // Séance active ou du jour
                    sessionSection

                    // Semaine en cours
                    weekSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(Color.appBackground)
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await viewModel.loadData()
            }
            .task {
                await viewModel.loadData()
            }
            .fullScreenCover(item: $activeSession) { session in
                SessionView(session: session, dataService: dataService) {
                    Task {
                        await viewModel.cancelSession(session)
                    }
                }
            }
        }
        .environmentObject(viewModel)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        Text(greetingText)
            .font(.largeTitle.bold())
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 16)
            .padding(.bottom, 8)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return "Bonjour"
        } else if hour < 18 {
            return "Bon après-midi"
        } else {
            return "Bonsoir"
        }
    }

    // MARK: - Session Section

    private var sessionSection: some View {
        Group {
            if viewModel.hasActiveWorkout {
                activeSessionCard
            } else if let todaySession = viewModel.todaySession {
                todaySessionCard(todaySession)
            } else {
                restDayCard
            }
        }
    }

    // MARK: - Today's Session Card

    private func todaySessionCard(_ template: SessionTemplate) -> some View {
        let color = Color.forSessionType(template.sessionType)

        return Button {
            Task {
                if let session = await viewModel.startSession(from: template) {
                    activeSession = session
                }
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.95), color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: color.opacity(0.3), radius: 20, x: 0, y: 10)

                VStack(spacing: 24) {
                    Image(systemName: template.sessionType.icon)
                        .font(.system(size: 64, weight: .medium))
                        .foregroundStyle(.white.opacity(0.95))

                    VStack(spacing: 6) {
                        Text(template.sessionType.displayName)
                            .font(.title.bold())
                            .foregroundStyle(.white)

                        Text("\(template.exercises.count) exercices")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14))
                        Text("Commencer")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(color)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.white)
                    .clipShape(Capsule())
                }
                .padding(.vertical, 32)
            }
            .frame(height: 260)
        }
        .buttonStyle(.plain)
        .padding(.bottom, 8)
    }

    // MARK: - Active Session Card

    private var activeSessionCard: some View {
        Button {
            activeSession = viewModel.activeWorkout
        } label: {
            iOS26AccentCardView(color: .orange, cornerRadius: 24, padding: 20) {
                HStack(spacing: 16) {
                    if let session = viewModel.activeWorkout {
                        ProgressRingWithContent(
                            progress: session.progress,
                            color: .orange,
                            lineWidth: 5,
                            size: 64
                        ) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(size: 20))
                                .foregroundStyle(.orange)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Séance en cours")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(session.sessionType.displayName)
                                .font(.title3.bold())

                            Text("\(session.completedExercises.count)/\(session.exercises.count) exercices • \(session.durationDisplay)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "play.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 52, height: 52)
                            .background(Color.orange)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Rest Day Card

    private var restDayCard: some View {
        iOS26CardView(cornerRadius: 24, padding: 40) {
            VStack(spacing: 24) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple.opacity(0.6), .blue.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(spacing: 8) {
                    Text("Jour de repos")
                        .font(.title2.weight(.semibold))

                    Text("Récupère bien, tu l'as mérité")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Week Section

    private var weekSection: some View {
        iOS26CardView(cornerRadius: 20, padding: 20) {
            VStack(spacing: 20) {
                // Header avec progression
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Semaine \(viewModel.currentWeekNumber)")
                            .font(.headline)

                        Text("\(viewModel.sessionsCompletedThisWeek) sur \(viewModel.totalSessionsThisWeek) séances")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if viewModel.sessionsCompletedThisWeek == viewModel.totalSessionsThisWeek && viewModel.totalSessionsThisWeek > 0 {
                        iOS26Badge(text: "COMPLET", color: .success, size: .small)
                    } else {
                        Text("\(Int((Double(viewModel.sessionsCompletedThisWeek) / Double(max(viewModel.totalSessionsThisWeek, 1))) * 100))%")
                            .font(.title2.weight(.bold).monospacedDigit())
                            .foregroundStyle(Color.appPrimary)
                    }
                }

                // Barre de progression
                ProgressBar(
                    progress: Double(viewModel.sessionsCompletedThisWeek) / Double(max(viewModel.totalSessionsThisWeek, 1)),
                    color: .appPrimary,
                    height: 8
                )

                // Indicateurs de séance
                HStack(spacing: 0) {
                    ForEach(SessionType.allCases) { type in
                        sessionDayIndicator(type)
                    }
                }
            }
        }
    }

    private func sessionDayIndicator(_ type: SessionType) -> some View {
        let isCompleted = viewModel.isSessionCompleted(type)
        let isToday = viewModel.todaySessionType == type
        let color = Color.forSessionType(type)

        return VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isCompleted ? color : color.opacity(0.12))
                    .frame(width: 44, height: 44)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Image(systemName: type.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(isToday ? color : .secondary)
                }
            }
            .overlay {
                if isToday && !isCompleted {
                    Circle()
                        .stroke(color, lineWidth: 2.5)
                        .frame(width: 52, height: 52)
                }
            }

            Text(type.shortName)
                .font(.caption2.weight(.medium))
                .foregroundStyle(isToday ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    HomeView(dataService: DataService())
        .environmentObject(DataService())
}
