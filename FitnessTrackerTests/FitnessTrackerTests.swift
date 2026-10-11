import XCTest
@testable import FitnessTracker

final class FitnessTrackerTests: XCTestCase {
    func testDefaultWeightUnitIsPounds() {
        XCTAssertEqual(WeightUnit.lbs.rawValue, "lbs")
        XCTAssertEqual(WeightUnit.kg.rawValue, "kg")
    }

    func testEpleyFormula() {
        let e1rm = ProgressCalculator.estimatedOneRepMax(weight: 200, reps: 5)
        XCTAssertEqual(e1rm, 200 * (1 + 5.0 / 30.0), accuracy: 0.0001)
    }

    func testSettingsKeys() {
        XCTAssertEqual(SettingsKeys.weightUnit, "settings.weightUnit")
        XCTAssertEqual(SettingsKeys.hasSeededPresetData, "settings.hasSeededPresetData")
    }

    func testLoggedSetRequiresExplicitCompletion() {
        let set = SetLog(setNumber: 1, weight: 135, reps: 8, completedAt: nil)
        XCTAssertFalse(set.countsTowardStrengthAnalytics)
        set.completedAt = .now
        XCTAssertTrue(set.countsTowardStrengthAnalytics)
    }

    func testSetRegressionAgainstPreviousInSessionAndGhost() {
        let prior = SetLog(setNumber: 1, weight: 100, reps: 10, completedAt: .now)
        var current = SetLog(setNumber: 2, weight: 95, reps: 10, completedAt: .now)
        XCTAssertTrue(current.isRegression(previousInSession: prior, ghostSet: nil, displayUnit: .lbs))
        current = SetLog(setNumber: 2, weight: 100, reps: 8, completedAt: .now)
        XCTAssertTrue(current.isRegression(previousInSession: prior, ghostSet: nil, displayUnit: .lbs))
        current = SetLog(setNumber: 2, weight: 100, reps: 10, completedAt: .now)
        XCTAssertFalse(current.isRegression(previousInSession: prior, ghostSet: nil, displayUnit: .lbs))

        let ghost = SetLog(setNumber: 1, weight: 120, reps: 5, completedAt: .now)
        let firstSet = SetLog(setNumber: 1, weight: 115, reps: 5, completedAt: .now)
        XCTAssertTrue(firstSet.isRegression(previousInSession: nil, ghostSet: ghost, displayUnit: .lbs))
        XCTAssertFalse(SetLog(setNumber: 1, weight: 120, reps: 4, completedAt: .now)
            .isRegression(previousInSession: nil, ghostSet: ghost, displayUnit: .lbs))
    }

    func testSessionVolumeConvertsMixedUnits() {
        let session = WorkoutSession(status: .completed)
        let exercise = SessionExercise(order: 0, session: session)
        let lbsSet = SetLog(setNumber: 1, weight: 100, weightUnit: WeightUnit.lbs.rawValue, reps: 10, completedAt: .now, sessionExercise: exercise)
        let kgSet = SetLog(setNumber: 2, weight: 100, weightUnit: WeightUnit.kg.rawValue, reps: 5, completedAt: .now, sessionExercise: exercise)
        exercise.sets = [lbsSet, kgSet]
        session.exercises = [exercise]

        let totalLbs = ProgressCalculator.sessionVolume(session, in: .lbs)
        let expectedKgAsLbs = WeightUnit.kg.convert(100, to: .lbs) * 5
        XCTAssertEqual(totalLbs, 100 * 10 + expectedKgAsLbs, accuracy: 0.01)
    }
}
