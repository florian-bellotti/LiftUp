import Foundation
import SwiftData

/// Données initiales pour l'application
enum SeedData {

    // MARK: - Default Exercises

    static func createDefaultExercises() -> [Exercise] {
        return [
            // UPPER
            Exercise(
                name: "Wide-Grip Pull-up",
                imageName: "pullup_wide",
                muscleGroups: [.lats, .biceps, .rearDelts],
                description: "Traction prise large pour cibler le grand dorsal"
            ),
            Exercise(
                name: "45 Incline Barbell Press",
                imageName: "incline_press",
                muscleGroups: [.chest, .shoulders, .triceps],
                description: "Développé incliné à 45° pour le haut des pectoraux"
            ),
            Exercise(
                name: "Cable Crossover Ladder",
                imageName: "cable_crossover",
                muscleGroups: [.chest],
                description: "Écartés à la poulie en séries pyramidales"
            ),
            Exercise(
                name: "High-Cable Lateral Raise",
                imageName: "cable_lateral",
                muscleGroups: [.shoulders],
                description: "Élévations latérales à la poulie haute"
            ),
            Exercise(
                name: "Overhead Cable Triceps Extension (Bar)",
                imageName: "overhead_triceps",
                muscleGroups: [.triceps],
                description: "Extension triceps à la poulie haute avec barre"
            ),
            Exercise(
                name: "Bayesian Cable Curl",
                imageName: "bayesian_curl",
                muscleGroups: [.biceps],
                description: "Curl biceps à la poulie, bras en arrière du corps"
            ),
            Exercise(
                name: "Pendlay Deficit Row",
                imageName: "pendlay_row",
                muscleGroups: [.back, .lats, .rearDelts],
                description: "Rowing Pendlay avec déficit pour plus d'amplitude"
            ),

            // LOWER
            Exercise(
                name: "Seated Leg Curl",
                imageName: "seated_leg_curl",
                muscleGroups: [.hamstrings],
                description: "Leg curl assis pour les ischio-jambiers"
            ),
            Exercise(
                name: "Leg Extension",
                imageName: "leg_extension",
                muscleGroups: [.quadriceps],
                description: "Extension de jambes pour les quadriceps"
            ),
            Exercise(
                name: "Squat",
                imageName: "squat",
                muscleGroups: [.quadriceps, .glutes, .hamstrings],
                description: "Squat barre sur le dos"
            ),
            Exercise(
                name: "Standing Calf Raise",
                imageName: "calf_raise",
                muscleGroups: [.calves],
                description: "Mollets debout à la machine"
            ),
            Exercise(
                name: "Barbell RDL",
                imageName: "rdl",
                muscleGroups: [.hamstrings, .glutes, .back],
                description: "Romanian Deadlift à la barre"
            ),
            Exercise(
                name: "Abdo roue",
                imageName: "ab_wheel",
                muscleGroups: [.core],
                description: "Roulette abdominale"
            ),

            // PULL
            Exercise(
                name: "Neutral-Grip Lat Pulldown",
                imageName: "lat_pulldown",
                muscleGroups: [.lats, .biceps],
                description: "Tirage vertical prise neutre"
            ),
            Exercise(
                name: "Tirage horizontal cable",
                imageName: "cable_row",
                muscleGroups: [.back, .lats, .rearDelts],
                description: "Rowing assis à la poulie basse"
            ),
            Exercise(
                name: "1-Arm 45 Cable Rear Delt Flye",
                imageName: "rear_delt_cable",
                muscleGroups: [.rearDelts],
                description: "Oiseau unilatéral à la poulie à 45°"
            ),
            Exercise(
                name: "EZ-Bar Cable Curl",
                imageName: "ez_cable_curl",
                muscleGroups: [.biceps],
                description: "Curl à la poulie avec barre EZ"
            ),
            Exercise(
                name: "EZ-Bar Preacher Curl",
                imageName: "preacher_curl",
                muscleGroups: [.biceps],
                description: "Curl au pupitre avec barre EZ"
            ),
            Exercise(
                name: "DB Shrug",
                imageName: "db_shrug",
                muscleGroups: [.traps],
                description: "Shrugs aux haltères"
            ),
            Exercise(
                name: "Wrist Curl",
                imageName: "wrist_curl",
                muscleGroups: [.forearms],
                description: "Curl de poignet pour les fléchisseurs"
            ),
            Exercise(
                name: "Reverse Wrist Curl",
                imageName: "reverse_wrist_curl",
                muscleGroups: [.forearms],
                description: "Curl de poignet inversé pour les extenseurs"
            ),

            // LEGS
            Exercise(
                name: "Leg Press",
                imageName: "leg_press",
                muscleGroups: [.quadriceps, .glutes],
                description: "Presse à cuisses"
            ),
            Exercise(
                name: "Fentes TRX",
                imageName: "trx_lunge",
                muscleGroups: [.quadriceps, .glutes],
                description: "Fentes bulgares avec TRX"
            ),
            Exercise(
                name: "Cable Hip Abduction",
                imageName: "hip_abduction",
                muscleGroups: [.glutes],
                description: "Abduction de hanche à la poulie"
            ),

            // PUSH
            Exercise(
                name: "Barbell Bench Press",
                imageName: "bench_press",
                muscleGroups: [.chest, .triceps, .shoulders],
                description: "Développé couché à la barre"
            ),
            Exercise(
                name: "Banc Bottom-Half DB Flye",
                imageName: "db_flye",
                muscleGroups: [.chest],
                description: "Écarté aux haltères - demi-amplitude basse"
            ),
            Exercise(
                name: "Machine Shoulder Press",
                imageName: "shoulder_press",
                muscleGroups: [.shoulders, .triceps],
                description: "Développé épaules à la machine"
            ),
            Exercise(
                name: "Dips",
                imageName: "dips",
                muscleGroups: [.chest, .triceps],
                description: "Dips aux barres parallèles"
            ),
            Exercise(
                name: "Abdo lève jambes couché",
                imageName: "leg_raise",
                muscleGroups: [.core],
                description: "Relevé de jambes allongé"
            )
        ]
    }

