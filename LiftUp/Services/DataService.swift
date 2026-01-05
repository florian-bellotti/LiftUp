import Foundation
import SwiftData

/// Service principal pour la gestion des données
@MainActor
final class DataService: ObservableObject {
    let modelContainer: ModelContainer
    let modelContext: ModelContext

    private(set) var workoutRepository: LocalWorkoutRepository
    private(set) var exerciseRepository: LocalExerciseRepository

    @Published var isLoading = false
    @Published var error: Error?

    init() {
        do {
            let schema = Schema([
                Exercise.self,
                PlannedExercise.self,
                ExerciseSet.self,
                SessionExercise.self,
                WorkoutSession.self,
                SessionTemplate.self,
                WeekProgram.self
            ])

            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )

            self.modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )

            self.modelContext = modelContainer.mainContext

            self.workoutRepository = LocalWorkoutRepository(modelContext: modelContext)
            self.exerciseRepository = LocalExerciseRepository(modelContext: modelContext)

        } catch {
            fatalError("Impossible de créer le ModelContainer: \(error)")
        }
    }

    /// Initialise les données par défaut si nécessaire
    func initializeIfNeeded() async {
        do {
            let exercises = try await exerciseRepository.getAllExercises()
            if exercises.isEmpty {
                await seedDefaultData()
            }
        } catch {
            self.error = error
        }
    }

    /// Charge les données initiales
    private func seedDefaultData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Créer les exercices par défaut
            let exercises = SeedData.createDefaultExercises()
            for exercise in exercises {
                modelContext.insert(exercise)
            }
            try modelContext.save()

            // Récupérer les exercices persistés pour garantir qu'ils sont bien dans le contexte
            let persistedExercises = try await exerciseRepository.getAllExercises()

            // Créer le programme de la semaine avec les exercices persistés
            let weekProgram = SeedData.createWeek16Program(with: persistedExercises, modelContext: modelContext)
            modelContext.insert(weekProgram)
            try modelContext.save()

            // Créer les séances complétées de la semaine 15 (données précédentes)
            let completedSessions = SeedData.createWeek16CompletedSessions(
                exercises: persistedExercises,
                weekProgram: weekProgram,
                modelContext: modelContext
            )
            for session in completedSessions {
                modelContext.insert(session)
            }
            try modelContext.save()

        } catch {
            self.error = error
        }
    }

    /// Réinitialise toutes les données
    func resetAllData() async {
        do {
            // Supprimer toutes les données
            try modelContext.delete(model: WorkoutSession.self)
            try modelContext.delete(model: WeekProgram.self)
            try modelContext.delete(model: Exercise.self)
            try modelContext.save()

            // Recharger les données par défaut
            await seedDefaultData()
        } catch {
            self.error = error
        }
    }
}
