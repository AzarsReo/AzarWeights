import Foundation
import SwiftData

/// One gym visit: check-in, optional check-out, and logged exercises.
@Model
final class WorkoutSession {
    var id: UUID
    var checkedInAt: Date
    var checkedOutAt: Date?
    /// `SessionStatus.rawValue`: `inProgress`, `completed`, `skipped`.
    var statusRaw: String
    var notes: String
    var createdAt: Date

    var template: WorkoutTemplate?

    @Relationship(deleteRule: .cascade, inverse: \SessionExercise.session)
    var exercises: [SessionExercise]

    var status: SessionStatus {
        get { SessionStatus(rawValue: statusRaw) ?? .inProgress }
        set { statusRaw = newValue.rawValue }
    }

    var duration: TimeInterval? {
        guard let checkedOutAt else { return nil }
        return checkedOutAt.timeIntervalSince(checkedInAt)
    }

    var orderedExercises: [SessionExercise] {
        exercises.sorted { $0.order < $1.order }
    }

    /// Working-set volume in the units stored on each `SetLog`.
    var totalVolume: Double {
        exercises.reduce(0) { partial, sessionExercise in
            partial + sessionExercise.workingVolume
        }
    }

    init(
        id: UUID = UUID(),
        checkedInAt: Date = .now,
        checkedOutAt: Date? = nil,
        status: SessionStatus = .inProgress,
        notes: String = "",
        createdAt: Date = .now,
        template: WorkoutTemplate? = nil
    ) {
        self.id = id
        self.checkedInAt = checkedInAt
        self.checkedOutAt = checkedOutAt
        self.statusRaw = status.rawValue
        self.notes = notes
        self.createdAt = createdAt
        self.template = template
        self.exercises = []
    }
}
