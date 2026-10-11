import SwiftUI
import SwiftData

/// Build a personal workout split: a named program with an ordered list of day
/// workouts, each holding its own exercises. Saves a user `WorkoutSplit`
/// (`isPreset == false`) with child `WorkoutTemplate` days.
struct SplitBuilderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Exercise.name) private var allExercises: [Exercise]

    @State private var name = ""
    @State private var splitDescription = ""
    @State private var days: [DraftDay] = []

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !trimmedName.isEmpty
            && !days.isEmpty
            && days.allSatisfy { !$0.exercises.isEmpty }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Split name (e.g. Push/Pull/Legs)", text: $name)
                        .font(.headline)
                    TextField("Description (optional)", text: $splitDescription)
                }
                .listRowBackground(GymTheme.card)

                Section("Days") {
                    ForEach($days) { $day in
                        NavigationLink {
                            SplitDayBuilderView(day: $day)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(day.name.isEmpty ? "Untitled Day" : day.name)
                                    .font(.headline)
                                Text(day.exercises.isEmpty
                                     ? "No exercises yet"
                                     : "\(day.exercises.count) exercises")
                                    .font(.caption)
                                    .foregroundStyle(day.exercises.isEmpty ? GymTheme.warning : .secondary)
                            }
                        }
                        .listRowBackground(GymTheme.card)
                    }
                    .onMove { indices, destination in
                        days.move(fromOffsets: indices, toOffset: destination)
                    }
                    .onDelete { indices in
                        days.remove(atOffsets: indices)
                    }

                    Button {
                        days.append(DraftDay(name: "Day \(days.count + 1)", exercises: []))
                    } label: {
                        Label("Add Day", systemImage: "plus.circle.fill")
                            .foregroundStyle(GymTheme.accent)
                    }
                    .listRowBackground(GymTheme.card)
                }
            }
            .scrollContentBackground(.hidden)
            .background(GymTheme.background.ignoresSafeArea())
            .navigationTitle("New Split")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItemGroup(placement: .confirmationAction) {
                    if !days.isEmpty {
                        EditButton()
                    }
                    Button("Save") { save() }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
            .azarArcWatermark()
        }
    }

    private func save() {
        guard canSave else { return }

        let split = WorkoutSplit(
            name: trimmedName,
            splitDescription: splitDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            daysPerWeek: days.count,
            isPreset: false
        )
        modelContext.insert(split)

        for (dayIndex, day) in days.enumerated() {
            let template = WorkoutTemplate(
                name: day.name.trimmingCharacters(in: .whitespacesAndNewlines),
                isCustom: false,
                isPreset: false,
                isStarterTemplate: false,
                dayIndex: dayIndex,
                split: split
            )
            modelContext.insert(template)

            for (order, draft) in day.exercises.enumerated() {
                let exercise = allExercises.first { $0.id == draft.exerciseID }
                let sets = draft.isCardio ? 1 : draft.targetSets
                let minReps = draft.isCardio ? 0 : min(draft.targetRepsMin, draft.targetRepsMax)
                let maxReps = draft.isCardio ? 0 : max(draft.targetRepsMin, draft.targetRepsMax)
                let te = TemplateExercise(
                    order: order,
                    targetSets: sets,
                    targetRepsMin: minReps,
                    targetRepsMax: maxReps,
                    template: template,
                    exercise: exercise
                )
                modelContext.insert(te)
            }
        }

        try? modelContext.save()
        dismiss()
    }
}

/// A single day within a draft split, before it is persisted as a `WorkoutTemplate`.
struct DraftDay: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var exercises: [DraftExercise]
}

/// Edit one day of a split: its name and its exercises (sets / rep range).
struct SplitDayBuilderView: View {
    @Binding var day: DraftDay

    @State private var showExercisePicker = false

    var body: some View {
        List {
            Section {
                TextField("Day name (e.g. Push)", text: $day.name)
                    .font(.headline)
            }
            .listRowBackground(GymTheme.card)

            Section("Exercises") {
                ForEach($day.exercises) { $draft in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(draft.exerciseName)
                            .font(.headline)
                        Text(draft.muscleGroup)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if draft.isCardio {
                            Text("Duration is entered during the workout.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            HStack(spacing: 16) {
                                stepperField("Sets", value: $draft.targetSets, range: 1...10)
                                stepperField("Min reps", value: $draft.targetRepsMin, range: 1...30)
                                stepperField("Max reps", value: $draft.targetRepsMax, range: 1...30)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                    .listRowBackground(GymTheme.card)
                }
                .onMove { indices, destination in
                    day.exercises.move(fromOffsets: indices, toOffset: destination)
                }
                .onDelete { indices in
                    day.exercises.remove(atOffsets: indices)
                }

                Button {
                    showExercisePicker = true
                } label: {
                    Label("Add Exercise", systemImage: "plus.circle.fill")
                        .foregroundStyle(GymTheme.accent)
                }
                .listRowBackground(GymTheme.card)
            }
        }
        .environment(\.editMode, .constant(.active))
        .scrollContentBackground(.hidden)
        .background(GymTheme.background.ignoresSafeArea())
        .navigationTitle(day.name.isEmpty ? "Day" : day.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showExercisePicker) {
            ExercisePickerSheet(title: "Add Exercise") { exercise in
                day.exercises.append(
                    DraftExercise(
                        exerciseID: exercise.id,
                        exerciseName: exercise.name,
                        muscleGroup: exercise.muscleGroup,
                        isCardio: exercise.isCardio,
                        targetSets: exercise.isCardio ? 1 : 3,
                        targetRepsMin: exercise.isCardio ? 0 : 8,
                        targetRepsMax: exercise.isCardio ? 0 : 12
                    )
                )
            }
        }
    }

    private func stepperField(_ title: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                Button {
                    value.wrappedValue = max(range.lowerBound, value.wrappedValue - 1)
                } label: {
                    Image(systemName: "minus.circle.fill")
                }
                .buttonStyle(.plain)
                Text("\(value.wrappedValue)")
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .frame(minWidth: 20)
                Button {
                    value.wrappedValue = min(range.upperBound, value.wrappedValue + 1)
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .buttonStyle(.plain)
            }
        }
    }
}
