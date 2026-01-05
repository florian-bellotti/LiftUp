import Foundation
import SwiftData

/// Protocole définissant les opérations sur les séances
/// Permet de switcher facilement entre stockage local et API
protocol WorkoutRepositoryProtocol {
    // MARK: - Week Programs
    func getCurrentWeekProgram() async throws -> WeekProgram?
    func getWeekProgram(weekNumber: Int) async throws -> WeekProgram?
    func getAllWeekPrograms() async throws -> [WeekProgram]
    func saveWeekProgram(_ program: WeekProgram) async throws
    func deleteWeekProgram(_ program: WeekProgram) async throws

    // MARK: - Workout Sessions
    func getWorkoutSession(id: UUID) async throws -> WorkoutSession?
    func getWorkoutSessions(forWeek weekNumber: Int) async throws -> [WorkoutSession]
    func getWorkoutSessions(forType sessionType: SessionType, limit: Int) async throws -> [WorkoutSession]
    func getAllCompletedSessions() async throws -> [WorkoutSession]
    func getCompletedSessions(forMonth date: Date) async throws -> [WorkoutSession]
    func getPreviousSession(forType sessionType: SessionType, before date: Date) async throws -> WorkoutSession?
    func saveWorkoutSession(_ session: WorkoutSession) async throws
    func deleteWorkoutSession(_ session: WorkoutSession) async throws

    // MARK: - Sync (préparation API future)
    func syncPendingChanges() async throws
    var hasPendingChanges: Bool { get }
}

