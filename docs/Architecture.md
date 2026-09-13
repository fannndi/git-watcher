# Architecture — Git Watcher

Android-only Flutter app (`com.fannndi.gitwatcher`). No server component; all state is
local (SharedPreferences) and remote data comes from the public GitHub REST API v3.

## Design system

- Material 3 throughout; `DynamicColorBuilder` (`dynamic_color`) maps the Android 12+
  wallpaper palette when `dynamicColor` is enabled, else `ColorScheme.fromSeed` with
  `brandSeedColorValue`.
- Component themes (cards, dialogs, sheets, inputs, snackbars, progress, dividers,
  segmented buttons) are centralized in `app.dart`.
- Motion uses `FadeForwardsPageTransitionsBuilder`; system UI is edge-to-edge and
  Android predictive back is enabled in the manifest.

## Layers

```
UI (screens/)
  HomeScreen, AddRepoScreen, DetailScreen, SettingsScreen, UpdateScreen
  Widgets: RepoTile, InfoChip, HomeSyncBar/HomeEmptyState/HomeErrorState,
           HomeNoResultsState, HomeTourOverlay, CommitCard, CommitDetailSheet,
           FadeInSlideUp
State (services/app_settings_controller.dart)
  AppSettingsController : ValueNotifier<AppSettings>  (global singleton)
Services (services/)
  StorageService      SharedPreferences persistence (single access point)
  GitHubService       HTTP client for api.github.com
  SyncService         change detection, caching, notification trigger
  NotificationService flutter_local_notifications + navigatorKey deep link
  StartupService      init notifications, register sync alarm
Background (workers/alarm_worker.dart)
  alarmCallback       runs in a separate isolate, top-level @pragma entry point
  registerSyncAlarm   exact periodic alarm (interval-based) with inexact fallback
Models (models/)
  WatchedRepo, Commit, CommitDetail, CommitFile, AppSettings,
  GitHubCredentials, SyncLog
```

## Runtime flow

1. `main()` loads `AppSettings` and the `setup_completed` flag, then
   `StartupService.init()`: initialize notifications (and request POST_NOTIFICATIONS
   permission once), initialize `AndroidAlarmManager`, and register the sync alarm if
   it is missing or the interval/precision changed. Exact alarms are opt-in via
   `preciseSync`; otherwise an inexact `allowWhileIdle` alarm is used.
2. `GitHubWatcherApp` rebuilds on settings changes (theme + language) and shows
   `SetupScreen` on first launch, otherwise `HomeScreen`.
3. Foreground sync: pull-to-refresh or the app-bar button calls
   `SyncService.checkUpdates()`. A 20-second debounce and a single-flight lock
   (auto-released after 10 minutes) prevent overlapping runs. `onProgress` reports
   per-repo completion to the Home status bar.
4. Background sync (`alarmCallback`) applies battery guards before touching the
   network: sleep-window skip (also resets the unread counter), unread pause after
   `maxUnreadCycles`, then the Wi-Fi-only check inside `SyncService`. The background
   timeout is 5 minutes. Times use the device's local clock, so the schedule follows
   the user's region automatically.
5. Stale repos (no commit for `staleRepoDays`) are only fetched on even hours; the
   rest are due every run. Fetching uses one GraphQL request for all repos when
   credentials exist, otherwise parallel REST requests with `If-None-Match`
   (304 responses are no-ops; the ETag is stored on the repo). Each repo is capped
   at `syncFetchLimit` (25) commits.
6. The cache is merged only when there are new commits, and `lastSha`/`lastCommitAt`
   are persisted once per changed repo.
7. New commits produce a `SyncLog` entry. Background runs also post one local
   notification listing the newest commit titles + authors (max 3 per repo); muted
   repos are excluded. The first sync in the wake-up window sends it as a "morning
   digest" (once per day), and consecutive unread deliveries switch to the sounding
   `updates_alert` channel when `alertOnUnread` is enabled. The payload opens the
   repo's `DetailScreen` when a single repo changed, otherwise `UpdateScreen`.
8. Tapping the notification opens that destination through the global
   `navigatorKey` and resets the unread counter; cold starts are redirected after
   the first frame. Resuming the app also resets the counter.
9. Pull-to-refresh in `DetailScreen` fetches only the newest 25 commits and merges
   them into the cache instead of re-downloading the whole sync mode.

## Storage keys (SharedPreferences)

| Key | Type | Contents |
|-----|------|----------|
| `watched_repos` | JSON array | `WatchedRepo` list |
| `app_settings` | JSON object | `AppSettings` |
| `sync_history` | JSON array | last `maxSyncHistory` (30) `SyncLog` entries |
| `commit_cache_{owner}_{repo}_{branch}_{mode}` | JSON array | deduped commits, max 1000 |
| `github_credentials` | JSON object | base64-obfuscated username/token |
| `last_sync_at` | ISO 8601 | last successful sync (foreground debounce) |
| `sync_lock` | ISO 8601 | sync single-flight lock |
| `alarm_registered` | bool | sync alarm already scheduled |
| `alarm_interval_minutes` | int | interval the current alarm was registered with |
| `alarm_precise` | bool | whether the current alarm is exact |
| `unread_cycles` | int | consecutive uncleared notification count (0-3) |
| `last_seen_at` | ISO 8601 | last time sync history was opened (unread badge) |
| `morning_digest_date` | date string | last day a morning digest was sent |
| `setup_completed` | bool | first-run wizard finished |
| `has_seen_tour` | bool | onboarding overlay dismissed |

## External APIs

| Endpoint | Used by |
|----------|---------|
| `GET /repos/{owner}/{repo}` | Add repo validation, avatar/visibility |
| `GET /repos/{owner}/{repo}/branches` | Branch picker (100 per page) |
| `GET /repos/{owner}/{repo}/commits` | Sync and commit list (`sha`, `per_page`, `page`) |
| `GET /repos/{owner}/{repo}/commits/{sha}` | Commit detail sheet |
| `GET /repos/fannndi/git-watcher/releases/latest` | In-app update hint |

Requests send Basic auth when credentials exist and fall back to anonymous on 401.
Server errors are retried once; rate-limit responses are surfaced to the caller so
one failing repo cannot stall the rest.

## Gradle note

`android/app/build.gradle` (Groovy) is the authoritative build config: namespace and
applicationId `com.fannndi.gitwatcher`, `emulator`/`production` flavors, release
signing, and core library desugaring. There are intentionally no `.kts` duplicates.
