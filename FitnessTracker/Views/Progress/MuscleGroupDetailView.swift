import SwiftUI

/// Aggregated progress for every lift targeting one `MuscleGroup`.
struct MuscleGroupDetailView: View {
    var muscleGroup: MuscleGroup = .chest
    var viewModel: ProgressViewModel

    @AppStorage(SettingsKeys.weightUnit) private var weightUnitRaw = WeightUnit.lbs.rawValue

    private var weightUnit: WeightUnit { WeightUnit(rawValue: weightUnitRaw) ?? .lbs }
    private var lifts: [ProgressViewModel.LiftRow] { viewModel.lifts(for: muscleGroup) }

    private var groupPlateau: Bool {
        lifts.filter { $0.status == .plateauing || $0.status == .confirmedPlateau }.count >= 2
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                summaryHeader

                if groupPlateau {
                    PlateauAlertCard(
                        status: .plateauing,
                        message: "\(muscleGroup.rawValue) progress stalling — multiple lifts are flat.",
                        suggestion: PlateauDetectionService.suggestion(for: .plateauing)
                    )
                }

                if lifts.isEmpty {
                    ContentUnavailableView(
                        "No lifts yet",
                        systemImage: "dumbbell",
                        description: Text("Train \(muscleGroup.rawValue.lowercased()) exercises to see progress here.")
                    )
                } else {
                    ForEach(lifts) { row in
                        NavigationLink {
                            LiftDetailView(exercise: row.exercise)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(row.exercise.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text("\(row.sessionCount) sessions · e1RM \(String(format: "%.0f %@", row.lastE1RM, weightUnit.abbreviation))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                ProgressStatusBadge(status: row.status)
                            }
                            .padding(14)
                            .background(GymTheme.card, in: RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
        }
        .background(GymTheme.background.ignoresSafeArea())
        .navigationTitle(muscleGroup.rawValue)
    }

    private var summaryHeader: some View {
        let volume = viewModel.muscleVolumes[muscleGroup] ?? 0
        let status = viewModel.muscleStatuses[muscleGroup] ?? .insufficientData
        return VStack(alignment: .leading, spacing: 10) {
            ProgressStatusBadge(status: status)
            Text(String(format: "%.0f %@ volume this week", volume, weightUnit.abbreviation))
                .font(.title3.bold())
            Text("\(lifts.count) tracked lifts")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GymTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    NavigationStack {
        MuscleGroupDetailView(viewModel: ProgressViewModel())
    }
    .preferredColorScheme(.dark)
}
