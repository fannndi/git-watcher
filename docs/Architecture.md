# Architecture — Git Watcher

Android-only Flutter app (`com.fannndi.gitwatcher`). No server component; all state is
local (SharedPreferences) and remote data comes from the public GitHub REST API v3.

## Layers

```
UI (screens/)
  HomeScreen, AddRepoScreen, DetailScreen, SettingsScreen, UpdateScreen
  Widgets: RepoTile, InfoChip, FadeInSlideUp
State (services/app_settings_controller.dart)
  AppSettingsController : ValueNotifier<AppSettings>  (global singleton)
Services (services/)
  StorageService      SharedPreferences persistence (single access point)
  GitHubService       HTTP client for api.github.com
  SyncService         change detection, caching, notification trigger
  NotificationService flutter_local_notifications + navigatorKey deep link
  StartupService      init notifications, register exact alarm
Background (workers/alarm_worker.dart)
  alarmCallback       runs in a separate isolate, top-level @pragma entry point
Models (models/)
  WatchedRepo, Commit, CommitDetail, CommitFile, AppSettings,
  GitHubCredentials, SyncLog
```

## Runtime flow

1. `main()` loads `AppSettings` from storage, then `StartupService.init()`:
   initialize notifications (and request POST_NOTIFICATIONS permission once),
   initialize `AndroidAlarmManager`, register the exact periodic alarm if it is
   missing or the configured interval changed.
2. `GitHubWatcherApp` rebuilds on settings changes (theme + language) and hosts
   `HomeScreen`.
3. Foreground sync: pull-to-refresh or the app-bar button calls
   `SyncService.checkUpdates()`. A 20-second debounce and a single-flight lock
   (auto-released after 10 minutes) prevent overlapping runs. `onProgress` reports
   per-repo completion to the Home status bar.
4. Background sync: the alarm isolate calls the same `SyncService.checkUpdates()`
   with `isBackground: true` and an 8-minute timeout.
5. Watched repos are fetched concurrently. Per repo, sync fetches the newest commits
   (20 for `minimal`, 100 for the larger modes) and counts commits newer than
   `lastSha`. The cache is merged only when there are new commits, and
   `lastSha`/`lastCommitAt` are updated from a single `saveRepos` write.
6. New commits produce a `SyncLog` entry. Background runs also post one local
   notification when notifications are enabled.
7. Tapping the notification opens `UpdateScreen` through the global
   `navigatorKey`; cold starts are redirected after the first frame.
8. Pull-to-refresh in `DetailScreen` fetches only the newest
   `backgroundSyncFetchLimit` commits and merges them into the cache instead of
   re-downloading the whole sync mode.

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
| `alarm_registered` | bool | exact alarm already scheduled |
| `alarm_interval_minutes` | int | interval the current alarm was registered with |
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
