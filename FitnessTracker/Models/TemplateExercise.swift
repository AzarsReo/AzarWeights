import Foundation
import SwiftData

/// Ordered exercise slot inside a `WorkoutTemplate`, with default sets/reps targets.
@Model
final class TemplateExercise {
    var id: UUID
    /// 0-based position in the workout.
    var order: Int
    var targetSets: Int
    var targetRepsMin: Int
    var targetRepsMax: Int
    /// Suggested rest between sets, in seconds. Default 90.
    var restSeconds: Int

    var template: WorkoutTemplate?
    var exercise: Exercise?

    var targetRepsDisplay: String {
        if targetRepsMin == targetRepsMax {
            return "\(targetRepsMin)"
        }
        return "\(targetRepsMin)–\(targetRepsMax)"
    }

    init(
        id: UUID = UUID(),
        order: Int,
        targetSets: Int,
        targetRepsMin: Int,
        targetRepsMax: Int,
        restSeconds: Int = 90,
        template: WorkoutTemplate? = nil,
        exercise: Exercise? = nil
    ) {
        self.id = id
        self.order = order
        self.targetSets = targetSets
        self.targetRepsMin = targetRepsMin
        self.targetRepsMax = targetRepsMax
        self.restSeconds = restSeconds
        self.template = template
        self.exercise = exercise
    }
}
