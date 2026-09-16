import Foundation
import SwiftData

/// Loads bundled `PresetData.json` into SwiftData on first launch.
enum SeedDataService {
    static let currentSeedVersion = 1

    static func seedIfNeeded(in container: ModelContainer) {
        let defaults = UserDefaults.standard
        let context = ModelContext(container)

        if defaults.bool(forKey: SettingsKeys.hasSeededPresetData) {
            return
        }

        do {
            var existingDescriptor = FetchDescriptor<Exercise>()
            existingDescriptor.fetchLimit = 1
            let existing = try context.fetch(existingDescriptor)
            if !existing.isEmpty {
                defaults.set(true, forKey: SettingsKeys.hasSeededPresetData)
                defaults.set(currentSeedVersion, forKey: SettingsKeys.seedVersion)
                return
            }

            try seed(context: context)
            try context.save()
            defaults.set(true, forKey: SettingsKeys.hasSeededPresetData)
            defaults.set(currentSeedVersion, forKey: SettingsKeys.seedVersion)
        } catch {
            assertionFailure("Preset seeding failed: \(error)")
        }
    }

    static func seed(context: ModelContext) throws {
        let file = try loadPresetFile()
        let exercisesByName = insertExercises(file.exercises, context: context)
        insertSplits(file.splits, exercisesByName: exercisesByName, context: context)
        insertStarterTemplates(file.starterTemplates, exercisesByName: exercisesByName, context: context)
    }

    private static func loadPresetFile() throws -> PresetDataFile {
        guard let url = Bundle.main.url(forResource: "PresetData", withExtension: "json") else {
            throw SeedError.missingResource
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(PresetDataFile.self, from: data)
    }

    @discardableResult
    private static func insertExercises(
        _ dtos: [PresetExerciseDTO],
        context: ModelContext
    ) -> [String: Exercise] {
        var map: [String: Exercise] = [:]
        var seen = Set<String>()

        for dto in dtos {
            let key = dto.name.lowercased()
            guard seen.insert(key).inserted else { continue }

            let exercise = Exercise(
                name: dto.name,
                muscleGroup: dto.muscleGroup,
                equipment: dto.equipment,
                movementPattern: dto.movementPattern,
                aliases: dto.aliases ?? [],
                isCustom: false
            )
            context.insert(exercise)
            map[dto.name] = exercise
        }
        return map
    }

    private static func insertSplits(
        _ dtos: [PresetSplitDTO],
        exercisesByName: [String: Exercise],
        context: ModelContext
    ) {
        for dto in dtos {
            let split = WorkoutSplit(
                name: dto.name,
                splitDescription: dto.description,
                daysPerWeek: dto.daysPerWeek,
                isPreset: true,
                isActive: false
            )
            context.insert(split)

            for (index, templateDTO) in dto.templates.enumerated() {
                let template = WorkoutTemplate(
                    name: templateDTO.name,
                    isCustom: false,
                    isPreset: true,
                    isStarterTemplate: false,
                    dayIndex: index,
                    assignedWeekdays: templateDTO.suggestedWeekdays ?? [],
                    split: split
                )
                context.insert(template)
                attachExercises(templateDTO.exercises, to: template, exercisesByName: exercisesByName, context: context)
            }
        }
    }

    private static func insertStarterTemplates(
        _ dtos: [PresetTemplateDTO],
        exercisesByName: [String: Exercise],
        context: ModelContext
    ) {
        for (index, dto) in dtos.enumerated() {
            let template = WorkoutTemplate(
                name: dto.name,
                isCustom: false,
                isPreset: true,
                isStarterTemplate: true,
                dayIndex: index,
                assignedWeekdays: []
            )
            context.insert(template)
            attachExercises(dto.exercises, to: template, exercisesByName: exercisesByName, context: context)
        }
    }

    private static func attachExercises(
        _ slots: [PresetTemplateExerciseDTO],
        to template: WorkoutTemplate,
        exercisesByName: [String: Exercise],
        context: ModelContext
    ) {
        for (index, slot) in slots.enumerated() {
            guard let exercise = exercisesByName[slot.name] else {
                assertionFailure("Preset references unknown exercise: \(slot.name)")
                continue
            }
            let row = TemplateExercise(
                order: index,
                targetSets: slot.targetSets,
                targetRepsMin: slot.targetRepsMin,
                targetRepsMax: slot.targetRepsMax,
                restSeconds: slot.restSeconds ?? 90,
                template: template,
                exercise: exercise
            )
            context.insert(row)
        }
    }

    enum SeedError: Error {
        case missingResource
    }
}

struct PresetDataFile: Codable {
    let exercises: [PresetExerciseDTO]
    let splits: [PresetSplitDTO]
    let starterTemplates: [PresetTemplateDTO]
}

struct PresetExerciseDTO: Codable {
    let name: String
    let muscleGroup: String
    let equipment: String
    let movementPattern: String
    let aliases: [String]?
}

struct PresetSplitDTO: Codable {
    let name: String
    let description: String
    let daysPerWeek: Int
    let templates: [PresetTemplateDTO]
}

struct PresetTemplateDTO: Codable {
    let name: String
    let suggestedWeekdays: [Int]?
    let exercises: [PresetTemplateExerciseDTO]
}

struct PresetTemplateExerciseDTO: Codable {
    let name: String
    let targetSets: Int
    let targetRepsMin: Int
    let targetRepsMax: Int
    let restSeconds: Int?
}
