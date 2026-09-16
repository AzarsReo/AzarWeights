import Foundation
import SwiftData

/// An exercise performed during a `WorkoutSession`, with copied template targets and logged sets.
@Model
final class SessionExercise {
    var id: UUID
    var order: Int
    /// Snapshot of the template target so later edits to the template don't rewrite history.
    var plannedSets: Int
    var plannedRepsMin: Int
    var plannedRepsMax: Int

    var session: WorkoutSession?
    var exercise: Exercise?

    @Relationship(deleteRule: .cascade, inverse: \SetLog.sessionExercise)
    var sets: [SetLog]

    var orderedSets: [SetLog] {
        sets.sorted { $0.setNumber < $1.setNumber }
    }

    var workingSets: [SetLog] {
        orderedSets.filter { !$0.isWarmup }
    }

    var workingVolume: Double {
        workingSets.reduce(0) { $0 + $1.volume }
    }

    var peakLoad: Double {
        workingSets.map(\.weight).max() ?? 0
    }

    init(
        id: UUID = UUID(),
        order: Int,
        plannedSets: Int = 3,
        plannedRepsMin: Int = 8,
        plannedRepsMax: Int = 12,
        session: WorkoutSession? = nil,
        exercise: Exercise? = nil
    ) {
        self.id = id
        self.order = order
        self.plannedSets = plannedSets
        self.plannedRepsMin = plannedRepsMin
        self.plannedRepsMax = plannedRepsMax
        self.session = session
        self.exercise = exercise
        self.sets = []
    }
}
