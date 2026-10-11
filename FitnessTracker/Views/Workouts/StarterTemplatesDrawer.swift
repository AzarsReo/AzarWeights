import SwiftUI
import SwiftData

/// Collapsible drawer of the 6 baseline starter templates.
struct StarterTemplatesDrawer: View {
    var templates: [WorkoutTemplate]
    @Binding var isExpanded: Bool
    var onSelect: (WorkoutTemplate) -> Void
    var onCreateSplit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 8)

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "square.stack.3d.up.fill")
                    Text(isExpanded ? "Hide Starters" : "Browse Starters")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }
            .buttonStyle(.plain)

            if isExpanded {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(templates, id: \.id) { template in
                            Button {
                                onSelect(template)
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(template.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text("\(template.orderedExercises.count) lifts")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text("Use as starting point")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(GymTheme.accent)
                                }
                                .padding(14)
                                .frame(width: 160, alignment: .leading)
                                .background(GymTheme.cardElevated, in: RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)
                        }

                        Button {
                            onCreateSplit()
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(GymTheme.accent)
                                Text("Create Your Own Split")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("Build a personal routine")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(14)
                            .frame(width: 160, height: 110, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(GymTheme.accent.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 20)
                .fill(GymTheme.card)
                .shadow(color: .black.opacity(0.35), radius: 12, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    if value.translation.height < -40 {
                        withAnimation { isExpanded = true }
                    } else if value.translation.height > 40 {
                        withAnimation { isExpanded = false }
                    }
                }
        )
    }
}

#Preview {
    StarterTemplatesDrawer(templates: [], isExpanded: .constant(true), onSelect: { _ in }, onCreateSplit: {})
        .preferredColorScheme(.dark)
}
