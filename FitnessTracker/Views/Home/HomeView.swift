import SwiftUI
import SwiftData

/// Today's workout, streak, and Start / Resume session.
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<WorkoutSplit> { $0.isActive == true })
    private var activeSplits: [WorkoutSplit]
    @Query(sort: \WorkoutSession.checkedInAt, order: .reverse)
    private var sessions: [WorkoutSession]
    @Query(filter: #Predicate<WorkoutTemplate> { $0.isCustom == true }, sort: \WorkoutTemplate.name)
    private var customTemplates: [WorkoutTemplate]

    @AppStorage(SettingsKeys.weightUnit) private var weightUnitRaw = WeightUnit.lbs.rawValue
    @State private var showingSettings = false
    @State private var navigateToSession = false
    @State private var sessionVM = SessionViewModel()
    @State private var showingTemplatePicker = false

    private var weightUnit: WeightUnit { WeightUnit(rawValue: weightUnitRaw) ?? .lbs }
    private var activeSplit: WorkoutSplit? { activeSplits.first }
    private var inProgressSession: WorkoutSession? {
        sessions.first { $0.status == .inProgress }
    }

    private var todaysTemplate: WorkoutTemplate? {
        guard let split = activeSplit else { return nil }
        let weekday = Calendar.current.component(.weekday, from: .now)
        if let assigned = split.orderedTemplates.first(where: { $0.assignedWeekdays.contains(weekday) }) {
            return assigned
        }
        // Fallback: rotate by day-of-year when no weekday assignments.
        let templates = split.orderedTemplates
        guard !templates.isEmpty else { return nil }
        let dayIndex = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 1
        return templates[(dayIndex - 1) % templates.count]
    }

    private var completedThisWeek: Int {
        let bounds = ProgressCalculator.weekBounds()
        return sessions.filter {
            $0.status == .completed
            && $0.checkedInAt >= bounds.start
            && $0.checkedInAt < bounds.end
        }.count
    }

    private var streak: Int {
        let calendar = Calendar.current
        let completedDays = Set(
            sessions
                .filter { $0.status == .completed }
                .map { calendar.startOfDay(for: $0.checkedInAt) }
        )
        var count = 0
        var day = calendar.startOfDay(for: .now)
        // If nothing today, start from yesterday so mid-day streak still counts.
        if !completedDays.contains(day) {
            day = calendar.date(byAdding: .day, value: -1, to: day) ?? day
        }
        while completedDays.contains(day) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    statsRow
                    todayCard
                    if let inProgress = inProgressSession {
                        resumeBanner(inProgress)
                    }
                }
                .padding(20)
            }
            .background(GymTheme.background.ignoresSafeArea())
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showingSettings) {
                NavigationStack {
                    SettingsView()
                }
            }
            .sheet(isPresented: $showingTemplatePicker) {
                templatePicker
            }
            .navigationDestination(isPresented: $navigateToSession) {
                if let session = sessionVM.session {
                    ActiveSessionView(session: session, viewModel: sessionVM)
                }
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(title: "Streak", value: "\(streak)", subtitle: "days")
            statCard(title: "This Week", value: "\(completedThisWeek)", subtitle: "workouts")
        }
    }

    private func statCard(title: String, value: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(GymTheme.accent)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(GymTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    private var todayCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(activeSplit?.name ?? "No active split")
                .font(.caption.weight(.semibold))
                .foregroundStyle(GymTheme.accent)
                .textCase(.uppercase)

            if let template = todaysTemplate {
                Text(template.name)
                    .font(.title.bold())
                Text(exerciseList(template))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button {
                    start(template: template)
                } label: {
                    Label(
                        inProgressSession != nil ? "Start New Workout" : "Start Workout",
                        systemImage: "play.fill"
                    )
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                }
                .buttonStyle(.borderedProminent)
                .tint(GymTheme.accent)
                .disabled(inProgressSession != nil)
            } else {
                Text("Rest Day")
                    .font(.title.bold())
                Text("No workout scheduled for today. Pick a custom workout or browse Workouts.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button {
                    showingTemplatePicker = true
                } label: {
                    Label("Choose a Workout", systemImage: "list.bullet")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                }
                .buttonStyle(.borderedProminent)
                .tint(GymTheme.accent)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GymTheme.card, in: RoundedRectangle(cornerRadius: 20))
    }

    private func resumeBanner(_ session: WorkoutSession) -> some View {
        Button {
            sessionVM.resume(session)
            navigateToSession = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Workout in progress")
                        .font(.headline)
                    Text(session.template?.name ?? "Session")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(DurationFormat.string(from: Date().timeIntervalSince(session.checkedInAt)) + " elapsed")
                        .font(.caption)
                        .foregroundStyle(GymTheme.info)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(18)
            .background(GymTheme.cardElevated, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var templatePicker: some View {
        NavigationStack {
            List {
                if let split = activeSplit {
                    Section("Split days") {
                        ForEach(split.orderedTemplates, id: \.id) { template in
                            Button(template.name) {
                                showingTemplatePicker = false
                                start(template: template)
                            }
                        }
                    }
                }
                if !customTemplates.isEmpty {
                    Section("My Workouts") {
                        ForEach(customTemplates, id: \.id) { template in
                            Button(template.name) {
                                showingTemplatePicker = false
                                start(template: template)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Start Workout")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingTemplatePicker = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func exerciseList(_ template: WorkoutTemplate) -> String {
        let names = template.orderedExercises.prefix(5).compactMap { $0.exercise?.name }
        guard !names.isEmpty else { return "\(template.orderedExercises.count) exercises" }
        let more = template.orderedExercises.count > 5 ? " +\(template.orderedExercises.count - 5)" : ""
        return names.joined(separator: " · ") + more
    }

    private func start(template: WorkoutTemplate) {
        sessionVM.checkIn(template: template, context: modelContext, weightUnit: weightUnit)
        navigateToSession = true
    }
}

#Preview {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Schema(FitnessTrackerSchema.allTypes),
        configurations: configuration
    )
    return HomeView()
        .modelContainer(container)
        .preferredColorScheme(.dark)
}
