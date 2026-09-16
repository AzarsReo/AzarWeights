import SwiftUI

/// Status chip: Getting Stronger / Plateauing / Taking a Dip / etc.
struct ProgressStatusBadge: View {
    var status: ProgressStatus = .insufficientData

    var body: some View {
        Text(status.displayName)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundStyle(foreground)
            .background(GymTheme.statusColor(status).opacity(0.2), in: Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(GymTheme.statusColor(status).opacity(0.5), lineWidth: 1)
            )
    }

    private var foreground: Color {
        switch status {
        case .insufficientData: return .secondary
        default: return GymTheme.statusColor(status)
        }
    }
}

#Preview {
    VStack(spacing: 8) {
        ForEach(ProgressStatus.allCases) { status in
            ProgressStatusBadge(status: status)
        }
    }
    .padding()
    .preferredColorScheme(.dark)
}
