# Context — GitHub Watcher

## Business context

GitHub Watcher is a Flutter Android app for monitoring GitHub repository commits.
It was built as a mobile programming project and is maintained as a focused,
lightweight alternative to the GitHub app.

## Target users

- Developers tracking repo activity
- Students monitoring project commits
- Small teams watching shared repositories

## Business rules

- Max 5 watched repositories per device (API rate limit consideration)
- Max 30 sync history entries, max 1000 cached commits per repo
- Background sync interval is fixed at 60 minutes
- Notifications only fire for background sync and can be disabled in settings
- Public repos: 60 requests/hour; authenticated: 5000 requests/hour
- Token is base64-obfuscated, not encrypted (production upgrade: flutter_secure_storage)

## Key decisions

- ValueNotifier over Provider/Riverpod: one global setting, no extra dependency
- SharedPreferences over SQLite: small key-value payloads only
- AndroidAlarmManager over WorkManager: exact hourly cadence instead of eventual
- Single platform (Android) and no conditional-export stubs: less code to maintain
- Custom AppStrings i18n over flutter_localizations: two languages, no codegen

## Known limitations

- Base64 is obfuscation, not encryption
- Background sync can be delayed by Android Doze unless battery exemption is granted
- No server-side push, no multi-user collaboration, no diff view
- In-app update check reads GitHub releases tags; no auto-update
