import SwiftUI
import Charts

/// Dual-axis style: heaviest working set (bars) + total volume load (line).
struct VolumeLoadChart: View {
    var metrics: [ProgressCalculator.SessionMetrics] = []
    var unitAbbreviation: String = "lbs"

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Peak Load + Volume")
                .font(.subheadline.weight(.semibold))
            if metrics.isEmpty {
                emptyState
            } else {
                Chart {
                    ForEach(metrics) { point in
                        BarMark(
                            x: .value("Date", point.date),
                            y: .value("Peak", point.peakLoad)
                        )
                        .foregroundStyle(GymTheme.info.opacity(0.7))

                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Volume", normalizedVolume(point.volumeLoad))
                        )
                        .foregroundStyle(GymTheme.accent)
                        .symbol(Circle().strokeBorder(lineWidth: 2))
                    }
                }
                .chartForegroundStyleScale([
                    "Peak": GymTheme.info,
                    "Volume": GymTheme.accent
                ])
                .chartYAxisLabel(unitAbbreviation)
                .frame(height: 180)
                Text("Bars = peak load · Line = volume (scaled)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// Scale volume roughly into peak-load range for shared axis readability.
    private func normalizedVolume(_ volume: Double) -> Double {
        let maxPeak = metrics.map(\.peakLoad).max() ?? 1
        let maxVol = metrics.map(\.volumeLoad).max() ?? 1
        guard maxVol > 0 else { return 0 }
        return volume / maxVol * maxPeak
    }

    private var emptyState: some View {
        Text("No volume data yet.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
            .background(GymTheme.cardElevated, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    VolumeLoadChart()
        .padding()
        .preferredColorScheme(.dark)
}
