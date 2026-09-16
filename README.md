# Fitness Tracker

Native iOS workout logger built with SwiftUI and SwiftData. Data stays on device — no account or backend for MVP.

## Open in Xcode

This Cursor folder **is** the Xcode project. No copying or re-importing files.

```bash
open FitnessTracker.xcodeproj
```

Or in Xcode: **File → Open** → select `FitnessTracker.xcodeproj` in this folder.

Then pick an iPhone simulator or your device and press **Cmd+R**.

## Requirements

- Xcode 15+ (iOS 17 / SwiftData)
- An Apple Developer account (free tier is enough to run on your own iPhone)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) only if you change `project.yml`: `brew install xcodegen`

## Regenerating the Xcode project

New Swift files under `FitnessTracker/` are picked up automatically the next time you open or build in Xcode (source globs). Re-run XcodeGen only when `project.yml` changes (targets, frameworks, build settings):

```bash
xcodegen generate
```

## Project layout

```
.
├── project.yml                    # XcodeGen source of truth
├── FitnessTracker.xcodeproj/      # Generated Xcode project (committed)
├── FitnessTracker/                # App source
│   ├── FitnessTrackerApp.swift
│   ├── Models/
│   ├── Views/
│   ├── ViewModels/
│   ├── Services/
│   └── Resources/
│       ├── PresetData.json        # Exercise library, splits, starter templates
│       └── Assets.xcassets
└── FitnessTrackerTests/
```

## Weight units

Default is **pounds (lbs)**. Toggle to kilograms in Settings. Key: `settings.weightUnit` (`lbs` | `kg`).
