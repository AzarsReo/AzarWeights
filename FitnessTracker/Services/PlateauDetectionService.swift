import Foundation
import SwiftData

/// Plateau logic, status badges, and suggestion copy for the Progress tab.
enum PlateauDetectionService {
    static let minimumSessions = 4
    static let flatBandPercent = 0.03
    static let regressionDropPercent = 0.15
    static let confirmedSessionCount = 6

    struct Alert: Identifiable, Hashable {
        let id: UUID
        let exerciseID: UUID?
        let exerciseName: String
        let muscleGroup: MuscleGroup?
        let status: ProgressStatus
        let message: String
        let suggestion: String
    }

    static func status(for exercise: Exercise, sessions: [SessionExercise]) -> ProgressStatus {
        let metrics = ProgressCalculator.metrics(for: sessions)
        return status(from: metrics)
    }

    static func status(from metrics: [ProgressCalculator.SessionMetrics]) -> ProgressStatus {
        guard metrics.count >= minimumSessions else { return .insufficientData }

        let recent = Array(metrics.suffix(minimumSessions))
        let peaks = recent.map(\.peakLoad)
        let volumes = recent.map(\.volumeLoad)
        let e1rms = recent.map(\.estimatedOneRepMax)

        if isRegressing(values: e1rms) || isRegressing(values: peaks) {
            return .takingADip
        }

        let peakFlat = isFlat(values: peaks)
        let volumeFlat = isFlat(values: volumes)
        let e1rmFlat = isFlat(values: e1rms)
        let volumeRising = ProgressCalculator.trendSlope(values: volumes) > 0
            && !volumeFlat
        let allRising =
            ProgressCalculator.trendSlope(values: peaks) > 0
            && ProgressCalculator.trendSlope(values: volumes) > 0
            && ProgressCalculator.trendSlope(values: e1rms) > 0

        if peakFlat && volumeRising && e1rmFlat {
            return .buildingCapacity
        }
        if peakFlat && volumeFlat && e1rmFlat {
            return metrics.count >= confirmedSessionCount ? .confirmedPlateau : .plateauing
        }
        if allRising {
            return .gettingStronger
        }
        if peakFlat && e1rmFlat {
            return metrics.count >= confirmedSessionCount ? .confirmedPlateau : .plateauing
        }
        if ProgressCalculator.trendSlope(values: e1rms) > 0 || ProgressCalculator.trendSlope(values: peaks) > 0 {
            return .gettingStronger
        }
        return .plateauing
    }

    static func suggestion(for status: ProgressStatus) -> String {
        switch status {
        case .plateauing:
            return "Try adding 1 rep at current weight, or add one working set."
        case .confirmedPlateau:
            return "Consider a deload week (40–50% volume) or switch rep range (e.g. 5×5 → 4×8)."
        case .takingADip:
            return "Check sleep, nutrition, and recovery before increasing intensity."
        case .buildingCapacity:
            return "Load is flat but volume is climbing — capacity is expanding."
        case .gettingStronger:
            return "Keep progressing — all strength signals are trending up."
        case .insufficientData:
            return "Log at least 4 sessions on this lift to unlock plateau detection."
        }
    }

    static func alerts(
        exercises: [Exercise],
        sessions: [WorkoutSession],
        displayUnit: WeightUnit = .lbs
    ) -> [Alert] {
        var results: [Alert] = []
        var plateauByGroup: [MuscleGroup: [String]] = [:]

        for exercise in exercises {
            let ses = ProgressCalculator.completedSessionExercises(for: exercise, in: sessions)
            let metrics = ProgressCalculator.metrics(for: ses, displayUnit: displayUnit)
            let status = status(from: metrics)
            guard status == .plateauing || status == .confirmedPlateau || status == .takingADip else {
                continue
            }
            let flatCount = metrics.count
            let message: String
            switch status {
            case .confirmedPlateau:
                message = "\(exercise.name) plateauing — \(flatCount) sessions flat."
            case .plateauing:
                message = "\(exercise.name) early plateau — \(min(flatCount, 4)) sessions flat."
            case .takingADip:
                message = "\(exercise.name) is down >15% recently."
            default:
                message = exercise.name
            }
            results.append(
                Alert(
                    id: exercise.id,
                    exerciseID: exercise.id,
                    exerciseName: exercise.name,
                    muscleGroup: exercise.muscleGroupEnum,
                    status: status,
                    message: message,
                    suggestion: suggestion(for: status)
                )
            )
            if let group = exercise.muscleGroupEnum,
               status == .plateauing || status == .confirmedPlateau {
                plateauByGroup[group, default: []].append(exercise.name)
            }
        }

        for (group, names) in plateauByGroup where names.count >= 2 {
            results.insert(
                Alert(
                    id: UUID(),
                    exerciseID: nil,
                    exerciseName: group.rawValue,
                    muscleGroup: group,
                    status: .plateauing,
                    message: "\(group.rawValue) progress stalling — \(names.joined(separator: " and ")) both flat.",
                    suggestion: suggestion(for: .plateauing)
                ),
                at: 0
            )
        }

        return results.sorted { lhs, rhs in
            severity(lhs.status) > severity(rhs.status)
        }
    }

    private static func severity(_ status: ProgressStatus) -> Int {
        switch status {
        case .takingADip: return 5
        case .confirmedPlateau: return 4
        case .plateauing: return 3
        case .buildingCapacity: return 2
        case .gettingStronger: return 1
        case .insufficientData: return 0
        }
    }

    private static func isFlat(values: [Double]) -> Bool {
        guard let avg = ProgressCalculator.rollingAverage(values: values), avg > 0 else {
            return values.allSatisfy { $0 == values.first }
        }
        return values.allSatisfy { abs($0 - avg) / avg <= flatBandPercent }
    }

    private static func isRegressing(values: [Double]) -> Bool {
        guard values.count >= 3 else { return false }
        let recent = Array(values.suffix(3))
        guard let first = recent.first, first > 0 else { return false }
        let last = recent.last ?? first
        return (first - last) / first > regressionDropPercent
    }
}
