import SwiftUI
import SwiftData

/// Pick (or change) the active workout split.
struct SplitPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WorkoutSplit.name) private var splits: [WorkoutSplit]

    @State private var selected: WorkoutSplit?
    @State private var weekdayAssignments: [UUID: Int] = [:]

    private let weekdaySymbols = Calendar.current.veryShortWeekdaySymbols

    var body: some View {
        List {
            ForEach(splits, id: \.id) { split in
                Section {
                    Button {
                        withAnimation {
                            selected = split
                            seedDefaults(for: split)
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(split.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(split.splitDescription)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(split.daysPerWeek) days / week")
                                    .font(.caption)
                                    .foregroundStyle(GymTheme.accent)
                            }
                            Spacer()
                            if split.isActive || selected?.id == split.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(GymTheme.accent)
                            }
                        }
                    }
                    .listRowBackground(GymTheme.card)

                    if selected?.id == split.id || (selected == nil && split.isActive) {
                        ForEach(split.orderedTemplates, id: \.id) { template in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(template.name)
                                    .font(.subheadline.weight(.semibold))
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        dayChip("—", selected: weekdayAssignments[template.id] == nil) {
                                            weekdayAssignments[template.id] = nil
                                        }
                                        ForEach(1...7, id: \.self) { day in
                                            dayChip(
                                                weekdaySymbols[day - 1],
                                                selected: weekdayAssignments[template.id] == day
                                            ) {
                                                weekdayAssignments[template.id] = day
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(GymTheme.cardElevated)
                            .onAppear {
                                if weekdayAssignments[template.id] == nil,
                                   let existing = template.assignedWeekdays.first {
                                    weekdayAssignments[template.id] = existing
                                }
                            }
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(GymTheme.background.ignoresSafeArea())
        .navigationTitle("Workout Split")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    applySelection()
                    dismiss()
                }
                .disabled(selected == nil && activeSplit == nil)
                .fontWeight(.semibold)
            }
        }
        .onAppear {
            selected = splits.first(where: \.isActive)
            if let selected {
                seedDefaults(for: selected, preferExisting: true)
            }
        }
    }

    private var activeSplit: WorkoutSplit? { splits.first(where: \.isActive) }

    private func dayChip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .frame(minWidth: 36, minHeight: 36)
                .background(selected ? GymTheme.accent : GymTheme.card, in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(selected ? .black : .primary)
        }
        .buttonStyle(.plain)
    }

    private func seedDefaults(for split: WorkoutSplit, preferExisting: Bool = false) {
        let preferred = [2, 3, 4, 5, 6, 7, 1]
        for (index, template) in split.orderedTemplates.enumerated() {
            if preferExisting, let existing = template.assignedWeekdays.first {
                weekdayAssignments[template.id] = existing
            } else if weekdayAssignments[template.id] == nil, index < preferred.count {
                weekdayAssignments[template.id] = preferred[index]
            }
        }
    }

    private func applySelection() {
        let target = selected ?? activeSplit
        guard let target else { return }
        for split in splits {
            split.isActive = (split.id == target.id)
        }
        for template in target.templates {
            if let day = weekdayAssignments[template.id] {
                template.assignedWeekdays = [day]
            } else {
                template.assignedWeekdays = []
            }
        }
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        SplitPickerView()
    }
    .preferredColorScheme(.dark)
}
