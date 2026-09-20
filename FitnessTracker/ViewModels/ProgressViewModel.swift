import Foundation
import SwiftData
import SwiftUI

/// Feeds the Progress tab: per-lift metrics, muscle heatmap, and plateau alerts.
@Observable
final class ProgressViewModel {
    struct LiftRow: Identifiable, Hashable {
        let id: UUID
        let exercise: Exercise
        let status: ProgressStatus
        let lastE1RM: Double
        let sessionCount: Int
    }

    struct WeeklySummary: Hashable {
        var totalVolume: Double = 0
        var workoutCount: Int = 0
        var prCount: Int = 0
        var trendingUp: Int = 0
        var trendingFlat: Int = 0
        var trendingDown: Int = 0
    }

    var selectedExercise: Exercise?
    var alerts: [PlateauDetectionService.Alert] = []
    var liftRows: [LiftRow] = []
    var muscleVolumes: [MuscleGroup: Double] = [:]
    var muscleStatuses: [MuscleGroup: ProgressStatus] = [:]
    var weeklySummary = WeeklySummary()
    var displayUnit: WeightUnit = .lbs

    func refresh(context: ModelContext, displayUnit: WeightUnit = .lbs) {
        self.displayUnit = displayUnit

        let sessionDescriptor = FetchDescriptor<WorkoutSession>(
            sortBy: [SortDescriptor(\.checkedInAt, order: .reverse)]
        )
        let sessions = (try? context.fetch(sessionDescriptor)) ?? []
        let completed = sessions.filter { $0.status == .completed }

        let exerciseDescriptor = FetchDescriptor<Exercise>(
            sortBy: [SortDescriptor(\.name)]
        )
        let exercises = (try? context.fetch(exerciseDescriptor)) ?? []

        // Only exercises that appear in at least one completed session.
        let trainedIDs = Set(
            completed.flatMap(\.exercises).compactMap { $0.exercise?.id }
        )
        let trained = exercises.filter { trainedIDs.contains($0.id) && !$0.isCardio }

        alerts = PlateauDetectionService.alerts(
            exercises: trained,
            sessions: completed,
            displayUnit: displayUnit
        )

        liftRows = trained.map { exercise in
            let ses = ProgressCalculator.completedSessionExercises(for: exercise, in: completed)
            let metrics = ProgressCalculator.metrics(for: ses, displayUnit: displayUnit)
            let status = PlateauDetectionService.status(from: metrics)
            return LiftRow(
                id: exercise.id,
                exercise: exercise,
                status: status,
                lastE1RM: metrics.last?.estimatedOneRepMax ?? 0,
                sessionCount: metrics.count
            )
        }
        .sorted { $0.exercise.name < $1.exercise.name }

        let weekStart = ProgressCalculator.weekBounds().start
        var volumes: [MuscleGroup: Double] = [:]
        var statuses: [MuscleGroup: ProgressStatus] = [:]
        for group in MuscleGroup.allCases {
            let volume = ProgressCalculator.muscleGroupVolume(
                group: group,
                sessions: completed,
                displayUnit: displayUnit,
                since: weekStart
            )
            volumes[group] = volume

            let groupLifts = liftRows.filter { $0.exercise.muscleGroupEnum == group }
            if groupLifts.isEmpty {
                statuses[group] = .insufficientData
            } else if groupLifts.contains(where: { $0.status == .takingADip }) {
                statuses[group] = .takingADip
            } else if groupLifts.filter({ $0.status == .confirmedPlateau || $0.status == .plateauing }).count >= 2 {
                statuses[group] = .plateauing
            } else if groupLifts.contains(where: { $0.status == .gettingStronger }) {
                statuses[group] = .gettingStronger
            } else if groupLifts.contains(where: { $0.status == .buildingCapacity }) {
                statuses[group] = .buildingCapacity
            } else {
                statuses[group] = groupLifts.first?.status ?? .insufficientData
            }
        }
        muscleVolumes = volumes
        muscleStatuses = statuses

        let bounds = ProgressCalculator.weekBounds()
        let weekSessions = completed.filter {
            $0.checkedInAt >= bounds.start && $0.checkedInAt < bounds.end
        }
        var summary = WeeklySummary()
        summary.totalVolume = ProgressCalculator.volumeInRange(
            sessions: completed,
            start: bounds.start,
            end: bounds.end,
            displayUnit: displayUnit
        )
        summary.workoutCount = weekSessions.count
        summary.trendingUp = liftRows.filter { $0.status == .gettingStronger || $0.status == .buildingCapacity }.count
        summary.trendingFlat = liftRows.filter { $0.status == .plateauing || $0.status == .confirmedPlateau }.count
        summary.trendingDown = liftRows.filter { $0.status == .takingADip }.count

        // Approximate PRs this week: peak load higher than all prior history.
        for row in liftRows {
            let ses = ProgressCalculator.completedSessionExercises(for: row.exercise, in: completed)
            let metrics = ProgressCalculator.metrics(for: ses, displayUnit: displayUnit)
            guard let latest = metrics.last, latest.date >= bounds.start else { continue }
            let priorBest = metrics.dropLast().map(\.peakLoad).max() ?? 0
            if latest.peakLoad > priorBest {
                summary.prCount += 1
            }
        }
        weeklySummary = summary
    }

    func lifts(for group: MuscleGroup) -> [LiftRow] {
        liftRows.filter { $0.exercise.muscleGroupEnum == group }
    }
}
