# AGENTS.md — Git Watcher

Flutter Android app that watches GitHub repositories and notifies about new commits.
App id: `com.fannndi.gitwatcher`, Dart package: `git_watcher`.

## UI system

- Material 3 with Material You: `DynamicColorBuilder` supplies the system palette
  when `AppSettings.dynamicColor` is on (default), otherwise the brand seed
  (`brandSeedColorValue`). All component themes live in `app.dart`.
- Motion: `FadeForwardsPageTransitionsBuilder` on Android.
- Home uses a `CustomScrollView` with `SliverAppBar.large`; lists are slivers and
  state widgets (`home_states.dart`) are non-scrolling so they can live inside
  `SliverFillRemaining`. On screens >= 720 dp it switches to a two-pane
  master-detail layout (`DetailScreen` embedded on the right).
- Detail and Update lists use pinned date headers (`sliver_date_header.dart`),
  `ChoiceChip` filters, and skeleton placeholders (`skeleton.dart`) while loading.
- Settings is a hub (`settings_screen.dart`) with sub-pages: appearance, sync,
  private access, about. Shared `SettingsSection` lives in `widgets/`.
- Search uses the M3 `SearchBar` widget (Home and Detail).
- Edge-to-edge system UI is enabled in `main()` and Android predictive back is on
  via `enableOnBackInvokedCallback`. The launcher icon is adaptive with a
  monochrome layer for Android 13+ themed icons.

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
| CI | `.github/workflows/ci.yml` — format check, analyze, test |

Toolchain note: Gradle 9.3.1 + AGP 9.1.1 + Kotlin 2.4.20 (required for Java 25;
older Gradle 8.x cannot run on this machine). `android/builtInKotlin=false` and
`android.newDsl=false` are Flutter-migrator flags, keep them.

## Security

- GitHub credentials live in `flutter_secure_storage`; older base64 prefs are
  migrated on first read. `StorageService` falls back to prefs only when the
  secure plugin is unavailable (tests).
- `android:allowBackup="false"` so tokens never leave the device via cloud backup.
- `hideNotificationContent` maps to `NotificationVisibility.secret` for lock-screen
  privacy.

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
    startup_service.dart        init notifications + sync alarm
  screens/                      Home, Setup, AddRepo, Detail, Update + settings hub
                                and 4 settings sub-pages
  widgets/
    repo_tile.dart              repo card with long-press actions
    chips.dart                  shared InfoChip
    home_states.dart            Home sync bar, empty/error/no-result, tour
    commit_card.dart            commit list item
    commit_detail_sheet.dart    commit detail bottom sheet + file summary
    skeleton.dart               loading placeholders
    sliver_date_header.dart     pinned date headers for commit/history lists
    settings_section.dart       shared settings card
  workers/alarm_worker.dart     background isolate entry point + alarm scheduling
  utils/constants.dart          ALL constants (single source of truth)
  utils/strings.dart            AppStrings i18n (id + en)
test/
  unit/models_test.dart, unit/strings_test.dart
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
- Keep it simple: prefer small stateless widgets and plain functions over abstractions.
- Delete dead code instead of commenting it out. Keep the analyzer at zero issues and tests green.

## Behavior contracts

- Up to `maxWatchedRepos` (10) repos.
- First launch shows `SetupScreen` until `setup_completed` is set (wizard: language/
  theme, schedule, notification permission, optional GitHub token).
- Background sync: periodic alarm via `AndroidAlarmManager`, interval from
  `AppSettings.syncIntervalMinutes` (30/60/120, default 60). Exact alarms are used
  only when `AppSettings.preciseSync` is on; otherwise inexact + `allowWhileIdle`.
  `registerSyncAlarm()` re-registers when interval or precision changes.
- Battery guards in `alarmCallback`, in order: sleep window skip -> unread pause ->
  Wi-Fi-only skip (inside `SyncService`) -> fetch.
  - Sleep window (`quietHoursEnabled`, default 23:00-07:00, times in local time):
    no sync runs inside it and the unread counter resets; the first sync after
    wake-up (up to 3 h window) is sent as a once-a-day morning digest.
  - Unread pause: each run checks whether the previous update notification is still
    active. If so the counter grows; at `maxUnreadCycles` (3) syncing stops until
    the user engages (opens the app or taps the notification, which resets it).
  - When `alertOnUnread` is on, the second and later consecutive notifications use
    the sounding `updates_alert` channel.
- Every scheduled sync: stale repos (`lastCommitAt` older than `staleRepoDays`) are
  only fetched on even hours; active repos every run. Each repo is capped at
  `syncFetchLimit` (25) commits.
- Fetches use one GraphQL request for all repos when GitHub credentials exist
  (`fetchCommitsBatch`), falling back to parallel REST requests otherwise. The REST
  path sends `If-None-Match` per repo; a 304 skips parsing and cache writes, and the
  response ETag is persisted on `WatchedRepo.etag`.
- Foreground sync: 20 s debounce, 10 min stale-lock auto-release, single-flight lock.
  Repos are fetched concurrently, `onProgress(completed, total)` drives the Home bar,
  and repo/cache data is only rewritten when a repo actually has new commits.
- Commit cache: deduped by SHA, sorted newest-first, capped at `maxCachedCommits`.
  Detail pull-to-refresh merges the newest `syncFetchLimit` commits.
- Notifications are sent only by background sync and only when
  `AppSettings.notificationsEnabled` is true. Muted repos are still synced and
  cached but excluded from notifications. The body lists the newest commit titles
  with authors (cap 3 per repo); the payload deep-links to the updated repo when
  exactly one repo changed, otherwise to `UpdateScreen`. Notification actions:
  `mark_read` resets the unread counter and cancels, `mute_repo` mutes the
  payload's repo (single-repo notifications only). The background action handler is
  the top-level `notificationActionBackground` entry point.
- Unread badge is persisted via `last_seen_at`: history is "unread" while the newest
  `SyncLog` is newer than the stored last-seen timestamp.
- Token is base64-obfuscated in SharedPreferences, not encrypted.
- Sync modes: `minimal` = commits from the latest day, `latest_500`, `extended_5000`.

## Docs

- `docs/Architecture.md` — layers, flows, storage keys
- `docs/Context.md` — business rules and key decisions
- `docs/Rules.md` — coding conventions
- `docs/Tasks.md` — backlog and known gaps
- `docs/PRD.md` — original product spec (partially historical)
