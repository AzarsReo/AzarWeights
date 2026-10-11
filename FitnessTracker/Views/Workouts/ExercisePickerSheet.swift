import SwiftUI
import SwiftData

/// Searchable exercise library picker (swap mid-session, template builder, etc.).
struct ExercisePickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Exercise.name) private var allExercises: [Exercise]
    @State private var showingNewExercise = false

    var title: String = "Choose Exercise"
    var excludingExerciseID: UUID?
    /// Pre-selects the muscle filter (e.g. when swapping for a similar movement).
    var initialMuscleFilter: MuscleGroup?
    var onSelect: (Exercise) -> Void

    @State private var searchText = ""
    @State private var muscleFilter: MuscleGroup?

    var body: some View {
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
                        onSelect(exercise)
                        dismiss()
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
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewExercise = true
                    } label: {
                        Label("New Exercise", systemImage: "plus")
                    }
                }
            }
            .azarArcWatermark()
            .sheet(isPresented: $showingNewExercise) {
                // Editor only creates + saves and dismisses itself. The new exercise
                // then appears in this list (via @Query) for the user to tap — avoids
                // dismissing this picker while the editor sheet is still presented.
                ExerciseEditorSheet()
            }
        }
        .onAppear {
            if muscleFilter == nil {
                muscleFilter = initialMuscleFilter
            }
        }
    }

    private var filteredExercises: [Exercise] {
        allExercises.filter { exercise in
            if let excludingExerciseID, exercise.id == excludingExerciseID {
                return false
            }
            if let muscleFilter, exercise.muscleGroup != muscleFilter.rawValue {
                return false
            }
            if searchText.isEmpty { return true }
            let q = searchText.lowercased()
            if exercise.name.lowercased().contains(q) { return true }
            return exercise.aliases.contains { $0.lowercased().contains(q) }
        }
    }
}
