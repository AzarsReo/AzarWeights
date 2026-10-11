import SwiftUI
import SwiftData

/// Form for creating a personal (user-defined) exercise that joins the library.
struct ExerciseEditorSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// Called with the freshly created exercise after it is saved (e.g. to auto-select it).
    var onCreate: ((Exercise) -> Void)?

    @State private var name = ""
    @State private var muscleGroup: MuscleGroup = .chest
    @State private var equipment: EquipmentType = .barbell
    @State private var movementPattern: MovementPattern = .push

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Exercise name", text: $name)
                }

                Section {
                    Picker("Muscle Group", selection: $muscleGroup) {
                        ForEach(MuscleGroup.allCases) { group in
                            Text(group.rawValue).tag(group)
                        }
                    }
                    Picker("Equipment", selection: $equipment) {
                        ForEach(EquipmentType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    Picker("Movement", selection: $movementPattern) {
                        ForEach(MovementPattern.allCases) { pattern in
                            Text(pattern.displayName).tag(pattern)
                        }
                    }
                } header: {
                    Text("Details")
                } footer: {
                    Text("Cardio movements are logged by duration instead of weight and reps.")
                }
            }
            .navigationTitle("New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(trimmedName.isEmpty)
                }
            }
            .azarArcWatermark()
        }
    }

    private func save() {
        let exercise = Exercise(
            name: trimmedName,
            muscleGroup: muscleGroup.rawValue,
            equipment: equipment.rawValue,
            movementPattern: movementPattern.rawValue,
            isCustom: true
        )
        modelContext.insert(exercise)
        try? modelContext.save()
        onCreate?(exercise)
        dismiss()
    }
}
