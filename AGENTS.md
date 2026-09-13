# AGENTS.md — GitHub Watcher

Flutter Android app that watches GitHub repositories and notifies about new commits.

## Commands

| Task | Command |
|------|---------|
| Install deps | `flutter pub get` |
| Static analysis (must stay clean) | `flutter analyze` |
| Run all tests | `flutter test` |
| Run one area | `flutter test test/unit`, `test/widget`, `test/integration` |
| Run app | `flutter run` (Android device/emulator) |
| Release build | `flutter build apk --flavor production` |
| Regenerate launcher icons | `dart run flutter_launcher_icons` |
| Helper script | `.\run_tests.ps1 [-Type unit|widget|integration|all]` |

## Layout

```
lib/
  main.dart                     bootstrap: load settings, init services, runApp
  app.dart                      MaterialApp + light/dark themes
  models/                       immutable data classes with fromJson/toJson
  services/
    storage_service.dart        the only class that touches SharedPreferences
    github_service.dart         GitHub REST v3 client, no UI
    sync_service.dart           change detection + cache + notification trigger
    app_settings_controller.dart global ValueNotifier<AppSettings>
    notification_service.dart   local notifications, navigatorKey, deep link
    startup_service.dart        init notifications + exact periodic alarm
  screens/                      5 screens, StatefulWidget + setState
  widgets/                      RepoTile + shared InfoChip
  workers/alarm_worker.dart     background isolate entry point
  utils/constants.dart          ALL constants (single source of truth)
  utils/strings.dart            AppStrings i18n (id + en)
test/
  unit/models_test.dart
  integration/storage_service_test.dart
  widget/screens_test.dart
```

## Rules

- Android-only target. Do not add iOS/web/desktop folders, conditional exports, or stubs.
- Gradle: only Groovy files (`android/**/*.gradle`) exist and are authoritative. Never create `.kts` duplicates.
- Constants live only in `lib/utils/constants.dart`. Storage keys must not appear as string literals elsewhere.
- Persist through `StorageService`; screens and other services never call SharedPreferences directly.
- Every user-visible string goes through `AppStrings`, in both `id` and `en`.
- Screens get the language via `ValueListenableBuilder` on `appSettingsController`.
- Delete dead code instead of commenting it out. Keep the analyzer at zero issues and tests green.

## Behavior contracts

- Background sync: hourly exact alarm (`AndroidAlarmManager.periodic`), idempotent
  through the `alarm_registered` flag in `alarm_worker.dart`.
- Foreground sync: 20 s debounce, 10 min stale-lock auto-release, single-flight lock.
- Commit cache: deduped by SHA, sorted newest-first, capped at `maxCachedCommits`.
- Notifications are sent only by background sync and only when
  `AppSettings.notificationsEnabled` is true.
- Token is base64-obfuscated in SharedPreferences, not encrypted.
- Sync modes: `minimal` = commits from the latest day, `latest_500`, `extended_5000`.

## Docs

- `docs/Architecture.md` — layers, flows, storage keys
- `docs/Context.md` — business rules and key decisions
- `docs/Rules.md` — coding conventions
- `docs/Tasks.md` — backlog and known gaps
- `PRD_GitHubWatcher.md` — original product spec (partially historical)
