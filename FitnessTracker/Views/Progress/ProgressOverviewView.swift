import SwiftUI
import SwiftData

private enum ProgressRoute: Hashable {
    case lift(UUID)
    case muscle(MuscleGroup)
}

/// Progress landing dashboard.
struct ProgressOverviewView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(SettingsKeys.weightUnit) private var weightUnitRaw = WeightUnit.lbs.rawValue
    @State private var viewModel = ProgressViewModel()
    @State private var path = NavigationPath()

    private var weightUnit: WeightUnit { WeightUnit(rawValue: weightUnitRaw) ?? .lbs }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    weeklySummaryStrip

                    if !viewModel.alerts.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Alerts")
                                .font(.headline)
                            ForEach(viewModel.alerts.prefix(5)) { alert in
                                Button {
                                    if let id = alert.exerciseID {
                                        path.append(ProgressRoute.lift(id))
                                    } else if let group = alert.muscleGroup {
                                        path.append(ProgressRoute.muscle(group))
                                    }
                                } label: {
                                    PlateauAlertCard(
                                        status: alert.status,
                                        message: alert.message,
                                        suggestion: alert.suggestion
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    MuscleHeatmapView(
                        volumes: viewModel.muscleVolumes,
                        statuses: viewModel.muscleStatuses
                    ) { group in
                        path.append(ProgressRoute.muscle(group))
                    }

                    liftsSection
                }
                .padding(20)
            }
            .background(GymTheme.background.ignoresSafeArea())
            .navigationTitle("Progress")
            .navigationDestination(for: ProgressRoute.self) { route in
                switch route {
                case .lift(let id):
                    if let exercise = viewModel.liftRows.first(where: { $0.id == id })?.exercise {
                        LiftDetailView(exercise: exercise)
                    } else {
                        ContentUnavailableView("Lift not found", systemImage: "questionmark")
                    }
                case .muscle(let group):
                    MuscleGroupDetailView(muscleGroup: group, viewModel: viewModel)
                }
            }
            .onAppear { refresh() }
            .onChange(of: weightUnitRaw) { _, _ in refresh() }
        }
    }

    private var weeklySummaryStrip: some View {
        let s = viewModel.weeklySummary
        return VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)
            HStack(spacing: 10) {
                summaryChip("Volume", String(format: "%.0f", s.totalVolume))
                summaryChip("Workouts", "\(s.workoutCount)")
                summaryChip("PRs", "\(s.prCount)")
            }
            HStack(spacing: 10) {
                summaryChip("Up", "\(s.trendingUp)", color: GymTheme.accent)
                summaryChip("Flat", "\(s.trendingFlat)", color: GymTheme.warning)
                summaryChip("Down", "\(s.trendingDown)", color: GymTheme.danger)
            }
        }
        .padding(16)
        .background(GymTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    private func summaryChip(_ title: String, _ value: String, color: Color = .primary) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(color)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(GymTheme.cardElevated, in: RoundedRectangle(cornerRadius: 10))
    }

    private var liftsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Lifts")
                .font(.headline)
            if viewModel.liftRows.isEmpty {
                Text("Complete a workout to unlock progress tracking.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(GymTheme.card, in: RoundedRectangle(cornerRadius: 14))
            } else {
                ForEach(viewModel.liftRows) { row in
                    Button {
                        path.append(ProgressRoute.lift(row.id))
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(row.exercise.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("\(row.sessionCount) sessions · e1RM \(String(format: "%.0f", row.lastE1RM)) \(weightUnit.abbreviation)")
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
    }

    private func refresh() {
        viewModel.refresh(context: modelContext, displayUnit: weightUnit)
    }
}

#Preview {
    ProgressOverviewView()
        .preferredColorScheme(.dark)
}