    // MARK: - Week 16 Program

    static func createWeek16Program(with exercises: [Exercise], modelContext: ModelContext) -> WeekProgram {
        // Helper to find exercise by name
        func findExercise(_ name: String) -> Exercise? {
            exercises.first { $0.name.lowercased().contains(name.lowercased()) }
        }

        // Calculate start of current week (Monday)
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = weekday == 1 ? 6 : weekday - 2
        let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today)!

        let weekProgram = WeekProgram(
            weekNumber: 16,
            startDate: calendar.startOfDay(for: monday)
        )

        // UPPER (Monday)
        let upperSession = SessionTemplate(sessionType: .upper, dayIndex: 0)
        let upperExercises: [(name: String, warmup: Int, repsMin: Int, repsMax: Int, rest: Int)] = [
            ("Wide-Grip Pull-up", 2, 8, 10, 150),
            ("45 Incline", 3, 6, 8, 210),
            ("Cable Crossover", 2, 8, 10, 90),
            ("High-Cable Lateral", 2, 8, 10, 90),
            ("Overhead Cable Triceps", 1, 8, 10, 90),
            ("Bayesian Cable Curl", 1, 8, 10, 90),
            ("Pendlay", 2, 6, 10, 150)
        ]
        createPlannedExercises(upperExercises, for: upperSession, exercises: exercises)
        weekProgram.sessions.append(upperSession)

        // LOWER (Tuesday)
        let lowerSession = SessionTemplate(sessionType: .lower, dayIndex: 1)
        let lowerExercises: [(name: String, warmup: Int, repsMin: Int, repsMax: Int, rest: Int)] = [
            ("Seated Leg Curl", 2, 8, 10, 90),
            ("Leg Extension", 2, 8, 10, 90),
            ("Squat", 4, 6, 8, 210),
            ("Standing Calf", 2, 6, 8, 90),
            ("Barbell RDL", 4, 6, 8, 150),
            ("Abdo roue", 1, 8, 10, 90)
        ]
        createPlannedExercises(lowerExercises, for: lowerSession, exercises: exercises)
        weekProgram.sessions.append(lowerSession)

        // PULL (Wednesday)
        let pullSession = SessionTemplate(sessionType: .pull, dayIndex: 2)
        let pullExercises: [(name: String, warmup: Int, repsMin: Int, repsMax: Int, rest: Int)] = [
            ("Neutral-Grip Lat Pulldown", 3, 8, 10, 150),
            ("Tirage horizontal", 3, 8, 10, 150),
            ("1-Arm 45 Cable Rear Delt", 2, 10, 12, 90),
            ("EZ-Bar Cable Curl", 1, 10, 12, 90),
            ("EZ-Bar Preacher Curl", 1, 12, 15, 90),
            ("DB Shrug", 3, 10, 12, 90),
            ("Wrist Curl", 0, 15, 15, 90),
            ("Reverse Wrist Curl", 0, 15, 15, 90)
        ]
        createPlannedExercises(pullExercises, for: pullSession, exercises: exercises)
        weekProgram.sessions.append(pullSession)

