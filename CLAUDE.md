# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build for iOS Simulator
xcodebuild -project MuscuTrack.xcodeproj -scheme LiftUp -destination 'platform=iOS Simulator,name=iPhone 17' build

# Build for watchOS Simulator
xcodebuild -project MuscuTrack.xcodeproj -scheme LiftUpWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)' build

# Run tests (when added)
xcodebuild -project MuscuTrack.xcodeproj -scheme LiftUp -destination 'platform=iOS Simulator,name=iPhone 17' test
```

Note: This project uses pure Xcode (no CocoaPods/SPM). Open `MuscuTrack.xcodeproj` in Xcode for development.

## Architecture

**Pattern**: MVVM with Repository Pattern

```
Views (SwiftUI)
    ↓
ViewModels (@StateObject/@EnvironmentObject)
    ↓
DataService (SwiftData container initialization)
    ↓
Repositories (LocalWorkoutRepository, LocalExerciseRepository)
    ↓
Models (@Model from SwiftData)
```

**Entry Point**: `LiftUpApp.swift` creates `DataService` as StateObject and injects it via `environmentObject`. The app flows: `LiftUpApp` → `ContentView` → `HomeView`.

## Key Components

### Data Layer
- **DataService**: Manages SwiftData `ModelContainer`/`ModelContext`, initializes repositories, seeds default data on first launch
- **Repositories**: Abstract data access with protocols. `LocalWorkoutRepository` and `LocalExerciseRepository` use SwiftData. `APIWorkoutRepository` is stubbed for future sync

### Models (SwiftData @Model)
- **WeekProgram**: 5-day training split containing SessionTemplates
- **SessionTemplate**: Defines exercises for a session type (Upper/Lower/Pull/Legs/Push)
- **PlannedExercise**: Exercise scheduled in a template with target reps/weight/rest
- **WorkoutSession**: Actual workout instance with real recorded data
- **SessionExercise**: Exercise during a live workout
- **ExerciseSet**: Individual set with reps, weight, warmup flag
- **Exercise**: Exercise catalog entry with muscle groups and equipment

### ViewModels
- **WorkoutViewModel**: Week program state, session management, progression
- **SessionViewModel**: Active workout state, timer integration
- **TimerViewModel**: Rest period countdown logic

### Services
- **ProgressionService**: RPE-based weight progression suggestions
- **WatchConnectivityService**: iPhone-Watch sync via WCSession

## Watch App

`MuscuTrackWatch/` contains a companion watchOS app with simplified UI. Communication happens via `WatchConnectivityManager` sending `WatchWorkoutData` JSON payloads.

## UI Conventions

- iOS 26-inspired liquid glass design language
- Custom components in `Components/`: `GlassCard`, `ProgressRing`
- Session type color coding: Upper (blue), Lower (green), Pull (orange), Legs (purple), Push (red)
- Color extensions in `Extensions/Color+Extensions.swift`
- View modifiers in `Extensions/View+Extensions.swift`

## Code Notes

- Comments are in French throughout the codebase
- All ViewModels use `@MainActor` for thread safety
- No external dependencies - pure Apple frameworks (SwiftUI, SwiftData, WatchConnectivity)
