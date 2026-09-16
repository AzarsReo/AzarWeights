import Foundation
import SwiftData

/// A named workout (split day, starter template, or user custom routine).
///
/// Distinguishing flags for later UI:
/// - Starter Templates drawer: `isStarterTemplate == true` (also `isPreset`, `split == nil`)
/// - Split day templates: `split != nil` (ordered by `dayIndex`)
/// - My Workouts (primary): `isCustom == true`
@Model
final class WorkoutTemplate {
    var id: UUID
    var name: String
    var isCustom: Bool
    var isPreset: Bool
    /// The 6 baseline templates in the collapsible Starter Templates drawer.
    var isStarterTemplate: Bool
    /// Position within the parent split (0-based). Ignored for starters/custom unless assigned to a split.
    var dayIndex: Int
    /// `Calendar.Component.weekday` values (1 = Sunday … 7 = Saturday). Empty until onboarding assigns days.
    var assignedWeekdays: [Int]
    var notes: String
    var createdAt: Date

    var split: WorkoutSplit?

    @Relationship(deleteRule: .cascade, inverse: \TemplateExercise.template)
    var exercises: [TemplateExercise]

    @Relationship(deleteRule: .nullify, inverse: \WorkoutSession.template)
    var sessions: [WorkoutSession]

    var orderedExercises: [TemplateExercise] {
        exercises.sorted { $0.order < $1.order }
    }

    init(
        id: UUID = UUID(),
        name: String,
        isCustom: Bool = false,
        isPreset: Bool = true,
        isStarterTemplate: Bool = false,
        dayIndex: Int = 0,
        assignedWeekdays: [Int] = [],
        notes: String = "",
        createdAt: Date = .now,
        split: WorkoutSplit? = nil
    ) {
        self.id = id
        self.name = name
        self.isCustom = isCustom
        self.isPreset = isPreset
        self.isStarterTemplate = isStarterTemplate
        self.dayIndex = dayIndex
        self.assignedWeekdays = assignedWeekdays
        self.notes = notes
        self.createdAt = createdAt
        self.split = split
        self.exercises = []
        self.sessions = []
    }
}
