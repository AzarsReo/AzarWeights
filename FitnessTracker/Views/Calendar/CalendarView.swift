import SwiftUI
import SwiftData

/// Month calendar of session check-ins.
struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.checkedInAt, order: .reverse)
    private var sessions: [WorkoutSession]
    @Query(filter: #Predicate<WorkoutTemplate> { $0.isCustom == true }, sort: \WorkoutTemplate.name)
    private var customTemplates: [WorkoutTemplate]
    @Query(filter: #Predicate<WorkoutSplit> { $0.isActive == true })
    private var activeSplits: [WorkoutSplit]

    @State private var visibleMonth: Date = .now
    @State private var selectedDay: Date?
    @State private var showingDayDetail = false

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                monthHeader
                weekdayHeader
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(daysInMonth, id: \.self) { day in
                        if let day {
                            dayCell(day)
                        } else {
                            Color.clear.frame(height: 48)
                        }
                    }
                }
                .padding(.horizontal, 16)

                Spacer()
            }
            .padding(.top, 8)
            .background(GymTheme.background.ignoresSafeArea())
            .navigationTitle("Calendar")
            .sheet(isPresented: $showingDayDetail) {
                if let selectedDay {
                    NavigationStack {
                        DayDetailView(
                            date: selectedDay,
                            customTemplates: customTemplates,
                            splitTemplates: activeSplits.first?.orderedTemplates ?? []
                        )
                    }
                    .presentationDetents([.medium, .large])
                }
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                visibleMonth = calendar.date(byAdding: .month, value: -1, to: visibleMonth) ?? visibleMonth
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 44, height: 44)
            }
            Spacer()
            Text(visibleMonth, format: .dateTime.month(.wide).year())
                .font(.title3.bold())
            Spacer()
            Button {
                visibleMonth = calendar.date(byAdding: .month, value: 1, to: visibleMonth) ?? visibleMonth
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 12)
    }

    private var weekdayHeader: some View {
        HStack {
            ForEach(calendar.veryShortWeekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
    }

    private var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: visibleMonth),
              let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday
        else { return [] }

        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        var day = monthInterval.start
        while day < monthInterval.end {
            days.append(day)
            day = calendar.date(byAdding: .day, value: 1, to: day) ?? monthInterval.end
        }
        return days
    }

    private func dayCell(_ day: Date) -> some View {
        let sessions = sessionsOn(day)
        let isToday = calendar.isDateInToday(day)
        return Button {
            selectedDay = day
            showingDayDetail = true
        } label: {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: day))")
                    .font(.subheadline.weight(isToday ? .bold : .regular))
                    .foregroundStyle(isToday ? GymTheme.accent : .primary)
                HStack(spacing: 3) {
                    ForEach(sessions.prefix(3), id: \.id) { session in
                        Circle()
                            .fill(GymTheme.sessionMarker(session.status))
                            .frame(width: 6, height: 6)
                    }
                }
                .frame(height: 8)
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(sessions.isEmpty ? Color.clear : GymTheme.card)
            )
        }
        .buttonStyle(.plain)
    }

    private func sessionsOn(_ day: Date) -> [WorkoutSession] {
        sessions.filter { calendar.isDate($0.checkedInAt, inSameDayAs: day) }
    }
}

#Preview {
    CalendarView()
        .preferredColorScheme(.dark)
}
