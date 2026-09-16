import SwiftUI

/// Body diagram colored by weekly volume / progress status per muscle group.
struct MuscleHeatmapView: View {
    var volumes: [MuscleGroup: Double] = [:]
    var statuses: [MuscleGroup: ProgressStatus] = [:]
    var onSelect: ((MuscleGroup) -> Void)?

    private let primaryGroups: [MuscleGroup] = [
        .chest, .back, .shoulders, .biceps, .triceps,
        .quadriceps, .hamstrings, .glutes, .calves, .core
    ]

    private var maxVolume: Double {
        max(volumes.values.max() ?? 0, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Muscle Heatmap")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(primaryGroups, id: \.self) { group in
                    Button {
                        onSelect?(group)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(group.rawValue)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text(volumeLabel(group))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Circle()
                                .fill(color(for: group))
                                .frame(width: 14, height: 14)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(GymTheme.cardElevated)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(color(for: group).opacity(intensity(for: group) * 0.35))
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func volumeLabel(_ group: MuscleGroup) -> String {
        let volume = volumes[group] ?? 0
        if volume <= 0 { return "No volume this week" }
        return String(format: "%.0f vol", volume)
    }

    private func intensity(for group: MuscleGroup) -> Double {
        let volume = volumes[group] ?? 0
        guard volume > 0 else { return 0.08 }
        return min(1, volume / maxVolume)
    }

    private func color(for group: MuscleGroup) -> Color {
        if let status = statuses[group], status != .insufficientData {
            return GymTheme.statusColor(status)
        }
        let volume = volumes[group] ?? 0
        return volume > 0 ? GymTheme.accent : Color.secondary
    }
}

#Preview {
    MuscleHeatmapView(
        volumes: [.chest: 12000, .back: 8000],
        statuses: [.chest: .gettingStronger, .back: .plateauing]
    )
    .padding()
    .preferredColorScheme(.dark)
}
