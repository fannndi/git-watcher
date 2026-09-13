# Tasks — Git Watcher

## Done

### 2026-09 — development round 2
- [x] Rebrand to **Git Watcher**: applicationId `com.fannndi.gitwatcher`,
      Dart package `git_watcher`, user-facing name and notification channel
- [x] Configurable background sync interval (15/30/60/120 min, default 60) wired
      end-to-end: settings UI -> storage -> exact alarm re-registration
- [x] Home: repo slot counter in the app bar, last-sync status bar, load-error retry
      state, pull-to-refresh and app-bar button both run a sync
- [x] Add repo: preview description, visibility, primary language, and stars
- [x] Settings: interval selector and localized test notification with permission flow
- [x] Commit detail: commit count in the header; floating rounded snackbars

### 2026-09 — refactor
- [x] Repaired the broken build: theme API updates, `AppSettingsController.load()`,
      `strings` scope bug, notification/startup service regressions
- [x] Removed dead code: `app_constants.dart`, `app_colors.dart`, `theme_helper.dart`,
      `extensions.dart`, `error_boundary.dart`, `shimmer_loading.dart`, `about_screen.dart`
- [x] Deleted non-Android platform folders and conditional-export stubs
- [x] Removed duplicate/stale Gradle Kotlin DSL files; Groovy config is authoritative
- [x] Unified constants, i18n strings, chips, and list animations
- [x] Immutable `WatchedRepo`; robust JSON parsing with fallbacks
- [x] StorageService: cached prefs instance, corrupt-data fallbacks, capped history/cache
- [x] Sync now respects `notificationsEnabled` and localizes notification text
- [x] Fixed commit detail sheet duplicate file list and broken retry
- [x] Widget tests no longer depend on stale UI text; storage test coverage added

## Backlog

### High
- [ ] Encrypt credentials with `flutter_secure_storage`
- [ ] Fix build environment: Gradle 8.14 rejects Java 25. Either point Flutter at a
      JDK 21 (`flutter config --jdk-dir=...`) or upgrade Gradle/AGP/Kotlin together
      (AGP 9.x + Gradle 9.x + Kotlin 2.3+), then verify `flutter build apk --flavor production`
- [ ] Request exact-alarm permission (`SCHEDULE_EXACT_ALARM`) on Android 13+ with UX
      fallback to inexact alarms

### Medium
- [ ] Inject `GitHubService`/`StorageService` in screens for full widget-test coverage
- [ ] Release signing: document `android/key.properties` setup for real store builds
- [ ] Commit count badge per repo on `RepoTile` (needs cached count lookup)
- [ ] Verify `flutter build apk --flavor production` in CI

### Low
- [ ] Optional: paginate commit cache instead of truncating at 1000
- [ ] Optional: per-repo sync intervals
- [ ] Optional: repository search by GitHub API in Add repo
- [ ] Optional: biometric lock for stored credentials
