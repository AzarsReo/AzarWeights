import SwiftUI
import Charts

/// Smoothed estimated 1RM (Epley) over sessions with PR milestone dots.
struct E1RMTrendChart: View {
    var metrics: [ProgressCalculator.SessionMetrics] = []
    var prDates: Set<Date> = []
    var unitAbbreviation: String = "lbs"

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Estimated 1RM")
                .font(.subheadline.weight(.semibold))
            if metrics.isEmpty {
                emptyState
            } else {
                Chart {
                    ForEach(metrics) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("e1RM", point.estimatedOneRepMax)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(GymTheme.accent)

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("e1RM", point.estimatedOneRepMax)
                        )
                        .foregroundStyle(
                            prDates.contains(Calendar.current.startOfDay(for: point.date))
                                ? GymTheme.warning
                                : GymTheme.accent
                        )
                        .symbolSize(
                            prDates.contains(Calendar.current.startOfDay(for: point.date)) ? 64 : 36
                        )
                    }
                }
                .chartYAxisLabel(unitAbbreviation)
                .frame(height: 180)
            }
        }
    }

    private var emptyState: some View {
        Text("Log a few sessions to see e1RM trend.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
            .background(GymTheme.cardElevated, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    E1RMTrendChart()
        .padding()
        .preferredColorScheme(.dark)
}
