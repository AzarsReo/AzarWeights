# Azar Weights (Fitness Tracker)

Local-first iOS workout app — SwiftUI + SwiftData. Track sessions, manage splits/templates, and view strength progress.

## Stack

| Layer | Tech |
|---|---|
| UI | SwiftUI (iOS 17+) |
| Persistence | SwiftData |
| Charts | Swift Charts |
| Auth | Sign in with Apple + Google Sign-In |
| Identity | Keychain + UserDefaults |
| Presets | `PresetData.json` via `SeedDataService` |

**Pattern:** MVVM-ish — Views + 2 ViewModels + stateless Services. No repository layer yet.

## App Flow

```
Launch → SeedDataService → RootView
  ├─ Onboarding (first run: pick split, assign days)
  └─ MainTabView (4 tabs)
       ├─ Home     → SignIn gate → Dashboard → Active Session
       ├─ Workouts → Templates, split picker, builder
       ├─ Calendar → Month view → Day detail
       └─ Progress → Lift trends, heatmap, plateaus
```

## Data Model

```
WorkoutSplit
  └─ WorkoutTemplate (split day | starter | custom)
       └─ TemplateExercise → Exercise

WorkoutSession (one gym visit)
  └─ SessionExercise (snapshot of template slot)
       └─ SetLog (weight, reps, RPE, cardio duration)
```

**Key rule:** Templates are blueprints. Sessions are immutable history — editing a template never rewrites past logs.

## Layers

| Folder | Role |
|---|---|
| `Models/` | SwiftData `@Model` types, domain enums |
| `ViewModels/` | `SessionViewModel`, `ProgressViewModel` |
| `Services/` | `ProgressCalculator`, `PlateauDetectionService`, `SeedDataService`, `AuthService` |
| `Views/` | Feature folders: Home, Workouts, Calendar, Progress, Onboarding, Settings |

## Core Loops

**Session:** `HomeView` → `checkIn(template)` → `ActiveSessionView` → log sets → `checkOut()` → optional save-as-template

**Planning:** `WorkoutsView` → build/edit templates → start from Home or Workouts

**Analytics:** `ProgressViewModel.refresh()` → `ProgressCalculator` + `PlateauDetectionService` → charts & alerts

## Auth (current)

- Home tab gates on sign-in (`SignInView` / `AuthService`)
- Account stored in Keychain — **workout data is still local-only, not user-scoped in SwiftData**

## Direction

| Now | Next |
|---|---|
| Local SwiftData persistence | Cloud sync per user |
| Template → session → set model | `ownerId` on models |
| Auth gate on Home | Multi-device account model |
| Direct `@Query` / `ModelContext` access | Repository layer |
| Session UX (RPE, swap, save) | Fix session edge-case bugs |

## Project Layout

```
FitnessTracker/
├── Models/          # SwiftData entities + enums
├── ViewModels/      # Session + Progress orchestration
├── Services/        # Domain logic, seeding, auth
├── Views/           # SwiftUI screens (by feature tab)
└── Resources/       # PresetData.json, Assets, Info.plist
```
