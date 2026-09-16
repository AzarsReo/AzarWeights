import SwiftUI
import SwiftData

/// Sheet for a single calendar day.
struct DayDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage(SettingsKeys.weightUnit) private var weightUnitRaw = WeightUnit.lbs.rawValue

    var date: Date = .now
    var sessions: [WorkoutSession] = []
    var customTemplates: [WorkoutTemplate] = []
    var splitTemplates: [WorkoutTemplate] = []

    @State private var sessionVM = SessionViewModel()
    @State private var showStartPicker = false

    private var weightUnit: WeightUnit { WeightUnit(rawValue: weightUnitRaw) ?? .lbs }

    var body: some View {
        Group {
            if sessions.isEmpty {
                emptyDay
            } else {
                sessionList
            }
        }
        .background(GymTheme.background.ignoresSafeArea())
        .navigationTitle(date.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
        .sheet(isPresented: $showStartPicker) {
            NavigationStack {
                List {
                    if !splitTemplates.isEmpty {
                        Section("Split days") {
                            ForEach(splitTemplates, id: \.id) { template in
                                Button(template.name) {
                                    logPast(template: template)
                                }
                            }
                        }
                    }
                    if !customTemplates.isEmpty {
                        Section("My Workouts") {
                            ForEach(customTemplates, id: \.id) { template in
                                Button(template.name) {
                                    logPast(template: template)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Log Workout")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showStartPicker = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private var emptyDay: some View {
        VStack(spacing: 20) {
            ContentUnavailableView(
                "No Session",
                systemImage: "moon.zzz",
                description: Text("Log a past workout or mark this as a rest day.")
            )
            Button {
                showStartPicker = true
            } label: {
                Label("Log Past Workout", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(GymTheme.accent)
            .padding(.horizontal, 24)

            Button {
                markRest()
            } label: {
                Text("Mark Rest Day")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.bordered)
            .padding(.horizontal, 24)
            Spacer()
        }
    }

    private var sessionList: some View {
        List {
            ForEach(sessions, id: \.id) { session in
                Section {
                    HStack {
                        Text(session.template?.name ?? "Workout")
                            .font(.headline)
                        Spacer()
                        Text(session.status.displayName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(GymTheme.sessionMarker(session.status))
                    }
                    if let duration = session.duration {
                        labeled("Duration", DurationFormat.string(from: duration))
                    } else if session.status == .inProgress {
                        labeled("Started", session.checkedInAt.formatted(date: .omitted, time: .shortened))
                    }
                    labeled(
                        "Volume",
                        String(format: "%.0f %@", session.totalVolume, weightUnit.abbreviation)
                    )

                    ForEach(session.orderedExercises, id: \.id) { se in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(se.exercise?.name ?? "Exercise")
                                .font(.subheadline.weight(.semibold))
                            ForEach(se.orderedSets, id: \.id) { set in
                                Text(
                                    String(
                                        format: "Set %d · %.0f %@ × %d",
                                        set.setNumber,
                                        set.unit.convert(set.weight, to: weightUnit),
                                        weightUnit.abbreviation,
                                        set.reps
                                    )
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .listRowBackground(GymTheme.card)
            }
        }
        .scrollContentBackground(.hidden)
    }

    private func labeled(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.subheadline.monospacedDigit())
        }
    }

    private func markRest() {
        let session = WorkoutSession(
            checkedInAt: date,
            checkedOutAt: date,
            status: .skipped,
            notes: "Rest day"
        )
        modelContext.insert(session)
        try? modelContext.save()
        dismiss()
    }

    private func logPast(template: WorkoutTemplate) {
        showStartPicker = false
        sessionVM.checkIn(template: template, context: modelContext, weightUnit: weightUnit, now: date)
        if let session = sessionVM.session {
            session.checkedOutAt = date.addingTimeInterval(3600)
            session.status = .completed
            try? modelContext.save()
        }
        dismiss()
    }
}

#Preview {
    NavigationStack {
        DayDetailView()
    }
    .preferredColorScheme(.dark)
}
