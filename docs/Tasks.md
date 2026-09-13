# Tasks — Git Watcher

## Done

### 2026-09 — development round 8 (Material 3 / UI-UX)
- [x] Material You: system wallpaper palette via `dynamic_color` with a toggle and a
      brand-seed fallback when the OS has no dynamic scheme
- [x] Centralized M3 component themes (cards, dialogs, sheets, filled inputs,
      snackbars, progress, dividers, segmented buttons, FAB shape)
- [x] Material motion on Android (`FadeForwardsPageTransitionsBuilder`)
- [x] Home redesigned with `SliverAppBar.large`, `CustomScrollView`, sliver states,
      extended FAB on the empty state, and a slot counter in the sync bar
- [x] M3 `SearchBar` on Home and commit list; larger empty-state illustration
- [x] Edge-to-edge system UI + Android predictive back

### 2026-09 — development round 7 (wake-up schedule + first-run setup)
- [x] Replaced adaptive interval backoff with an explicit sleep schedule: wake-up
      and sleep time pickers (local device time follows the region automatically)
- [x] Unread pause: after `maxUnreadCycles` (3) uncleared notifications, syncing
      stops until the user opens the app or taps the notification; the counter resets
      inside the sleep window and the first wake-up sync is a morning digest
- [x] Optional sounding alert channel for unread deliveries plus a shortcut to
      Android channel settings (manual Do Not Disturb override)
- [x] First-run setup wizard (`SetupScreen`): welcome + language/theme, schedule,
      notification permission + battery exemption, optional GitHub credentials

### 2026-09 — development round 6 (battery & sync intelligence)
- [x] Adaptive interval backoff (superseded in round 7 by the explicit sleep
      schedule + unread pause, which the user preferred)
- [x] Exact alarms are now opt-in via the Extreme Precision switch; default is
      inexact + `allowWhileIdle`
- [x] Quiet hours (default 23-07, configurable): no syncs during the window; first
      sync afterwards sends a once-a-day morning digest
- [x] Stale repos (no commit for `staleRepoDays`) are only checked on even hours
- [x] GraphQL batching: one request for all repos when a token exists, with
      parallel REST fallback (`fetchCommitsBatch`)
- [x] Wi-Fi-only sync option, per-repo mute via long-press, persisted unread badge
      (`last_seen_at`)

### 2026-09 — development round 5
- [x] Richer reminders: notification body lists newest commit titles + authors
      (max 3 per repo), payload deep-links to the updated repo when one repo
      changed, otherwise to sync history
- [x] Commit model carries the author (GitHub login, falling back to git name); the
      commit card shows the author chip

### 2026-09 — development round 4
- [x] Modular widgets: `home_states.dart`, `commit_card.dart`,
      `commit_detail_sheet.dart`; screens now only hold state + composition
- [x] Repo limit raised to 10; scheduled sync capped at 25 commits per repo
      (one request per repo per interval)
- [x] Battery: `allowWhileIdle` alarms, exact-alarm fallback to inexact when the OS
      denies `SCHEDULE_EXACT_ALARM`, 5-minute background timeout, interval options
      trimmed to 30/60/120, repo prefs written only when something changed
- [x] Interval settings copy no longer hardcodes "1 hour"

### 2026-09 — development round 3
- [x] Repo cleanup: removed `sub-project.md`, moved the product spec to `docs/PRD.md`
- [x] Fetch optimization: concurrent per-repo sync, cache writes skipped when a repo
      has no new commits, detail refresh merges the newest 100 commits only
- [x] UX: "Syncing n/m" progress bar, swipe-to-delete with Undo, relative last-commit
      time on tiles, tap-to-copy commit SHA, floating snackbars

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
- [ ] ETag / conditional requests on the commits endpoint to spare rate limit
- [ ] Verify `flutter build apk --flavor production` in CI

### Low
- [ ] Optional: paginate commit cache instead of truncating at 1000
- [ ] Optional: per-repo sync intervals
- [ ] Optional: repository search by GitHub API in Add repo
- [ ] Optional: biometric lock for stored credentials
- [ ] Optional: commit count badge per `RepoTile`
