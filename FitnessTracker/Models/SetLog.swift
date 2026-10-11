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
    /// Rate of perceived exertion (1–10). `nil` until the lifter selects a value.
    var rpe: Int?
    /// Logged duration for cardio exercises (`nil` for strength sets).
    var durationSeconds: Int?
    var isWarmup: Bool
    var completedAt: Date?

    var sessionExercise: SessionExercise?

    var volume: Double { weight * Double(reps) }

    var durationMinutes: Int {
        get { max(0, (durationSeconds ?? 0) / 60) }
        set { durationSeconds = newValue > 0 ? newValue * 60 : nil }
    }

    var hasLoggedDuration: Bool { (durationSeconds ?? 0) > 0 }

    /// User tapped Log and entered valid strength data (bodyweight may be 0).
    var countsTowardStrengthAnalytics: Bool {
        guard completedAt != nil, !isWarmup else { return false }
        return reps > 0 && weight >= 0
    }

    /// User tapped Log and entered cardio duration.
    var countsTowardCardioAnalytics: Bool {
        guard completedAt != nil, !isWarmup else { return false }
        return hasLoggedDuration
    }

    func isValidToLog(isCardio: Bool) -> Bool {
        if isCardio { return hasLoggedDuration }
        return reps > 0 && weight >= 0
    }

    /// True when this completed working set dropped load or matched weight with fewer reps vs baseline.
    func isRegression(previousInSession: SetLog?, ghostSet: SetLog?, displayUnit: WeightUnit) -> Bool {
        guard countsTowardStrengthAnalytics else { return false }
        let baseline: SetLog?
        if let previousInSession, previousInSession.countsTowardStrengthAnalytics {
            baseline = previousInSession
        } else if let ghostSet, ghostSet.countsTowardStrengthAnalytics {
            baseline = ghostSet
        } else {
            baseline = nil
        }
        guard let baseline else { return false }

        let currentWeight = unit.convert(weight, to: displayUnit)
        let baselineWeight = baseline.unit.convert(baseline.weight, to: displayUnit)
        if currentWeight + 0.001 < baselineWeight { return true }
        let compareReps = previousInSession != nil && previousInSession?.countsTowardStrengthAnalytics == true
        if compareReps, abs(currentWeight - baselineWeight) <= 0.001, reps < baseline.reps { return true }
        return false
    }

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
        rpe: Int? = nil,
        durationSeconds: Int? = nil,
        isWarmup: Bool = false,
        completedAt: Date? = .now,
        sessionExercise: SessionExercise? = nil
    ) {
        self.id = id
        self.setNumber = setNumber
        self.weight = weight
        self.weightUnit = weightUnit
        self.reps = reps
        self.rpe = rpe
        self.durationSeconds = durationSeconds
        self.isWarmup = isWarmup
        self.completedAt = completedAt
        self.sessionExercise = sessionExercise
    }
}
