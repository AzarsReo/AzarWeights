import SwiftUI
import SwiftData

/// Custom workouts (primary) + collapsible Starter Templates drawer (secondary).
struct WorkoutsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<WorkoutSplit> { $0.isActive == true })
    private var activeSplits: [WorkoutSplit]
    @Query(filter: #Predicate<WorkoutTemplate> { $0.isCustom == true }, sort: \WorkoutTemplate.createdAt, order: .reverse)
    private var customTemplates: [WorkoutTemplate]
    @Query(filter: #Predicate<WorkoutTemplate> { $0.isStarterTemplate == true }, sort: \WorkoutTemplate.name)
    private var starterTemplates: [WorkoutTemplate]

    @State private var showSplitPicker = false
    @State private var builderSource: WorkoutTemplate?
    @State private var showBuilder = false
    @State private var startersExpanded = false
    @State private var sessionVM = SessionViewModel()
    @State private var navigateToSession = false
    @AppStorage(SettingsKeys.weightUnit) private var weightUnitRaw = WeightUnit.lbs.rawValue

    private var weightUnit: WeightUnit { WeightUnit(rawValue: weightUnitRaw) ?? .lbs }
    private var activeSplit: WorkoutSplit? { activeSplits.first }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        activeSplitCard
                        myWorkoutsSection
                        Color.clear.frame(height: startersExpanded ? 280 : 72)
                    }
                    .padding(20)
                }

                StarterTemplatesDrawer(
                    templates: starterTemplates,
                    isExpanded: $startersExpanded,
                    onSelect: { starter in
                        builderSource = starter
                        showBuilder = true
                    }
                )
            }
            .background(GymTheme.background.ignoresSafeArea())
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        builderSource = nil
                        showBuilder = true
                    } label: {
                        Label("New Workout", systemImage: "plus")
                    }
                }
            }
            .navigationDestination(isPresented: $showSplitPicker) {
                SplitPickerView()
            }
            .navigationDestination(isPresented: $showBuilder) {
                TemplateBuilderView(sourceTemplate: builderSource)
            }
            .navigationDestination(isPresented: $navigateToSession) {
                if let session = sessionVM.session {
                    ActiveSessionView(session: session, viewModel: sessionVM)
                }
            }
        }
    }

    private var activeSplitCard: some View {
        Button {
            showSplitPicker = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Active Split")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(GymTheme.accent)
                        .textCase(.uppercase)
                    Text(activeSplit?.name ?? "None selected")
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                    if let split = activeSplit {
                        Text("\(split.daysPerWeek) days · tap to change")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(18)
            .background(GymTheme.card, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var myWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("My Workouts")
                    .font(.title3.bold())
                Spacer()
                Button {
                    builderSource = nil
                    showBuilder = true
                } label: {
                    Label("New", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(GymTheme.accent)
            }

            if customTemplates.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No custom workouts yet")
                        .font(.headline)
                    Text("Create one from scratch or pull a starter template from the drawer below.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(GymTheme.card, in: RoundedRectangle(cornerRadius: 16))
            } else {
                ForEach(customTemplates, id: \.id) { template in
                    workoutRow(template)
                }
            }
        }
    }

    private func workoutRow(_ template: WorkoutTemplate) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.headline)
                    Text("\(template.orderedExercises.count) exercises")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    sessionVM.checkIn(template: template, context: modelContext, weightUnit: weightUnit)
                    navigateToSession = true
                } label: {
                    Text("Start")
                        .font(.subheadline.weight(.bold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(GymTheme.accent, in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(GymTheme.card, in: RoundedRectangle(cornerRadius: 16))
        .contextMenu {
            Button {
                builderSource = template
                showBuilder = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive) {
                modelContext.delete(template)
                try? modelContext.save()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Schema(FitnessTrackerSchema.allTypes),
        configurations: configuration
    )
    return WorkoutsView()
        .modelContainer(container)
        .preferredColorScheme(.dark)
}