        // LEGS (Thursday)
        let legsSession = SessionTemplate(sessionType: .legs, dayIndex: 3)
        let legsExercises: [(name: String, warmup: Int, repsMin: Int, repsMax: Int, rest: Int)] = [
            ("Leg Press", 4, 8, 10, 150),
            ("Seated Leg Curl", 2, 10, 12, 90),
            ("Leg Extension", 2, 10, 12, 90),
            ("Fentes TRX", 3, 8, 10, 150),
            ("Cable Hip Abduction", 2, 10, 12, 90),
            ("Standing Calf", 2, 10, 12, 90)
        ]
        createPlannedExercises(legsExercises, for: legsSession, exercises: exercises)
        weekProgram.sessions.append(legsSession)

        // PUSH (Friday)
        let pushSession = SessionTemplate(sessionType: .push, dayIndex: 4)
        let pushExercises: [(name: String, warmup: Int, repsMin: Int, repsMax: Int, rest: Int)] = [
            ("Barbell Bench Press", 4, 8, 10, 210),
            ("Bottom-Half DB Flye", 2, 10, 12, 90),
            ("Machine Shoulder Press", 3, 8, 10, 150),
            ("High-Cable Lateral", 1, 10, 12, 90),
            ("Dips", 1, 10, 10, 90),
            ("Overhead Cable Triceps", 1, 10, 12, 90),
            ("Wrist Curl", 0, 15, 15, 90),
            ("Reverse Wrist Curl", 0, 15, 15, 90),
            ("Abdo lève jambes", 2, 10, 20, 90)
        ]
        createPlannedExercises(pushExercises, for: pushSession, exercises: exercises)
        weekProgram.sessions.append(pushSession)

