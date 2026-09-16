import Foundation
import SwiftData

/// Canonical lift in the exercise library (preset or user-created).
@Model
final class Exercise {
    /// Stable identifier used when joining templates and session logs.
    var id: UUID
    var name: String
    /// `MuscleGroup.rawValue` (e.g. `"Chest"`).
    var muscleGroup: String
    /// `EquipmentType.rawValue` (e.g. `"Barbell"`).
    var equipment: String
    /// `MovementPattern.rawValue` (e.g. `"push"`).
    var movementPattern: String
    /// Search aliases (e.g. `"RDL"` for Romanian Deadlift).
    var aliases: [String]
    /// `true` when the user created this lift; bundled library rows are `false`.
    var isCustom: Bool
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \TemplateExercise.exercise)
    var templateUsages: [TemplateExercise]

    @Relationship(deleteRule: .nullify, inverse: \SessionExercise.exercise)
    var sessionUsages: [SessionExercise]

    var muscleGroupEnum: MuscleGroup? { MuscleGroup(rawValue: muscleGroup) }
    var equipmentEnum: EquipmentType? { EquipmentType(rawValue: equipment) }
    var movementPatternEnum: MovementPattern? { MovementPattern(rawValue: movementPattern) }

    init(
        id: UUID = UUID(),
        name: String,
        muscleGroup: String,
        equipment: String,
        movementPattern: String,
        aliases: [String] = [],
        isCustom: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.muscleGroup = muscleGroup
        self.equipment = equipment
        self.movementPattern = movementPattern
        self.aliases = aliases
        self.isCustom = isCustom
        self.createdAt = createdAt
        self.templateUsages = []
        self.sessionUsages = []
    }
}
