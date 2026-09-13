# Context — Git Watcher

## Business context

Git Watcher is a Flutter Android app for monitoring GitHub repository commits.
It started as a mobile programming project and is now developed further as a focused,
lightweight alternative to the GitHub app.

## Target users

- Developers tracking repo activity
- Students monitoring project commits
- Small teams watching shared repositories

## Business rules

- Max 10 watched repositories per device (API rate limit consideration)
- Max 30 sync history entries, max 1000 cached commits per repo
- Background sync interval is user-configurable: 30/60/120 minutes, default 60
- Each scheduled sync fetches at most 25 commits per repo
- Notifications only fire for background sync and can be disabled in settings
- Muted repos are still synced and cached, but excluded from notifications
- Morning digest: the first sync after quiet hours sends one digest per day
- Public repos: 60 requests/hour; authenticated: 5000 requests/hour
- Token is base64-obfuscated, not encrypted (production upgrade: flutter_secure_storage)

## Battery strategy

- Inexact alarms by default; exact alarms only behind the "Extreme Precision" opt-in
- Sleep schedule (default 23:00-07:00, local device time): no syncs while asleep;
  the first sync after wake-up sends a once-a-day morning digest
- Unread pause: after 3 consecutive notifications the user has not cleared, syncing
  stops until the user engages (app resume or notification tap); the counter resets
  during the sleep window
- Stale repos (no commit for a week) are checked at most every other hour
- Optional Wi-Fi-only sync avoids mobile radio use
- One GraphQL request per sync for all repos when a token is configured (ETag-aware
  REST fallback)
- Cache and repo prefs are written only when commits actually changed

## Key decisions

- ValueNotifier over Provider/Riverpod: one global setting, no extra dependency
- SharedPreferences over SQLite: small key-value payloads only
- AndroidAlarmManager over WorkManager: precise user-configured cadence instead of eventual
- Single platform (Android) and no conditional-export stubs: less code to maintain
- Custom AppStrings i18n over flutter_localizations: two languages, no codegen

## Known limitations

- Base64 is obfuscation, not encryption
- Background sync can be delayed by Android Doze unless battery exemption is granted
- No server-side push, no multi-user collaboration, no diff view
- In-app update check reads GitHub releases tags; no auto-update
