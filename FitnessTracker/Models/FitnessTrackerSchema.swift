import SwiftData

/// All SwiftData `@Model` types registered on the app `ModelContainer`.
enum FitnessTrackerSchema {
    static let allTypes: [any PersistentModel.Type] = [
        Exercise.self,
        WorkoutSplit.self,
        WorkoutTemplate.self,
        TemplateExercise.self,
        WorkoutSession.self,
        SessionExercise.self,
        SetLog.self
    ]
}
