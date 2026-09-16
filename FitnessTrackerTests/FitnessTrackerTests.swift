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
}
