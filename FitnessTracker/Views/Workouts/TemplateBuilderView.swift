import SwiftUI
import SwiftData

/// Build or edit a custom `WorkoutTemplate`.
struct TemplateBuilderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var sourceTemplate: WorkoutTemplate?

    @Query(sort: \Exercise.name) private var allExercises: [Exercise]

    @State private var name: String = ""
    @State private var draftExercises: [DraftExercise] = []
    @State private var showExercisePicker = false
    @State private var searchText = ""
    @State private var muscleFilter: MuscleGroup?
    @State private var editingExistingID: UUID?

    private var isEditingCustom: Bool {
        sourceTemplate?.isCustom == true
    }

    var body: some View {
        List {
            Section {
                TextField("Workout name", text: $name)
                    .font(.headline)
            }
            .listRowBackground(GymTheme.card)

            Section("Exercises") {
                ForEach($draftExercises) { $draft in
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
                    draftExercises.move(fromOffsets: indices, toOffset: destination)
                }
                .onDelete { indices in
                    draftExercises.remove(atOffsets: indices)
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
        .navigationTitle(isEditingCustom ? "Edit Workout" : "New Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || draftExercises.isEmpty)
                    .fontWeight(.semibold)
            }
        }
        .sheet(isPresented: $showExercisePicker) {
            exercisePicker
        }
        .onAppear {
            bootstrapFromSource()
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

    private var exercisePicker: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Muscle", selection: $muscleFilter) {
                        Text("All").tag(Optional<MuscleGroup>.none)
                        ForEach(MuscleGroup.allCases) { group in
                            Text(group.rawValue).tag(Optional(group))
                        }
                    }
                }
                ForEach(filteredExercises, id: \.id) { exercise in
                    Button {
                        draftExercises.append(
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
                        showExercisePicker = false
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(exercise.name)
                                .foregroundStyle(.primary)
                            Text("\(exercise.muscleGroup) · \(exercise.equipment)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Add Exercise")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showExercisePicker = false }
                }
            }
        }
    }

    private var filteredExercises: [Exercise] {
        allExercises.filter { exercise in
            if let muscleFilter, exercise.muscleGroup != muscleFilter.rawValue {
                return false
            }
            if searchText.isEmpty { return true }
            let q = searchText.lowercased()
            if exercise.name.lowercased().contains(q) { return true }
            return exercise.aliases.contains { $0.lowercased().contains(q) }
        }
    }

    private func bootstrapFromSource() {
        guard draftExercises.isEmpty else { return }
        guard let source = sourceTemplate else {
            name = ""
            return
        }
        editingExistingID = source.isCustom ? source.id : nil
        name = source.isCustom ? source.name : "My \(source.name)"
        draftExercises = source.orderedExercises.compactMap { te in
            guard let exercise = te.exercise else { return nil }
            return DraftExercise(
                exerciseID: exercise.id,
                exerciseName: exercise.name,
                muscleGroup: exercise.muscleGroup,
                isCardio: exercise.isCardio,
                targetSets: te.targetSets,
                targetRepsMin: te.targetRepsMin,
                targetRepsMax: te.targetRepsMax
            )
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let template: WorkoutTemplate
        if let editingID = editingExistingID,
           let existing = sourceTemplate,
           existing.id == editingID,
           existing.isCustom {
            template = existing
            template.name = trimmed
            for old in template.exercises {
                modelContext.delete(old)
            }
            template.exercises = []
        } else {
            template = WorkoutTemplate(
                name: trimmed,
                isCustom: true,
                isPreset: false,
                isStarterTemplate: false,
                split: nil
            )
            modelContext.insert(template)
        }

        for (index, draft) in draftExercises.enumerated() {
            let exercise = allExercises.first { $0.id == draft.exerciseID }
            let sets = draft.isCardio ? 1 : draft.targetSets
            let minReps = draft.isCardio ? 0 : min(draft.targetRepsMin, draft.targetRepsMax)
            let maxReps = draft.isCardio ? 0 : max(draft.targetRepsMin, draft.targetRepsMax)
            let te = TemplateExercise(
                order: index,
                targetSets: sets,
                targetRepsMin: minReps,
                targetRepsMax: maxReps,
                template: template,
                exercise: exercise
            )
            modelContext.insert(te)
        }

        try? modelContext.save()
        dismiss()
    }
}

struct DraftExercise: Identifiable, Hashable {
    let id = UUID()
    var exerciseID: UUID
    var exerciseName: String
    var muscleGroup: String
    var isCardio: Bool
    var targetSets: Int
    var targetRepsMin: Int
    var targetRepsMax: Int
}

#Preview {
    NavigationStack {
        TemplateBuilderView()
    }
    .preferredColorScheme(.dark)
}
