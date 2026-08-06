# Context — GitHub Watcher

## Business Context
GitHub Watcher is a Flutter Android app for monitoring GitHub repository commits. Built as a mobile programming project (tugas pemrograman mobile).

## Target Users
- Developers tracking repo activity
- Students monitoring project commits
- Small teams watching shared repositories

## Business Rules
- Max 5 watched repositories (API rate limit consideration)
- Max 30 sync history entries (storage optimization)
- Max 1000 cached commits per repo (performance)
- 60-minute background sync interval
- Token stored as Base64 (not encryption — noted for production upgrade)
- Public repos: 60 req/hr limit; Authenticated: 5000 req/hr

## Key Decisions
- ValueNotifier over Provider/Riverpod for simplicity
- SharedPreferences over SQLite for key-value data
- AndroidAlarmManager over WorkManager for precision
- Conditional exports over runtime platform checks
- Custom i18n over flutter_localizations for simplicity

## Known Limitations
- Base64 is not encryption (production: use flutter_secure_storage)
- iOS not primary target (stubs only)
- No server-side push notifications
- No multi-user collaboration
