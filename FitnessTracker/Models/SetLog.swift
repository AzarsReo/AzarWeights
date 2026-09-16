import Foundation
import SwiftData

/// Actual performance for one set: weight, reps, warmup flag.
///
/// `weight` is stored in `weightUnit` (`WeightUnit.rawValue`) — the unit chosen in Settings
/// at log time. Convert with `WeightUnit.convert(_:to:)` before mixing historical rows
/// that may have been logged under a different unit.
@Model
final class SetLog {
    var id: UUID
    var setNumber: Int
    var weight: Double
    /// `"lbs"` or `"kg"`.
    var weightUnit: String
    var reps: Int
    var isWarmup: Bool
    var completedAt: Date?

    var sessionExercise: SessionExercise?

    var volume: Double { weight * Double(reps) }

    var unit: WeightUnit {
        get { WeightUnit(rawValue: weightUnit) ?? .lbs }
        set { weightUnit = newValue.rawValue }
    }

    /// Epley estimated 1RM: `weight × (1 + reps/30)`. Not defined for 0 reps.
    var estimatedOneRepMax: Double {
        guard reps > 0 else { return weight }
        return weight * (1 + Double(reps) / 30.0)
    }

    init(
        id: UUID = UUID(),
        setNumber: Int,
        weight: Double,
        weightUnit: String = WeightUnit.lbs.rawValue,
        reps: Int,
        isWarmup: Bool = false,
        completedAt: Date? = .now,
        sessionExercise: SessionExercise? = nil
    ) {
        self.id = id
        self.setNumber = setNumber
        self.weight = weight
        self.weightUnit = weightUnit
        self.reps = reps
        self.isWarmup = isWarmup
        self.completedAt = completedAt
        self.sessionExercise = sessionExercise
    }
}
