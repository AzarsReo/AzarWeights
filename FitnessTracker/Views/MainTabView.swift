import SwiftUI
import SwiftData

enum AppTab: Hashable {
    case home
    case workouts
    case calendar
    case progress
}

/// Root 4-tab shell. Individual tab UIs are owned by later agents — keep this file as navigation only.
struct MainTabView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(AppTab.home)

            WorkoutsView()
                .tabItem { Label("Workouts", systemImage: "dumbbell.fill") }
                .tag(AppTab.workouts)

            CalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
                .tag(AppTab.calendar)

            ProgressOverviewView()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(AppTab.progress)
        }
        .tint(Color.accentColor)
    }
}

#Preview {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Schema(FitnessTrackerSchema.allTypes),
        configurations: configuration
    )
    return MainTabView()
        .modelContainer(container)
}
