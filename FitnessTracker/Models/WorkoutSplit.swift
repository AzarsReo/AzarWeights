import Foundation
import SwiftData

/// A weekly program structure (PPL, Upper/Lower, Bro Split, etc.).
@Model
final class WorkoutSplit {
    var id: UUID
    var name: String
    /// Program summary shown in the split picker. Named to avoid clashing with `CustomStringConvertible`.
    var splitDescription: String
    var daysPerWeek: Int
    /// Bundled programs are `true`; user-built programs (future) are `false`.
    var isPreset: Bool
    /// At most one split should be active — the one driving Home / calendar scheduling.
    var isActive: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \WorkoutTemplate.split)
    var templates: [WorkoutTemplate]

    /// Day templates ordered by `dayIndex`.
    var orderedTemplates: [WorkoutTemplate] {
        templates.sorted { $0.dayIndex < $1.dayIndex }
    }

    init(
        id: UUID = UUID(),
        name: String,
        splitDescription: String,
        daysPerWeek: Int,
        isPreset: Bool = true,
        isActive: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.splitDescription = splitDescription
        self.daysPerWeek = daysPerWeek
        self.isPreset = isPreset
        self.isActive = isActive
        self.createdAt = createdAt
        self.templates = []
    }
}
