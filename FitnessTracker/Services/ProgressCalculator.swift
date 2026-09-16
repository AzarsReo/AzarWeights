import Foundation
import SwiftData

/// e1RM, volume load, PRs, and trend slope for the Progress tab.
enum ProgressCalculator {
    struct SessionMetrics: Identifiable, Hashable {
        var id: UUID { sessionExerciseID }
        let sessionExerciseID: UUID
        let sessionID: UUID
        let date: Date
        let peakLoad: Double
        let volumeLoad: Double
        let estimatedOneRepMax: Double
        let strengthSets: Int
        let hypertrophySets: Int
        let enduranceSets: Int
    }

    struct PersonalRecords: Hashable {
        var maxWeight: Double = 0
        var maxReps: Int = 0
        var maxVolume: Double = 0
        var maxEstimatedOneRepMax: Double = 0
        var maxWeightDate: Date?
        var maxRepsDate: Date?
        var maxVolumeDate: Date?
        var maxEstimatedOneRepMaxDate: Date?
    }

    struct PREvent: Identifiable, Hashable {
        enum Kind: String, Hashable {
            case weight
            case reps
            case volume
            case e1RM

            var displayName: String {
                switch self {
                case .weight: return "Weight PR"
                case .reps: return "Rep PR"
                case .volume: return "Volume PR"
                case .e1RM: return "e1RM PR"
                }
            }
        }

        let id: UUID
        let kind: Kind
        let value: Double
        let date: Date
        let label: String
    }

    static func estimatedOneRepMax(weight: Double, reps: Int) -> Double {
        guard reps > 0 else { return weight }
        return weight * (1 + Double(reps) / 30.0)
    }

    static func volumeLoad(for sessionExercise: SessionExercise) -> Double {
        sessionExercise.workingVolume
    }

    static func peakLoad(for sessionExercise: SessionExercise) -> Double {
        sessionExercise.peakLoad
    }

    static func bestEstimatedOneRepMax(for sessionExercise: SessionExercise) -> Double {
        sessionExercise.workingSets.map(\.estimatedOneRepMax).max() ?? 0
    }

    /// Session exercises for a given lift, oldest → newest, completed sessions only.
    static func completedSessionExercises(
        for exercise: Exercise,
        in sessions: [WorkoutSession]
    ) -> [SessionExercise] {
        sessions
            .filter { $0.status == .completed }
            .compactMap { session -> SessionExercise? in
                session.orderedExercises.first { $0.exercise?.id == exercise.id }
            }
            .sorted {
                ($0.session?.checkedInAt ?? .distantPast) < ($1.session?.checkedInAt ?? .distantPast)
            }
    }

    static func metrics(for sessionExercises: [SessionExercise], displayUnit: WeightUnit = .lbs) -> [SessionMetrics] {
        sessionExercises.compactMap { se in
            guard let session = se.session else { return nil }
            let working = se.workingSets
            guard !working.isEmpty else { return nil }

            var peak = 0.0
            var volume = 0.0
            var bestE1RM = 0.0
            var strength = 0
            var hypertrophy = 0
            var endurance = 0

            for set in working {
                let unit = set.unit
                let weight = unit.convert(set.weight, to: displayUnit)
                let e1rm = estimatedOneRepMax(weight: weight, reps: set.reps)
                peak = max(peak, weight)
                volume += weight * Double(set.reps)
                bestE1RM = max(bestE1RM, e1rm)
                switch set.reps {
                case 1...5: strength += 1
                case 6...12: hypertrophy += 1
                default: endurance += 1
                }
            }

            return SessionMetrics(
                sessionExerciseID: se.id,
                sessionID: session.id,
                date: session.checkedInAt,
                peakLoad: peak,
                volumeLoad: volume,
                estimatedOneRepMax: bestE1RM,
                strengthSets: strength,
                hypertrophySets: hypertrophy,
                enduranceSets: endurance
            )
        }
        .sorted { $0.date < $1.date }
    }

