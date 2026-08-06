# Architecture — GitHub Watcher

## Tech Stack
- **Framework:** Flutter 3.24+ (Dart >=3.5.0 <4.0.0)
- **Platform:** Android (primary), iOS/Web/Linux/macOS (stubs)
- **State Management:** ValueNotifier + ValueListenableBuilder
- **Storage:** SharedPreferences (JSON serialization)
- **HTTP:** http package
- **Background:** android_alarm_manager_plus (Exact Alarm, 60min)
- **Notifications:** flutter_local_notifications
- **Design:** Material Design 3, colorSchemeSeed: blue

## Layer Architecture
```
┌─────────────────────────────────────────┐
│ UI Layer (5 screens + 1 widget)         │
│ HomeScreen, AddRepoScreen, DetailScreen │
│ SettingsScreen, UpdateScreen, RepoTile  │
├─────────────────────────────────────────┤
│ Controller Layer (1)                    │
│ AppSettingsController (ValueNotifier)   │
├─────────────────────────────────────────┤
│ Service Layer (7 services)              │
│ GitHubService, StorageService           │
│ SyncService, NotificationService        │
│ StartupService, AppSettingsController   │
│ (conditional exports for mobile/stub)   │
├─────────────────────────────────────────┤
│ Data Layer (5 models)                   │
│ WatchedRepo, Commit, CommitDetail       │
│ CommitFile, AppSettings                 │
│ GitHubCredentials, SyncLog              │
└─────────────────────────────────────────┘
```

## Directory Structure
```
lib/
├── main.dart                 # Entry point, bootstrap
├── app.dart                  # MaterialApp root widget
├── models/                   # Data models (5 files)
├── screens/                  # UI screens (5 files)
├── services/                 # Business logic (10 files, 3 conditional pairs)
├── utils/                    # Constants + i18n strings (2 files)
├── widgets/                  # Reusable widgets (1 file)
└── workers/                  # Background isolate (1 file)
```

## Platform Strategy
- Conditional exports: `notification_service.dart`, `startup_service.dart`
- Mobile: full implementation with AlarmManager, notifications
- Stub: no-op implementation for web/desktop

## Background Sync
- AndroidAlarmManager.periodic (exact: true, wakeup: true)
- 60-minute interval, idempotent registration
- Sync lock with 10-minute auto-release
- Foreground debounce: 20 seconds
