import Foundation
import SwiftData
import SwiftUI
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
    /// True when the finished session can be saved as a new My Workout template.
    var shouldOfferSaveWorkout = false
    var workoutSaveCompleted = false
    var suggestedWorkoutName = "My Workout"

    private var startedFromCustomTemplate = false
    private var sessionStructureModified = false

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
        startedFromCustomTemplate = template.isCustom
        sessionStructureModified = false
        workoutSaveCompleted = false

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

            if let exercise = templateExercise.exercise {
                seedSets(
                    for: sessionExercise,
                    exercise: exercise,
                    context: context,
                    weightUnit: weightUnit
                )
            }
        }

        try? context.save()
        session = newSession
        showSummary = false
    }

    func resume(_ existing: WorkoutSession) {
        session = existing
        showSummary = false
        startedFromCustomTemplate = existing.template?.isCustom ?? false
        sessionStructureModified = false
        workoutSaveCompleted = false
    }

    func checkOut(context: ModelContext, now: Date = .now) {
        guard let session else { return }
        session.checkedOutAt = now
        session.status = .completed

        for exercise in session.orderedExercises {
            for set in exercise.orderedSets where set.completedAt == nil && (set.weight > 0 || set.reps > 0 || set.hasLoggedDuration) {
                set.completedAt = now
            }
        }

        summaryDuration = now.timeIntervalSince(session.checkedInAt)
        summaryVolume = session.totalVolume
        summaryPRCount = countNewPRs(session: session, context: context)
        shouldOfferSaveWorkout = !startedFromCustomTemplate || sessionStructureModified
        if let sourceName = session.template?.name, !startedFromCustomTemplate {
            suggestedWorkoutName = "My \(sourceName)"
        } else {
            suggestedWorkoutName = session.template?.name ?? "My Workout"
        }

        try? context.save()
        showSummary = true
    }

    /// Saves the completed session structure as a new custom workout template.
    @discardableResult
    func saveSessionAsTemplate(name: String, context: ModelContext) -> Bool {
        guard let session else { return false }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        let template = WorkoutTemplate(
            name: trimmed,
            isCustom: true,
            isPreset: false,
            isStarterTemplate: false,
            split: nil
        )
        context.insert(template)

        for se in session.orderedExercises {
            guard let exercise = se.exercise else { continue }
            let targetSets: Int
            let repsMin: Int
            let repsMax: Int
            if exercise.isCardio {
                targetSets = 1
                repsMin = 0
                repsMax = 0
            } else {
                targetSets = max(se.orderedSets.count, se.plannedSets, 1)
                repsMin = se.plannedRepsMin
                repsMax = se.plannedRepsMax
            }
            let row = TemplateExercise(
                order: se.order,
                targetSets: targetSets,
                targetRepsMin: repsMin,
                targetRepsMax: repsMax,
                template: template,
                exercise: exercise
            )
            context.insert(row)
        }

        try? context.save()
        workoutSaveCompleted = true
        return true
    }

    func addSet(to sessionExercise: SessionExercise, weightUnit: WeightUnit, context: ModelContext) {
        guard !sessionExercise.isCardio else { return }
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
        context.insert(set)
        sessionExercise.sets.append(set)
    }

    func removeSet(_ set: SetLog, from sessionExercise: SessionExercise, context: ModelContext) {
        guard sessionExercise.sets.count > 1 else { return }
        sessionExercise.sets.removeAll { $0.id == set.id }
        context.delete(set)
        for (index, remaining) in sessionExercise.orderedSets.enumerated() {
            remaining.setNumber = index + 1
        }
    }

    /// Permanently removes the current session and all logged sets.
    func deleteSession(context: ModelContext) {
        guard let session else { return }
        context.delete(session)
        try? context.save()
        self.session = nil
        showSummary = false
    }

    /// Replaces an exercise mid-session and re-seeds its sets from history or defaults.
    func swapExercise(
        _ sessionExercise: SessionExercise,
        to newExercise: Exercise,
        context: ModelContext,
        weightUnit: WeightUnit
    ) {
        guard sessionExercise.exercise?.id != newExercise.id else { return }

        for set in sessionExercise.sets {
            context.delete(set)
        }
        sessionExercise.sets.removeAll()
        sessionExercise.exercise = newExercise

        if newExercise.isCardio {
            sessionExercise.plannedSets = 1
            sessionExercise.plannedRepsMin = 0
            sessionExercise.plannedRepsMax = 0
        }

        seedSets(
            for: sessionExercise,
            exercise: newExercise,
            context: context,
            weightUnit: weightUnit
        )
        sessionStructureModified = true
        try? context.save()
    }

    private func seedSets(
        for sessionExercise: SessionExercise,
        exercise: Exercise,
        context: ModelContext,
        weightUnit: WeightUnit
    ) {
        let previous = previousWorkingSets(for: exercise, context: context)
        let seedCount = exercise.isCardio ? 1 : max(sessionExercise.plannedSets, 1)
        for index in 0..<seedCount {
            let prior = previous.indices.contains(index) ? previous[index] : nil
            let set: SetLog
            if exercise.isCardio {
                set = SetLog(
                    setNumber: 1,
                    weight: 0,
                    weightUnit: weightUnit.rawValue,
                    reps: 0,
                    durationSeconds: nil,
                    isWarmup: false,
                    completedAt: nil,
                    sessionExercise: sessionExercise
                )
            } else {
                set = SetLog(
                    setNumber: index + 1,
                    weight: prior.map { $0.unit.convert($0.weight, to: weightUnit) } ?? 0,
                    weightUnit: weightUnit.rawValue,
                    reps: prior?.reps ?? sessionExercise.plannedRepsMin,
                    isWarmup: false,
                    completedAt: nil,
                    sessionExercise: sessionExercise
                )
            }
            context.insert(set)
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
        guard let exercise else { return nil }
        if exercise.isCardio {
            guard let last = sets.first(where: { $0.hasLoggedDuration }) else { return nil }
            return "Last: \(CardioFormat.minutesLabel(last.durationSeconds ?? 0))"
        }
        guard let best = sets.max(by: { $0.weight < $1.weight }) ?? sets.first else { return nil }
        let weight = best.unit.convert(best.weight, to: unit)
        return String(format: "Last: %.0f %@ × %d", weight, unit.abbreviation, best.reps)
    }

    private func countNewPRs(session: WorkoutSession, context: ModelContext) -> Int {
        var count = 0
        for se in session.orderedExercises {
            guard let exercise = se.exercise, !exercise.isCardio else { continue }
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
