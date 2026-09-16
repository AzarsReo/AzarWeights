import Foundation

/// UserDefaults / AppStorage keys. Later UI agents should read and write only these.
enum SettingsKeys {
    /// `"lbs"` (default) or `"kg"`. See `WeightUnit`.
    static let weightUnit = "settings.weightUnit"
    /// Set `true` after the user finishes split onboarding.
    static let hasCompletedOnboarding = "settings.hasCompletedOnboarding"
    /// Set `true` after `SeedDataService` inserts bundled presets.
    static let hasSeededPresetData = "settings.hasSeededPresetData"
    /// Integer version of the last successful seed (`SeedDataService.currentSeedVersion`).
    static let seedVersion = "settings.seedVersion"
    /// Local push for confirmed plateaus (Progress tab). Default `true`.
    static let plateauNotificationsEnabled = "settings.plateauNotificationsEnabled"
}

/// Stored and displayed weight unit. Logged `SetLog.weight` values are in this unit at log time
/// (`SetLog.weightUnit` records which one was active).
enum WeightUnit: String, Codable, CaseIterable, Identifiable {
    case lbs
    case kg

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .lbs: return "Pounds (lbs)"
        case .kg: return "Kilograms (kg)"
        }
    }

    var abbreviation: String { rawValue }

    /// Convert a weight from this unit into `other`.
    func convert(_ value: Double, to other: WeightUnit) -> Double {
        if self == other { return value }
        switch (self, other) {
        case (.lbs, .kg):
            return value * 0.45359237
        case (.kg, .lbs):
            return value / 0.45359237
        default:
            return value
        }
    }
}

/// Primary muscle group for library filtering, heatmaps, and plateau aggregation.
enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case quadriceps = "Quadriceps"
    case hamstrings = "Hamstrings"
    case glutes = "Glutes"
    case calves = "Calves"
    case core = "Core"
    case forearms = "Forearms"
    case neck = "Neck"
    case cardio = "Cardio"

    var id: String { rawValue }
}

/// Equipment tag used in the exercise picker.
enum EquipmentType: String, Codable, CaseIterable, Identifiable {
    case barbell = "Barbell"
    case dumbbell = "Dumbbell"
    case cable = "Cable"
    case machine = "Machine"
    case bodyweight = "Bodyweight"
    case kettlebell = "Kettlebell"
    case band = "Band"
    case smithMachine = "Smith Machine"
    case ezBar = "EZ Bar"
    case trapBar = "Trap Bar"
    case medicineBall = "Medicine Ball"
    case suspension = "Suspension"
    case other = "Other"

    var id: String { rawValue }
}

/// Movement pattern from the plan: push / pull / hinge / squat / core / carry, plus cardio and olympic.
enum MovementPattern: String, Codable, CaseIterable, Identifiable {
    case push
    case pull
    case hinge
    case squat
    case core
    case carry
    case cardio
    case olympic

    var id: String { rawValue }

    var displayName: String { rawValue.capitalized }
}

/// `WorkoutSession.statusRaw` values.
enum SessionStatus: String, Codable, CaseIterable, Identifiable {
    case inProgress
    case completed
    case skipped

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .skipped: return "Skipped"
        }
    }
}

/// Strength trend labels produced by `PlateauDetectionService` (Progress tab).
enum ProgressStatus: String, Codable, CaseIterable, Identifiable {
    case gettingStronger
    case buildingCapacity
    case plateauing
    case confirmedPlateau
    case takingADip
    case insufficientData

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gettingStronger: return "Getting Stronger"
        case .buildingCapacity: return "Building Capacity"
        case .plateauing: return "Plateauing"
        case .confirmedPlateau: return "Confirmed Plateau"
        case .takingADip: return "Taking a Dip"
        case .insufficientData: return "Need More Data"
        }
    }
}
