import SwiftUI

/// Shared dark gym-friendly tokens used across MVP screens.
enum GymTheme {
    static let background = Color(red: 0.07, green: 0.08, blue: 0.10)
    static let card = Color(red: 0.12, green: 0.13, blue: 0.16)
    static let cardElevated = Color(red: 0.16, green: 0.18, blue: 0.22)
    static let accent = Color(red: 0.30, green: 0.85, blue: 0.55)
    static let warning = Color(red: 0.95, green: 0.70, blue: 0.25)
    static let danger = Color(red: 0.95, green: 0.35, blue: 0.35)
    static let info = Color(red: 0.35, green: 0.65, blue: 0.95)

    static func statusColor(_ status: ProgressStatus) -> Color {
        switch status {
        case .gettingStronger: return accent
        case .buildingCapacity: return info
        case .plateauing: return warning
        case .confirmedPlateau: return warning
        case .takingADip: return danger
        case .insufficientData: return .secondary
        }
    }

    static func sessionMarker(_ status: SessionStatus) -> Color {
        switch status {
        case .completed: return accent
        case .inProgress: return info
        case .skipped: return .secondary
        }
    }
}

enum WeekdayLabel {
    static func name(_ weekday: Int) -> String {
        let symbols = Calendar.current.weekdaySymbols
        guard weekday >= 1, weekday <= 7 else { return "" }
        return symbols[weekday - 1]
    }

    static func short(_ weekday: Int) -> String {
        let symbols = Calendar.current.shortWeekdaySymbols
        guard weekday >= 1, weekday <= 7 else { return "" }
        return symbols[weekday - 1]
    }
}

enum DurationFormat {
    static func string(from interval: TimeInterval) -> String {
        let total = Int(interval)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}
