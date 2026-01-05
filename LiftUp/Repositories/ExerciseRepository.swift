import Foundation
import SwiftData

/// Protocole pour la gestion des exercices
protocol ExerciseRepositoryProtocol {
    func getAllExercises() async throws -> [Exercise]
    func getExercise(id: UUID) async throws -> Exercise?
    func searchExercises(query: String) async throws -> [Exercise]
    func getExercises(forMuscleGroup muscleGroup: MuscleGroup) async throws -> [Exercise]
    func saveExercise(_ exercise: Exercise) async throws
    func deleteExercise(_ exercise: Exercise) async throws
}

/// Implémentation locale avec SwiftData
@MainActor
final class LocalExerciseRepository: ExerciseRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func getAllExercises() async throws -> [Exercise] {
        let descriptor = FetchDescriptor<Exercise>(
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }

    func getExercise(id: UUID) async throws -> Exercise? {
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate<Exercise> { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    func searchExercises(query: String) async throws -> [Exercise] {
        let lowercaseQuery = query.lowercased()
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate<Exercise> { exercise in
                exercise.name.localizedStandardContains(lowercaseQuery)
            },
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }

    func getExercises(forMuscleGroup muscleGroup: MuscleGroup) async throws -> [Exercise] {
        // SwiftData ne supporte pas bien les predicates sur les arrays
        // On filtre côté client
        let allExercises = try await getAllExercises()
        return allExercises.filter { $0.muscleGroups.contains(muscleGroup) }
    }

    func saveExercise(_ exercise: Exercise) async throws {
        modelContext.insert(exercise)
        try modelContext.save()
    }

    func deleteExercise(_ exercise: Exercise) async throws {
        // Ne pas permettre la suppression des exercices non-custom
        guard exercise.isCustom else {
            throw ExerciseRepositoryError.cannotDeleteBuiltInExercise
        }
        modelContext.delete(exercise)
        try modelContext.save()
    }
}

enum ExerciseRepositoryError: LocalizedError {
    case cannotDeleteBuiltInExercise

    var errorDescription: String? {
        switch self {
        case .cannotDeleteBuiltInExercise:
            return "Impossible de supprimer un exercice intégré"
        }
    }
}
