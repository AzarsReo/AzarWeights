import Foundation
import SwiftData
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(UIKit)
import UIKit
#endif

/// Owns an in-progress `WorkoutSession` (check-in, set logging, check-out).
@Observable
final class SessionViewModel {
    var session: WorkoutSession?
    var showSummary = false
    var summaryDuration: TimeInterval = 0
    var summaryVolume: Double = 0
    var summaryPRCount = 0

    init(session: WorkoutSession? = nil) {
        self.session = session
    }

    func checkIn(
        template: WorkoutTemplate,
        context: ModelContext,
        weightUnit: WeightUnit = .lbs,
        now: Date = .now
    ) {
        let newSession = WorkoutSession(
            checkedInAt: now,
            status: .inProgress,
            template: template
        )
        context.insert(newSession)

        for templateExercise in template.orderedExercises {
            let sessionExercise = SessionExercise(
                order: templateExercise.order,
                plannedSets: templateExercise.targetSets,
                plannedRepsMin: templateExercise.targetRepsMin,
                plannedRepsMax: templateExercise.targetRepsMax,
                session: newSession,
                exercise: templateExercise.exercise
            )
            context.insert(sessionExercise)

            let previous = previousWorkingSets(for: templateExercise.exercise, context: context)
            let seedCount = max(templateExercise.targetSets, 1)
            for index in 0..<seedCount {
                let prior = previous.indices.contains(index) ? previous[index] : nil
                let set = SetLog(
                    setNumber: index + 1,
                    weight: prior.map { $0.unit.convert($0.weight, to: weightUnit) } ?? 0,
                    weightUnit: weightUnit.rawValue,
                    reps: prior?.reps ?? templateExercise.targetRepsMin,
                    isWarmup: false,
                    completedAt: nil,
                    sessionExercise: sessionExercise
                )
                context.insert(set)
            }
        }

        try? context.save()
        session = newSession
        showSummary = false
    }

    func resume(_ existing: WorkoutSession) {
        session = existing
        showSummary = false
    }

    func checkOut(context: ModelContext, now: Date = .now) {
        guard let session else { return }
        session.checkedOutAt = now
        session.status = .completed

        for exercise in session.orderedExercises {
            for set in exercise.orderedSets where set.completedAt == nil && (set.weight > 0 || set.reps > 0) {
                set.completedAt = now
            }
        }

        summaryDuration = now.timeIntervalSince(session.checkedInAt)
        summaryVolume = session.totalVolume
        summaryPRCount = countNewPRs(session: session, context: context)

        try? context.save()
        showSummary = true
    }

    func addSet(to sessionExercise: SessionExercise, weightUnit: WeightUnit) {
        let nextNumber = (sessionExercise.orderedSets.last?.setNumber ?? 0) + 1
        let last = sessionExercise.orderedSets.last
        let set = SetLog(
            setNumber: nextNumber,
            weight: last?.weight ?? 0,
            weightUnit: weightUnit.rawValue,
            reps: last?.reps ?? sessionExercise.plannedRepsMin,
            isWarmup: false,
            completedAt: nil,
            sessionExercise: sessionExercise
        )
        sessionExercise.sets.append(set)
    }

    func removeSet(_ set: SetLog, from sessionExercise: SessionExercise) {
        guard sessionExercise.sets.count > 1 else { return }
        sessionExercise.sets.removeAll { $0.id == set.id }
        for (index, remaining) in sessionExercise.orderedSets.enumerated() {
            remaining.setNumber = index + 1
        }
    }

    func markSetComplete(_ set: SetLog, now: Date = .now) {
        set.completedAt = now
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }

    /// Ghost values from the most recent completed session for this exercise.
    func previousWorkingSets(for exercise: Exercise?, context: ModelContext) -> [SetLog] {
        guard let exercise else { return [] }
        let exerciseID = exercise.id
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.statusRaw == "completed" },
            sortBy: [SortDescriptor(\.checkedInAt, order: .reverse)]
        )
        guard let sessions = try? context.fetch(descriptor) else { return [] }
        for session in sessions {
            if let match = session.orderedExercises.first(where: { $0.exercise?.id == exerciseID }) {
                let working = match.workingSets.filter { $0.completedAt != nil }
                if !working.isEmpty { return working }
                if !match.workingSets.isEmpty { return match.workingSets }
            }
        }
        return []
    }

    func previousGhostText(for exercise: Exercise?, context: ModelContext, unit: WeightUnit) -> String? {
        let sets = previousWorkingSets(for: exercise, context: context)
        guard let best = sets.max(by: { $0.weight < $1.weight }) ?? sets.first else { return nil }
        let weight = best.unit.convert(best.weight, to: unit)
        return String(format: "Last: %.0f %@ × %d", weight, unit.abbreviation, best.reps)
    }

    private func countNewPRs(session: WorkoutSession, context: ModelContext) -> Int {
        var count = 0
        for se in session.orderedExercises {
            guard let exercise = se.exercise else { continue }
            let history = ProgressCalculator.completedSessionExercises(for: exercise, in: fetchCompleted(context: context))
                .filter { $0.session?.id != session.id }
            let priorMetrics = ProgressCalculator.metrics(for: history)
            let priorBest = priorMetrics.map(\.peakLoad).max() ?? 0
            let priorE1RM = priorMetrics.map(\.estimatedOneRepMax).max() ?? 0
            let currentPeak = ProgressCalculator.peakLoad(for: se)
            let currentE1RM = ProgressCalculator.bestEstimatedOneRepMax(for: se)
            if currentPeak > priorBest && priorBest > 0 { count += 1 }
            else if priorBest == 0 && currentPeak > 0 { count += 1 }
            if currentE1RM > priorE1RM && priorE1RM > 0 { count += 1 }
        }
        return count
    }

    private func fetchCompleted(context: ModelContext) -> [WorkoutSession] {
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.statusRaw == "completed" }
        )
        return (try? context.fetch(descriptor)) ?? []
    }
}
