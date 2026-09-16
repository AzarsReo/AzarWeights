import SwiftUI
import Charts

/// Stacked bars of sets by rep range: 1–5 / 6–12 / 13+.
struct RepRangeChart: View {
    var metrics: [ProgressCalculator.SessionMetrics] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Rep Range Distribution")
                .font(.subheadline.weight(.semibold))
            if metrics.isEmpty {
                emptyState
            } else {
                Chart {
                    ForEach(metrics) { point in
                        BarMark(
                            x: .value("Date", point.date),
                            y: .value("Sets", point.strengthSets)
                        )
                        .foregroundStyle(by: .value("Range", "1–5"))

                        BarMark(
                            x: .value("Date", point.date),
                            y: .value("Sets", point.hypertrophySets)
                        )
                        .foregroundStyle(by: .value("Range", "6–12"))

                        BarMark(
                            x: .value("Date", point.date),
                            y: .value("Sets", point.enduranceSets)
                        )
                        .foregroundStyle(by: .value("Range", "13+"))
                    }
                }
                .chartForegroundStyleScale([
                    "1–5": GymTheme.danger,
                    "6–12": GymTheme.accent,
                    "13+": GymTheme.info
                ])
                .frame(height: 180)
            }
        }
    }

    private var emptyState: some View {
        Text("No set distribution yet.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
            .background(GymTheme.cardElevated, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    RepRangeChart()
        .padding()
        .preferredColorScheme(.dark)
}