/// Implémentation locale avec SwiftData
@MainActor
final class LocalWorkoutRepository: WorkoutRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Week Programs

    func getCurrentWeekProgram() async throws -> WeekProgram? {
        let calendar = Calendar.current
        let today = Date()

        // Calculer le lundi de cette semaine
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = weekday == 1 ? 6 : weekday - 2
        guard let mondayThisWeek = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else {
            return nil
        }

        let startOfMonday = calendar.startOfDay(for: mondayThisWeek)
        let endOfSunday = calendar.date(byAdding: .day, value: 7, to: startOfMonday)!

        let descriptor = FetchDescriptor<WeekProgram>(
            predicate: #Predicate<WeekProgram> { program in
                program.startDate >= startOfMonday && program.startDate < endOfSunday && program.isActive
            },
            sortBy: [SortDescriptor(\WeekProgram.weekNumber, order: .reverse)]
        )

        let results = try modelContext.fetch(descriptor)
        return results.first
    }

    func getWeekProgram(weekNumber: Int) async throws -> WeekProgram? {
        let descriptor = FetchDescriptor<WeekProgram>(
            predicate: #Predicate<WeekProgram> { $0.weekNumber == weekNumber }
        )
        return try modelContext.fetch(descriptor).first
    }

    func getAllWeekPrograms() async throws -> [WeekProgram] {
        let descriptor = FetchDescriptor<WeekProgram>(
            sortBy: [SortDescriptor(\WeekProgram.weekNumber, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func saveWeekProgram(_ program: WeekProgram) async throws {
        modelContext.insert(program)
        try modelContext.save()
    }

    func deleteWeekProgram(_ program: WeekProgram) async throws {
        modelContext.delete(program)
        try modelContext.save()
    }

    // MARK: - Workout Sessions

    func getWorkoutSession(id: UUID) async throws -> WorkoutSession? {
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    func getWorkoutSessions(forWeek weekNumber: Int) async throws -> [WorkoutSession] {
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { $0.weekNumber == weekNumber },
            sortBy: [SortDescriptor(\WorkoutSession.startedAt, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }

    func getWorkoutSessions(forType sessionType: SessionType, limit: Int) async throws -> [WorkoutSession] {
        let typeRawValue = sessionType.rawValue
        var descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { session in
                session.sessionTypeRaw == typeRawValue && session.isCompleted
            },
            sortBy: [SortDescriptor(\WorkoutSession.startedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }

    func getAllCompletedSessions() async throws -> [WorkoutSession] {
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { session in
                session.isCompleted
            },
            sortBy: [SortDescriptor(\WorkoutSession.startedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func getCompletedSessions(forMonth date: Date) async throws -> [WorkoutSession] {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!

        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { session in
                session.isCompleted &&
                session.startedAt >= startOfMonth &&
                session.startedAt < endOfMonth
            },
            sortBy: [SortDescriptor(\WorkoutSession.startedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func getPreviousSession(forType sessionType: SessionType, before date: Date) async throws -> WorkoutSession? {
        let typeRawValue = sessionType.rawValue
        var descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { session in
                session.sessionTypeRaw == typeRawValue &&
                session.startedAt < date &&
                session.isCompleted
            },
            sortBy: [SortDescriptor(\WorkoutSession.startedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func saveWorkoutSession(_ session: WorkoutSession) async throws {
        modelContext.insert(session)
        try modelContext.save()
    }

    func deleteWorkoutSession(_ session: WorkoutSession) async throws {
        modelContext.delete(session)
        try modelContext.save()
    }

    // MARK: - Sync

    func syncPendingChanges() async throws {
        // Pour l'instant, pas de sync - sera implémenté avec l'API
        // Cette méthode permettra de pousser les changements locaux vers l'API
    }

    var hasPendingChanges: Bool {
        // Pour l'instant, toujours false - sera implémenté avec l'API
        return false
    }
}

/// Repository pour la future intégration API
@MainActor
final class APIWorkoutRepository: WorkoutRepositoryProtocol {
    private let baseURL: URL
    private let localRepository: LocalWorkoutRepository

    init(baseURL: URL, localRepository: LocalWorkoutRepository) {
        self.baseURL = baseURL
        self.localRepository = localRepository
    }

    // MARK: - Week Programs (délègue au local pour l'instant)

    func getCurrentWeekProgram() async throws -> WeekProgram? {
        // TODO: Implémenter sync avec API
        return try await localRepository.getCurrentWeekProgram()
    }

    func getWeekProgram(weekNumber: Int) async throws -> WeekProgram? {
        return try await localRepository.getWeekProgram(weekNumber: weekNumber)
    }

    func getAllWeekPrograms() async throws -> [WeekProgram] {
        return try await localRepository.getAllWeekPrograms()
    }

    func saveWeekProgram(_ program: WeekProgram) async throws {
        try await localRepository.saveWeekProgram(program)
        // TODO: Queue pour sync API
    }

    func deleteWeekProgram(_ program: WeekProgram) async throws {
        try await localRepository.deleteWeekProgram(program)
    }

    // MARK: - Workout Sessions

    func getWorkoutSession(id: UUID) async throws -> WorkoutSession? {
        return try await localRepository.getWorkoutSession(id: id)
    }

    func getWorkoutSessions(forWeek weekNumber: Int) async throws -> [WorkoutSession] {
        return try await localRepository.getWorkoutSessions(forWeek: weekNumber)
    }

    func getWorkoutSessions(forType sessionType: SessionType, limit: Int) async throws -> [WorkoutSession] {
        return try await localRepository.getWorkoutSessions(forType: sessionType, limit: limit)
    }

    func getAllCompletedSessions() async throws -> [WorkoutSession] {
        return try await localRepository.getAllCompletedSessions()
    }

    func getCompletedSessions(forMonth date: Date) async throws -> [WorkoutSession] {
        return try await localRepository.getCompletedSessions(forMonth: date)
    }

    func getPreviousSession(forType sessionType: SessionType, before date: Date) async throws -> WorkoutSession? {
        return try await localRepository.getPreviousSession(forType: sessionType, before: date)
    }

    func saveWorkoutSession(_ session: WorkoutSession) async throws {
        try await localRepository.saveWorkoutSession(session)
        // TODO: Queue pour sync API
    }

    func deleteWorkoutSession(_ session: WorkoutSession) async throws {
        try await localRepository.deleteWorkoutSession(session)
    }

    // MARK: - Sync

    func syncPendingChanges() async throws {
        // TODO: Implémenter la synchronisation avec l'API
        // 1. Récupérer les changements en attente
        // 2. Les envoyer à l'API
        // 3. Marquer comme synchronisés
    }

    var hasPendingChanges: Bool {
        return localRepository.hasPendingChanges
    }
}