    static func personalRecords(from metrics: [SessionMetrics]) -> PersonalRecords {
        var prs = PersonalRecords()
        for m in metrics {
            if m.peakLoad > prs.maxWeight {
                prs.maxWeight = m.peakLoad
                prs.maxWeightDate = m.date
            }
            if m.volumeLoad > prs.maxVolume {
                prs.maxVolume = m.volumeLoad
                prs.maxVolumeDate = m.date
            }
            if m.estimatedOneRepMax > prs.maxEstimatedOneRepMax {
                prs.maxEstimatedOneRepMax = m.estimatedOneRepMax
                prs.maxEstimatedOneRepMaxDate = m.date
            }
        }
        return prs
    }

    /// Chronological PR milestones (first time each record type is set / broken).
    static func prTimeline(from metrics: [SessionMetrics], displayUnit: WeightUnit = .lbs) -> [PREvent] {
        var events: [PREvent] = []
        var bestWeight = 0.0
        var bestVolume = 0.0
        var bestE1RM = 0.0
        let abbr = displayUnit.abbreviation

        for m in metrics {
            if m.peakLoad > bestWeight {
                bestWeight = m.peakLoad
                events.append(
                    PREvent(
                        id: UUID(),
                        kind: .weight,
                        value: m.peakLoad,
                        date: m.date,
                        label: String(format: "%.0f %@", m.peakLoad, abbr)
                    )
                )
            }
            if m.volumeLoad > bestVolume {
                bestVolume = m.volumeLoad
                events.append(
                    PREvent(
                        id: UUID(),
                        kind: .volume,
                        value: m.volumeLoad,
                        date: m.date,
                        label: String(format: "%.0f vol", m.volumeLoad)
                    )
                )
            }
            if m.estimatedOneRepMax > bestE1RM {
                bestE1RM = m.estimatedOneRepMax
                events.append(
                    PREvent(
                        id: UUID(),
                        kind: .e1RM,
                        value: m.estimatedOneRepMax,
                        date: m.date,
                        label: String(format: "%.0f e1RM", m.estimatedOneRepMax)
                    )
                )
            }
        }
        return events.sorted { $0.date < $1.date }
    }

    /// Linear regression slope of y over evenly spaced x = 0..<n.
    static func trendSlope(values: [Double]) -> Double {
        let n = Double(values.count)
        guard n >= 2 else { return 0 }
        let xs = (0..<values.count).map(Double.init)
        let sumX = xs.reduce(0, +)
        let sumY = values.reduce(0, +)
        let sumXY = zip(xs, values).map(*).reduce(0, +)
        let sumXX = xs.map { $0 * $0 }.reduce(0, +)
        let denom = n * sumXX - sumX * sumX
        guard denom != 0 else { return 0 }
        return (n * sumXY - sumX * sumY) / denom
    }

    static func rollingAverage(values: [Double], window: Int = 4) -> Double? {
        guard !values.isEmpty else { return nil }
        let slice = values.suffix(window)
        return slice.reduce(0, +) / Double(slice.count)
    }

    static func muscleGroupVolume(
        group: MuscleGroup,
        sessions: [WorkoutSession],
        displayUnit: WeightUnit = .lbs,
        since: Date? = nil
    ) -> Double {
        sessions
            .filter { $0.status == .completed }
            .filter { session in
                guard let since else { return true }
                return session.checkedInAt >= since
            }
            .flatMap(\.exercises)
            .filter { $0.exercise?.muscleGroup == group.rawValue }
            .reduce(0.0) { partial, se in
                partial + se.workingSets.reduce(0.0) { sum, set in
                    let weight = set.unit.convert(set.weight, to: displayUnit)
                    return sum + weight * Double(set.reps)
                }
            }
    }

    static func weekBounds(containing date: Date = .now, calendar: Calendar = .current) -> (start: Date, end: Date) {
        let start = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        let end = calendar.date(byAdding: .day, value: 7, to: start) ?? date
        return (start, end)
    }

    static func volumeInRange(
        sessions: [WorkoutSession],
        start: Date,
        end: Date,
        displayUnit: WeightUnit = .lbs
    ) -> Double {
        sessions
            .filter { $0.status == .completed }
            .filter { $0.checkedInAt >= start && $0.checkedInAt < end }
            .reduce(0.0) { partial, session in
                partial + session.exercises.reduce(0.0) { sum, se in
                    sum + se.workingSets.reduce(0.0) { inner, set in
                        let weight = set.unit.convert(set.weight, to: displayUnit)
                        return inner + weight * Double(set.reps)
                    }
                }
            }
    }
}
