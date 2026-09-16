import SwiftUI

/// Actionable plateau notification card on the Progress dashboard.
struct PlateauAlertCard: View {
    var status: ProgressStatus = .plateauing
    var message: String = "Plateau alerts will appear here."
    var suggestion: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: iconName)
                    .foregroundStyle(GymTheme.statusColor(status))
                Text(status.displayName)
                    .font(.headline)
                Spacer()
            }
            Text(message)
                .font(.subheadline)
            if !suggestion.isEmpty {
                Text(suggestion)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(GymTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(GymTheme.statusColor(status).opacity(0.45), lineWidth: 1)
                )
        )
    }

    private var iconName: String {
        switch status {
        case .takingADip: return "arrow.down.right.circle.fill"
        case .confirmedPlateau, .plateauing: return "exclamationmark.triangle.fill"
        default: return "info.circle.fill"
        }
    }
}

#Preview {
    PlateauAlertCard(
        status: .plateauing,
        message: "Bench Press plateauing — 4 sessions flat.",
        suggestion: PlateauDetectionService.suggestion(for: .plateauing)
    )
    .padding()
    .preferredColorScheme(.dark)
}
