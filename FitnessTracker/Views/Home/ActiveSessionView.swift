import SwiftUI
import SwiftData

/// Check-in → log sets/reps/weight → check-out.
struct ActiveSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage(SettingsKeys.weightUnit) private var weightUnitRaw = WeightUnit.lbs.rawValue

    @Bindable var viewModel: SessionViewModel
    @State private var expandedExerciseID: UUID?

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
                ToolbarItem(placement: .confirmationAction) {
                    Button("Finish") {
                        viewModel.checkOut(context: modelContext)
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(GymTheme.accent)
                }
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
                    Text(String(format: "%.0f %@", session.totalVolume, weightUnit.abbreviation))
                        .foregroundStyle(.secondary)
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
                            Text("\(sessionExercise.plannedSets)×\(sessionExercise.plannedRepsMin)–\(sessionExercise.plannedRepsMax)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
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
                ForEach(sessionExercise.orderedSets, id: \.id) { set in
                    setRow(set, sessionExercise: sessionExercise)
                        .listRowBackground(GymTheme.cardElevated)
                }

                Button {
                    viewModel.addSet(to: sessionExercise, weightUnit: weightUnit)
                } label: {
                    Label("Add Set", systemImage: "plus.circle.fill")
                        .foregroundStyle(GymTheme.accent)
                }
                .listRowBackground(GymTheme.card)
            }
        }
    }

    private func setRow(_ set: SetLog, sessionExercise: SessionExercise) -> some View {
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

            if let ghost {
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
                    HStack {
                        Button {
                            set.weight = max(0, set.weight - weightStep)
                            set.weightUnit = weightUnit.rawValue
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                        }
                        .buttonStyle(.plain)

                        Text(String(format: "%.0f", set.weight))
                            .font(.title3.monospacedDigit().weight(.semibold))
                            .frame(minWidth: 48)

                        Button {
                            set.weight += weightStep
                            set.weightUnit = weightUnit.rawValue
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                        }
                        .buttonStyle(.plain)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Reps")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    HStack {
                        Button {
                            set.reps = max(0, set.reps - 1)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                        }
                        .buttonStyle(.plain)

                        Text("\(set.reps)")
                            .font(.title3.monospacedDigit().weight(.semibold))
                            .frame(minWidth: 36)

                        Button {
                            set.reps += 1
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                        }
                        .buttonStyle(.plain)
                    }
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
                viewModel.removeSet(set, from: sessionExercise)
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }

    private var weightStep: Double {
        weightUnit == .kg ? 2.5 : 5
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
                summaryRow(
                    "Volume",
                    String(format: "%.0f %@", viewModel.summaryVolume, weightUnit.abbreviation)
                )
                summaryRow("PRs", "\(viewModel.summaryPRCount)")
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(GymTheme.card, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 24)

            Spacer()

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

#Preview {
    NavigationStack {
        ActiveSessionView(session: WorkoutSession(), viewModel: SessionViewModel())
    }
    .preferredColorScheme(.dark)
}
