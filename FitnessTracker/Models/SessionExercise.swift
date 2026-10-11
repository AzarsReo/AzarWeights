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

    /// Non-warmup sets shown in the active workout UI.
    var workingSets: [SetLog] {
        orderedSets.filter { !$0.isWarmup }
    }

    /// Sets the user explicitly logged — sole input for volume, PRs, and plateaus.
    var loggedWorkingSets: [SetLog] {
        workingSets.filter { set in
            if isCardio { return set.countsTowardCardioAnalytics }
            return set.countsTowardStrengthAnalytics
        }
    }

    /// Last logged working strength set before `set` in this exercise (same session).
    func previousLoggedWorkingSet(before set: SetLog) -> SetLog? {
        guard !isCardio else { return nil }
        let ordered = orderedSets
        guard let index = ordered.firstIndex(where: { $0.id == set.id }) else { return nil }
        for candidate in ordered[..<index].reversed() {
            if candidate.countsTowardStrengthAnalytics { return candidate }
        }
        return nil
    }

    var totalCardioSeconds: Int {
        loggedWorkingSets.compactMap(\.durationSeconds).reduce(0, +)
    }

    var isCardio: Bool { exercise?.isCardio == true }

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
