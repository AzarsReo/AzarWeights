import SwiftUI
import SwiftData

/// First-launch flow: pick a split, preview days, assign weekdays, land on Home.
struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSplit.name) private var splits: [WorkoutSplit]
    @AppStorage(SettingsKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false

    @State private var step = 0
    @State private var selectedSplit: WorkoutSplit?
    /// templateID → weekday (1…7)
    @State private var weekdayAssignments: [UUID: Int] = [:]

    private let weekdaySymbols = Calendar.current.veryShortWeekdaySymbols

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case 0:
                    welcomeStep
                case 1:
                    splitPickerStep
                default:
                    dayAssignmentStep
                }
            }
            .background(GymTheme.background.ignoresSafeArea())
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 64))
                .foregroundStyle(GymTheme.accent)
            Text("Fitness Tracker")
                .font(.largeTitle.bold())
            Text("Pick a split, log sets at the gym, and track progress — all offline.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Button {
                withAnimation { step = 1 }
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(GymTheme.accent)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    private var splitPickerStep: some View {
        VStack(spacing: 0) {
            Text("Choose your split")
                .font(.title2.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)

            Text("You can change this later in Workouts.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

            List(splits, id: \.id) { split in
                Button {
                    selectedSplit = split
                    seedDefaultAssignments(for: split)
                    withAnimation { step = 2 }
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(split.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(split.splitDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                        Text("\(split.daysPerWeek) days / week · \(split.orderedTemplates.count) workouts")
                            .font(.caption)
                            .foregroundStyle(GymTheme.accent)
                    }
                    .padding(.vertical, 6)
                }
                .listRowBackground(GymTheme.card)
            }
            .scrollContentBackground(.hidden)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back") { withAnimation { step = 0 } }
            }
        }
    }

    private var dayAssignmentStep: some View {
        VStack(spacing: 0) {
            if let split = selectedSplit {
                Text(split.name)
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                Text("Assign training days (optional). Leave blank to keep flexible.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                List {
                    ForEach(split.orderedTemplates, id: \.id) { template in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(template.name)
                                .font(.headline)
                            Text(exercisePreview(template))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    dayChip(title: "—", selected: weekdayAssignments[template.id] == nil) {
                                        weekdayAssignments[template.id] = nil
                                    }
                                    ForEach(1...7, id: \.self) { weekday in
                                        dayChip(
                                            title: weekdaySymbols[weekday - 1],
                                            selected: weekdayAssignments[template.id] == weekday
                                        ) {
                                            weekdayAssignments[template.id] = weekday
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .listRowBackground(GymTheme.card)
                    }
                }
                .scrollContentBackground(.hidden)

                Button {
                    finish(split: split)
                } label: {
                    Text("Start Training")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .tint(GymTheme.accent)
                .padding(20)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back") { withAnimation { step = 1 } }
            }
        }
    }

    private func dayChip(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .frame(minWidth: 40, minHeight: 40)
                .background(selected ? GymTheme.accent : GymTheme.cardElevated, in: RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(selected ? .black : .primary)
        }
        .buttonStyle(.plain)
    }

    private func exercisePreview(_ template: WorkoutTemplate) -> String {
        let names = template.orderedExercises.prefix(4).compactMap { $0.exercise?.name }
        if names.isEmpty { return "No exercises yet" }
        let suffix = template.orderedExercises.count > 4 ? "…" : ""
        return names.joined(separator: " · ") + suffix
    }

    /// Default Mon–style mapping for common splits so Home has a today workout.
    private func seedDefaultAssignments(for split: WorkoutSplit) {
        weekdayAssignments.removeAll()
        // Prefer Mon=2 … Sat=7, then Sunday=1 if needed.
        let preferred = [2, 3, 4, 5, 6, 7, 1]
        for (index, template) in split.orderedTemplates.enumerated() {
            if index < preferred.count {
                weekdayAssignments[template.id] = preferred[index]
            }
        }
    }

    private func finish(split: WorkoutSplit) {
        for other in splits {
            other.isActive = false
        }
        split.isActive = true
        for template in split.templates {
            if let weekday = weekdayAssignments[template.id] {
                template.assignedWeekdays = [weekday]
            } else {
                template.assignedWeekdays = []
            }
        }
        try? modelContext.save()
        hasCompletedOnboarding = true
    }
}

#Preview {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Schema(FitnessTrackerSchema.allTypes),
        configurations: configuration
    )
    return OnboardingView()
        .modelContainer(container)
        .preferredColorScheme(.dark)
}
