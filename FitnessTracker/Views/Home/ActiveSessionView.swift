import SwiftUI
import SwiftData

/// Check-in → log sets/reps/weight (or cardio duration) → check-out.
struct ActiveSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage(SettingsKeys.weightUnit) private var weightUnitRaw = WeightUnit.lbs.rawValue

    @Bindable var viewModel: SessionViewModel
    @State private var expandedExerciseID: UUID?
    @State private var showDiscardConfirm = false
    @State private var swapTarget: SessionExercise?
    @State private var showSaveWorkoutAlert = false
    @State private var saveWorkoutName = ""

    private var weightUnit: WeightUnit { WeightUnit(rawValue: weightUnitRaw) ?? .lbs }

    init(session: WorkoutSession, viewModel: SessionViewModel) {
        self.viewModel = viewModel
        if viewModel.session?.id != session.id {
            viewModel.resume(session)
        }
    }

    var body: some View {
        Group {
            if viewModel.showSummary {
                summaryView
            } else if let session = viewModel.session {
                sessionContent(session)
            } else {
                ContentUnavailableView("No Session", systemImage: "exclamationmark.triangle")
            }
        }
        .background(GymTheme.background.ignoresSafeArea())
        .navigationTitle(viewModel.session?.template?.name ?? "Workout")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.showSummary)
        .toolbar {
            if !viewModel.showSummary {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard") {
                        showDiscardConfirm = true
                    }
                    .foregroundStyle(GymTheme.danger)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Finish") {
                        viewModel.checkOut(context: modelContext)
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(GymTheme.accent)
                }
            }
        }
        .confirmationDialog(
            "Discard this workout?",
            isPresented: $showDiscardConfirm,
            titleVisibility: .visible
        ) {
            Button("Discard Workout", role: .destructive) {
                viewModel.deleteSession(context: modelContext)
                dismiss()
            }
            Button("Keep Working", role: .cancel) {}
        } message: {
            Text("All logged sets for this session will be permanently deleted.")
        }
        .sheet(item: $swapTarget) { target in
            ExercisePickerSheet(
                title: "Swap Exercise",
                excludingExerciseID: target.exercise?.id
            ) { newExercise in
                viewModel.swapExercise(
                    target,
                    to: newExercise,
                    context: modelContext,
                    weightUnit: weightUnit
                )
            }
        }
    }

    private func sessionContent(_ session: WorkoutSession) -> some View {
        List {
            Section {
                HStack {
                    Label(
                        DurationFormat.string(from: Date().timeIntervalSince(session.checkedInAt)),
                        systemImage: "timer"
                    )
                    Spacer()
                    if session.totalVolume > 0 {
                        Text(String(format: "%.0f %@", session.totalVolume, weightUnit.abbreviation))
                            .foregroundStyle(.secondary)
                    } else if session.totalCardioSeconds > 0 {
                        Text(CardioFormat.minutesLabel(session.totalCardioSeconds))
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.subheadline)
                .listRowBackground(GymTheme.card)
            }

            ForEach(session.orderedExercises, id: \.id) { exercise in
                exerciseSection(exercise)
            }
        }
        .scrollContentBackground(.hidden)
    }

    private func exerciseSection(_ sessionExercise: SessionExercise) -> some View {
        let isExpanded = expandedExerciseID == sessionExercise.id
        let isCardio = sessionExercise.isCardio
        let ghost = viewModel.previousGhostText(
            for: sessionExercise.exercise,
            context: modelContext,
            unit: weightUnit
        )

        return Section {
            Button {
                withAnimation {
                    expandedExerciseID = isExpanded ? nil : sessionExercise.id
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(sessionExercise.exercise?.name ?? "Exercise")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        HStack(spacing: 8) {
                            if isCardio {
                                Text("Enter duration when you log")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("\(sessionExercise.plannedSets)×\(sessionExercise.plannedRepsMin)–\(sessionExercise.plannedRepsMax)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if let ghost {
                                Text(ghost)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(GymTheme.card)

            if isExpanded {
                Button {
                    swapTarget = sessionExercise
                } label: {
                    Label("Swap Exercise", systemImage: "arrow.triangle.2.circlepath")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(GymTheme.info)
                }
                .listRowBackground(GymTheme.card)

                ForEach(sessionExercise.orderedSets, id: \.id) { set in
                    if isCardio {
                        cardioSetRow(set)
                            .listRowBackground(GymTheme.cardElevated)
                    } else {
                        strengthSetRow(set, sessionExercise: sessionExercise)
                            .listRowBackground(GymTheme.cardElevated)
                    }
                }

                if !isCardio {
                    Button {
                        viewModel.addSet(to: sessionExercise, weightUnit: weightUnit, context: modelContext)
                    } label: {
                        Label("Add Set", systemImage: "plus.circle.fill")
                            .foregroundStyle(GymTheme.accent)
                    }
                    .listRowBackground(GymTheme.card)
                }
            }
        }
    }

    private func cardioSetRow(_ set: SetLog) -> some View {
        @Bindable var set = set
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Duration")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if set.completedAt != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(GymTheme.accent)
                }
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Minutes")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    TextField(
                        "0",
                        value: Binding(
                            get: { set.durationMinutes },
                            set: { set.durationMinutes = $0 }
                        ),
                        format: .number
                    )
                        .keyboardType(.numberPad)
                        .font(.title3.monospacedDigit().weight(.semibold))
                        .multilineTextAlignment(.center)
                        .frame(width: 72)
                        .padding(.vertical, 8)
                        .background(GymTheme.card, in: RoundedRectangle(cornerRadius: 8))
                }

                Spacer()

                Button {
                    guard set.durationMinutes > 0 else { return }
                    viewModel.markSetComplete(set)
                } label: {
                    Text(set.completedAt == nil ? "Log" : "Done")
                        .font(.subheadline.weight(.bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            set.completedAt == nil ? GymTheme.accent : GymTheme.accent.opacity(0.3),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)
                .disabled(set.durationMinutes == 0 && set.completedAt == nil)
            }
        }
        .padding(.vertical, 6)
    }

    private func strengthSetRow(_ set: SetLog, sessionExercise: SessionExercise) -> some View {
        @Bindable var set = set
        let previous = viewModel.previousWorkingSets(for: sessionExercise.exercise, context: modelContext)
        let ghost = previous.first { $0.setNumber == set.setNumber }

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Set \(set.setNumber)")
                    .font(.subheadline.weight(.semibold))
                if set.isWarmup {
                    Text("W")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.3), in: Capsule())
                }
                Spacer()
                if set.completedAt != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(GymTheme.accent)
                }
            }

            if let ghost, !ghost.hasLoggedDuration {
                Text(
                    String(
                        format: "Prev  %.0f %@ × %d",
                        ghost.unit.convert(ghost.weight, to: weightUnit),
                        weightUnit.abbreviation,
                        ghost.reps
                    )
                )
                .font(.caption)
                .foregroundStyle(.tertiary)
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weight (\(weightUnit.abbreviation))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    TextField("0", value: $set.weight, format: .number)
                        .keyboardType(.decimalPad)
                        .font(.title3.monospacedDigit().weight(.semibold))
                        .multilineTextAlignment(.center)
                        .frame(width: 72)
                        .padding(.vertical, 8)
                        .background(GymTheme.card, in: RoundedRectangle(cornerRadius: 8))
                        .onChange(of: set.weight) { _, _ in
                            set.weightUnit = weightUnit.rawValue
                        }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Reps")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    TextField("0", value: $set.reps, format: .number)
                        .keyboardType(.numberPad)
                        .font(.title3.monospacedDigit().weight(.semibold))
                        .multilineTextAlignment(.center)
                        .frame(width: 56)
                        .padding(.vertical, 8)
                        .background(GymTheme.card, in: RoundedRectangle(cornerRadius: 8))
                }

                Spacer()

                Button {
                    viewModel.markSetComplete(set)
                } label: {
                    Text(set.completedAt == nil ? "Log" : "Done")
                        .font(.subheadline.weight(.bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            set.completedAt == nil ? GymTheme.accent : GymTheme.accent.opacity(0.3),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                viewModel.removeSet(set, from: sessionExercise, context: modelContext)
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }

    private var summaryView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(GymTheme.accent)
            Text("Workout Complete")
                .font(.largeTitle.bold())

            VStack(spacing: 12) {
                summaryRow("Duration", DurationFormat.string(from: viewModel.summaryDuration))
                if viewModel.summaryVolume > 0 {
                    summaryRow(
                        "Volume",
                        String(format: "%.0f %@", viewModel.summaryVolume, weightUnit.abbreviation)
                    )
                }
                if let session = viewModel.session, session.totalCardioSeconds > 0 {
                    summaryRow("Cardio", CardioFormat.minutesLabel(session.totalCardioSeconds))
                }
                summaryRow("PRs", "\(viewModel.summaryPRCount)")
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(GymTheme.card, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 24)

            if viewModel.shouldOfferSaveWorkout {
                if viewModel.workoutSaveCompleted {
                    Label("Saved to My Workouts", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(GymTheme.accent)
                        .padding(.horizontal, 24)
                } else {
                    Button {
                        saveWorkoutName = viewModel.suggestedWorkoutName
                        showSaveWorkoutAlert = true
                    } label: {
                        Label("Save for Later", systemImage: "square.and.arrow.down")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.bordered)
                    .tint(GymTheme.accent)
                    .padding(.horizontal, 24)
                }
            }

            Spacer(minLength: 0)

            Button {
                viewModel.showSummary = false
                viewModel.session = nil
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(GymTheme.accent)
            .padding(24)
        }
        .alert("Save Workout", isPresented: $showSaveWorkoutAlert) {
            TextField("Workout name", text: $saveWorkoutName)
            Button("Save") {
                viewModel.saveSessionAsTemplate(name: saveWorkoutName, context: modelContext)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Save this workout to My Workouts so you can run it again anytime.")
        }
    }

    private func summaryRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.headline.monospacedDigit())
        }
    }
}

extension SessionExercise: Identifiable {}

#Preview {
    NavigationStack {
        ActiveSessionView(session: WorkoutSession(), viewModel: SessionViewModel())
    }
    .preferredColorScheme(.dark)
}
