import SwiftUI
import SwiftData

@main
struct FitnessTrackerApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema(FitnessTrackerSchema.allTypes)
        let configuration = ModelConfiguration(
            "FitnessTracker",
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to initialize SwiftData: \(error)")
        }
        SeedDataService.seedIfNeeded(in: container)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(container)
    }
}

private struct RootView: View {
    @AppStorage(SettingsKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: hasCompletedOnboarding)
    }
}
