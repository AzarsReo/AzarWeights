import SwiftUI

/// Minimal settings: weight unit (default lbs) and plateau notification toggle.
struct SettingsView: View {
    @AppStorage(SettingsKeys.weightUnit) private var weightUnitRaw = WeightUnit.lbs.rawValue
    @AppStorage(SettingsKeys.plateauNotificationsEnabled) private var plateauNotificationsEnabled = true

    var body: some View {
        Form {
            Section {
                Picker("Weight Unit", selection: $weightUnitRaw) {
                    ForEach(WeightUnit.allCases) { unit in
                        Text(unit.displayName).tag(unit.rawValue)
                    }
                }
                .pickerStyle(.inline)
            } header: {
                Text("Units")
            } footer: {
                Text("New sets are stored in the selected unit. Charts convert historical logs using each set’s saved unit.")
            }

            Section {
                Toggle("Plateau Alerts", isOn: $plateauNotificationsEnabled)
            } header: {
                Text("Notifications")
            } footer: {
                Text("Confirmed plateaus (6+ flat sessions) can send a local notification. In-app badges always show on Progress.")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