        return weekProgram
    }

    private static func createPlannedExercises(
        _ exerciseData: [(name: String, warmup: Int, repsMin: Int, repsMax: Int, rest: Int)],
        for session: SessionTemplate,
        exercises: [Exercise]
    ) {
        for (index, data) in exerciseData.enumerated() {
            let exercise = exercises.first { $0.name.localizedCaseInsensitiveContains(data.name) }

            let planned = PlannedExercise(
                exercise: exercise,
                warmupSets: data.warmup,
                targetRepsMin: data.repsMin,
                targetRepsMax: data.repsMax,
                restTimeSeconds: data.rest,
                orderIndex: index
            )

            session.exercises.append(planned)
        }
    }

    // MARK: - Week 15 Previous Sessions Data

    /// Crée les séances complétées de la semaine 15 avec les données réelles
    /// Les dates correspondent au lundi-vendredi de la semaine dernière
    static func createWeek16CompletedSessions(
        exercises: [Exercise],
        weekProgram: WeekProgram,
        modelContext: ModelContext
    ) -> [WorkoutSession] {
        var sessions: [WorkoutSession] = []

        // Calculer le lundi de la semaine dernière
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = weekday == 1 ? 6 : weekday - 2
        let mondayThisWeek = calendar.date(byAdding: .day, value: -daysFromMonday, to: today)!
        let mondayLastWeek = calendar.date(byAdding: .day, value: -7, to: mondayThisWeek)!

        // Récupérer les templates de session
        let upperTemplate = weekProgram.sessions.first { $0.sessionType == .upper }
        let lowerTemplate = weekProgram.sessions.first { $0.sessionType == .lower }
        let pullTemplate = weekProgram.sessions.first { $0.sessionType == .pull }
        let legsTemplate = weekProgram.sessions.first { $0.sessionType == .legs }
        let pushTemplate = weekProgram.sessions.first { $0.sessionType == .push }

        // UPPER Session (Lundi)
        if let template = upperTemplate {
            let date = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: mondayLastWeek)!
            sessions.append(createUpperSession(exercises: exercises, template: template, date: date))
        }

        // LOWER Session (Mardi)
        if let template = lowerTemplate {
            let tuesday = calendar.date(byAdding: .day, value: 1, to: mondayLastWeek)!
            let date = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: tuesday)!
            sessions.append(createLowerSession(exercises: exercises, template: template, date: date))
        }

        // PULL Session (Mercredi)
        if let template = pullTemplate {
            let wednesday = calendar.date(byAdding: .day, value: 2, to: mondayLastWeek)!
            let date = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: wednesday)!
            sessions.append(createPullSession(exercises: exercises, template: template, date: date))
        }

        // LEGS Session (Jeudi)
        if let template = legsTemplate {
            let thursday = calendar.date(byAdding: .day, value: 3, to: mondayLastWeek)!
            let date = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: thursday)!
            sessions.append(createLegsSession(exercises: exercises, template: template, date: date))
        }

        // PUSH Session (Vendredi)
        if let template = pushTemplate {
            let friday = calendar.date(byAdding: .day, value: 4, to: mondayLastWeek)!
            let date = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: friday)!
            sessions.append(createPushSession(exercises: exercises, template: template, date: date))
        }

        return sessions
    }

    // MARK: - UPPER Session

    private static func createUpperSession(exercises: [Exercise], template: SessionTemplate, date: Date) -> WorkoutSession {
        let session = WorkoutSession(
            sessionType: .upper,
            weekNumber: 0,
            startedAt: date,
            isCompleted: true
        )
        session.completedAt = date.addingTimeInterval(3600)
        session.durationSeconds = 3600

        // Données des séries: [(reps, poids)]
        let setsData: [String: [(Int, Double)]] = [
            "Wide-Grip Pull-up": [(6, 0), (6, 0), (5, 0)],
            "45 Incline": [(13, 20), (10, 20), (10, 20)],
            "Cable Crossover": [(10, 18), (10, 18), (10, 18)],
            "High-Cable Lateral": [(10, 12), (10, 12), (10, 12)],
            "Overhead Cable Triceps": [(10, 35), (10, 35)],
            "Bayesian": [(10, 18), (10, 18), (8, 18)],
            "Pendlay": [(10, 10), (10, 10), (10, 10)]
        ]

        for plannedExercise in template.sortedExercises {
            guard let exerciseName = plannedExercise.exercise?.name else { continue }

            // Trouver les données de séries correspondantes
            let sets = setsData.first { exerciseName.localizedCaseInsensitiveContains($0.key) }?.value ?? []

            if !sets.isEmpty {
                let sessionEx = createSessionExercise(
                    plannedExercise: plannedExercise,
                    sets: sets,
                    orderIndex: plannedExercise.orderIndex
                )
                session.exercises.append(sessionEx)
            }
        }

        return session
    }

    // MARK: - LOWER Session

    private static func createLowerSession(exercises: [Exercise], template: SessionTemplate, date: Date) -> WorkoutSession {
        let session = WorkoutSession(
            sessionType: .lower,
            weekNumber: 0,
            startedAt: date,
            isCompleted: true
        )
        session.completedAt = date.addingTimeInterval(3600)
        session.durationSeconds = 3600

        let setsData: [String: [(Int, Double)]] = [
            "Seated Leg Curl": [(10, 35), (10, 35), (10, 35)],
            "Leg Extension": [(10, 53), (10, 53), (10, 47)],
            "Squat": [(10, 40), (10, 40), (10, 40)],
            "Standing Calf": [(10, 70), (15, 70), (12, 70)],
            "Barbell RDL": [(10, 30), (10, 30), (10, 30)],
            "Abdo roue": [(8, 0), (7, 0), (6, 0)]
        ]

        for plannedExercise in template.sortedExercises {
            guard let exerciseName = plannedExercise.exercise?.name else { continue }
            let sets = setsData.first { exerciseName.localizedCaseInsensitiveContains($0.key) }?.value ?? []

            if !sets.isEmpty {
                let sessionEx = createSessionExercise(
                    plannedExercise: plannedExercise,
                    sets: sets,
                    orderIndex: plannedExercise.orderIndex
                )
                session.exercises.append(sessionEx)
            }
        }

        return session
    }

    // MARK: - PULL Session

    private static func createPullSession(exercises: [Exercise], template: SessionTemplate, date: Date) -> WorkoutSession {
        let session = WorkoutSession(
            sessionType: .pull,
            weekNumber: 0,
            startedAt: date,
            isCompleted: true
        )
        session.completedAt = date.addingTimeInterval(3600)
        session.durationSeconds = 3600

        let setsData: [String: [(Int, Double)]] = [
            "Neutral-Grip Lat Pulldown": [(10, 53), (10, 53), (10, 53)],
            "Tirage horizontal": [(10, 41), (10, 47), (10, 47)],
            "1-Arm 45 Cable Rear Delt": [(12, 17), (12, 17), (12, 17)],
            "EZ-Bar Cable Curl": [(10, 41), (10, 41), (10, 41)],
            "EZ-Bar Preacher Curl": [(8, 10), (9, 10), (8, 10)],
            "DB Shrug": [(12, 16), (12, 16), (12, 16)],
            "Wrist Curl": [(15, 10), (15, 10)],
            "Reverse Wrist Curl": [(15, 5), (15, 5)]
        ]

        for plannedExercise in template.sortedExercises {
            guard let exerciseName = plannedExercise.exercise?.name else { continue }
            let sets = setsData.first { exerciseName.localizedCaseInsensitiveContains($0.key) }?.value ?? []

            if !sets.isEmpty {
                let sessionEx = createSessionExercise(
                    plannedExercise: plannedExercise,
                    sets: sets,
                    orderIndex: plannedExercise.orderIndex
                )
                session.exercises.append(sessionEx)
            }
        }

        return session
    }

    // MARK: - LEGS Session

    private static func createLegsSession(exercises: [Exercise], template: SessionTemplate, date: Date) -> WorkoutSession {
        let session = WorkoutSession(
            sessionType: .legs,
            weekNumber: 0,
            startedAt: date,
            isCompleted: true
        )
        session.completedAt = date.addingTimeInterval(3600)
        session.durationSeconds = 3600

        let setsData: [String: [(Int, Double)]] = [
            "Leg Press": [(10, 60), (10, 60), (10, 60)],
            "Seated Leg Curl": [(15, 29), (15, 29), (25, 29)],
            "Leg Extension": [(10, 41), (10, 41), (10, 41)],
            "Fentes TRX": [(10, 12), (10, 12), (10, 12)],
            "Cable Hip Abduction": [(10, 7.5), (10, 7.5), (10, 7.5)],
            "Standing Calf": [(10, 70), (10, 70), (10, 70)]
        ]

        for plannedExercise in template.sortedExercises {
            guard let exerciseName = plannedExercise.exercise?.name else { continue }
            let sets = setsData.first { exerciseName.localizedCaseInsensitiveContains($0.key) }?.value ?? []

            if !sets.isEmpty {
                let sessionEx = createSessionExercise(
                    plannedExercise: plannedExercise,
                    sets: sets,
                    orderIndex: plannedExercise.orderIndex
                )
                session.exercises.append(sessionEx)
            }
        }

        return session
    }

    // MARK: - PUSH Session

    private static func createPushSession(exercises: [Exercise], template: SessionTemplate, date: Date) -> WorkoutSession {
        let session = WorkoutSession(
            sessionType: .push,
            weekNumber: 0,
            startedAt: date,
            isCompleted: true
        )
        session.completedAt = date.addingTimeInterval(3600)
        session.durationSeconds = 3600

        let setsData: [String: [(Int, Double)]] = [
            "Barbell Bench Press": [(10, 30), (10, 30), (10, 30)],
            "Bottom-Half DB Flye": [(12, 8), (12, 8), (12, 8)],
            "Machine Shoulder Press": [(10, 29), (10, 29), (10, 29)],
            "High-Cable Lateral": [(10, 12), (10, 12), (10, 12)],
            "Dips": [(7, 0), (7, 0), (6, 0)],
            "Overhead Cable Triceps": [(10, 35), (8, 35), (10, 30)],
            "Wrist Curl": [(15, 10), (15, 10)],
            "Reverse Wrist Curl": [(15, 5), (15, 5)],
            "Abdo lève jambes": [(10, 0), (10, 0), (10, 0)]
        ]

        for plannedExercise in template.sortedExercises {
            guard let exerciseName = plannedExercise.exercise?.name else { continue }
            let sets = setsData.first { exerciseName.localizedCaseInsensitiveContains($0.key) }?.value ?? []

            if !sets.isEmpty {
                let sessionEx = createSessionExercise(
                    plannedExercise: plannedExercise,
                    sets: sets,
                    orderIndex: plannedExercise.orderIndex
                )
                session.exercises.append(sessionEx)
            }
        }

        return session
    }

    // MARK: - Helper Methods

    private static func createSessionExercise(
        plannedExercise: PlannedExercise,
        sets: [(reps: Int, weight: Double)],
        orderIndex: Int
    ) -> SessionExercise {
        let sessionExercise = SessionExercise(
            plannedExercise: plannedExercise,
            isCompleted: true,
            orderIndex: orderIndex
        )

        for (index, setData) in sets.enumerated() {
            let exerciseSet = ExerciseSet(
                setNumber: index + 1,
                reps: setData.reps,
                weight: setData.weight,
                isWarmup: false,
                isCompleted: true
            )
            exerciseSet.completedAt = Date()
            sessionExercise.sets.append(exerciseSet)
        }

        return sessionExercise
    }
}
