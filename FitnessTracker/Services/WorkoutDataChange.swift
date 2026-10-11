import Foundation

/// Broadcast when sessions, sets, or templates change in ways that affect Progress analytics.
enum WorkoutDataChange {
    static let notification = Notification.Name("WorkoutDataDidChange")

    static func notify() {
        NotificationCenter.default.post(name: notification, object: nil)
    }
}
