import SwiftUI
import SwiftData

/// Per-lift multi-metric dashboard.
struct LiftDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(SettingsKeys.weightUnit) private var weightUnitRaw = WeightUnit.lbs.rawValue

    var exercise: Exercise?

    @State private var metrics: [ProgressCalculator.SessionMetrics] = []
    @State private var status: ProgressStatus = .insufficientData
    @State private var prEvents: [ProgressCalculator.PREvent] = []
    @State private var sessionExercises: [SessionExercise] = []
    @State private var expandedSessionID: UUID?

    private var weightUnit: WeightUnit { WeightUnit(rawValue: weightUnitRaw) ?? .lbs }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                comparisonCards

                chartCard {
                    E1RMTrendChart(
                        metrics: metrics,
                        prDates: Set(prEvents.filter { $0.kind == .e1RM || $0.kind == .weight }.map {
                            Calendar.current.startOfDay(for: $0.date)
                        }),
                        unitAbbreviation: weightUnit.abbreviation
                    )
                }

                chartCard {
                    VolumeLoadChart(metrics: metrics, unitAbbreviation: weightUnit.abbreviation)
                }

                chartCard {
                    RepRangeChart(metrics: metrics)
                }

                prTimeline
                sessionLog
            }
            .padding(20)
        }
        .background(GymTheme.background.ignoresSafeArea())
        .navigationTitle(exercise?.name ?? "Lift")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { reload() }
        .onChange(of: weightUnitRaw) { _, _ in reload() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            ProgressStatusBadge(status: status)
            Text(PlateauDetectionService.suggestion(for: status))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GymTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    private var comparisonCards: some View {
        let thisWeek = average(in: weekOffset(0))
        let lastWeek = average(in: weekOffset(-1))
        let fourWeek = average(in: fourWeekRange())

        return HStack(spacing: 10) {
            compareCard("This Week", thisWeek)
            compareCard("Last Week", lastWeek)
            compareCard("4-Wk Avg", fourWeek)
        }
    }

    private func compareCard(_ title: String, _ value: Double?) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value.map { String(format: "%.0f", $0) } ?? "—")
                .font(.headline.monospacedDigit())
            Text("e1RM")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(GymTheme.card, in: RoundedRectangle(cornerRadius: 12))
    }

    private var prTimeline: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PR Timeline")
                .font(.headline)
            if prEvents.isEmpty {
                Text("No PRs yet — keep logging.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(prEvents.reversed()) { event in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.kind.displayName)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(GymTheme.warning)
                                Text(event.label)
                                    .font(.subheadline.weight(.bold))
                                Text(event.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(12)
                            .background(GymTheme.cardElevated, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
        }
    }

    private var sessionLog: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Session Log")
                .font(.headline)
            ForEach(sessionExercises.reversed(), id: \.id) { se in
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedSessionID == se.id },
                        set: { expandedSessionID = $0 ? se.id : nil }
                    )
                ) {
                    ForEach(se.orderedSets, id: \.id) { set in
                        Text(
                            String(
                                format: "Set %d · %.0f %@ × %d%@",
                                set.setNumber,
                                set.unit.convert(set.weight, to: weightUnit),
                                weightUnit.abbreviation,
                                set.reps,
                                set.isWarmup ? " (W)" : ""
                            )
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 2)
                    }
                } label: {
                    HStack {
                        Text((se.session?.checkedInAt ?? .now).formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(String(format: "%.0f vol", ProgressCalculator.volumeLoad(for: se)))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(12)
                .background(GymTheme.card, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func chartCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(14)
            .background(GymTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    private func weekOffset(_ weeks: Int) -> (Date, Date) {
        let calendar = Calendar.current
        let bounds = ProgressCalculator.weekBounds()
        let start = calendar.date(byAdding: .weekOfYear, value: weeks, to: bounds.start) ?? bounds.start
        let end = calendar.date(byAdding: .weekOfYear, value: weeks, to: bounds.end) ?? bounds.end
        return (start, end)
    }

    private func fourWeekRange() -> (Date, Date) {
        let calendar = Calendar.current
        let end = ProgressCalculator.weekBounds().end
        let start = calendar.date(byAdding: .weekOfYear, value: -4, to: end) ?? end
        return (start, end)
    }

    private func average(in range: (Date, Date)) -> Double? {
        let values = metrics
            .filter { $0.date >= range.0 && $0.date < range.1 }
            .map(\.estimatedOneRepMax)
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private func reload() {
        guard let exercise else { return }
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.statusRaw == "completed" },
            sortBy: [SortDescriptor(\.checkedInAt)]
        )
        let sessions = (try? modelContext.fetch(descriptor)) ?? []
        sessionExercises = ProgressCalculator.completedSessionExercises(for: exercise, in: sessions)
        metrics = ProgressCalculator.metrics(for: sessionExercises, displayUnit: weightUnit)
        status = PlateauDetectionService.status(from: metrics)
        prEvents = ProgressCalculator.prTimeline(from: metrics, displayUnit: weightUnit)
    }
}

#Preview {
    NavigationStack {
        LiftDetailView()
    }
    .preferredColorScheme(.dark)
}
