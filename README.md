# Git Watcher

Flutter Android app to watch GitHub repositories and get local notifications when new
commits land. Public repos work without login; private repos use a Personal Access Token.

Package: `com.fannndi.gitwatcher` (Dart package `git_watcher`).

## Features

- Watch up to 5 repositories, each with its own branch and sync mode
- Sync modes: latest day (minimal), latest 500 commits, latest 5000 commits
- Configurable exact background sync (15/30/60/120 minutes, default 60)
- Local notifications with deep link to sync history and a test-notification button
- Offline commit cache, grouped by day, search by message/SHA, commit detail sheet
- Repo preview when adding: description, visibility, language, stars
- Last-sync status bar and retry state on Home
- Private repo access with base64-obfuscated token
- Bahasa Indonesia + English, light/dark/system theme
- Onboarding tour and battery optimization exemption helper

## Requirements

- Flutter 3.24+ (Dart >= 3.5)
- Android SDK, minSdk 29, targetSdk 36

## Getting started

```powershell
flutter pub get
flutter run
```

Release APK:

```powershell
flutter build apk --flavor production
```

## Quality gates

```powershell
flutter analyze   # must report zero issues
flutter test      # 50 tests
```

## Documentation

- `AGENTS.md` — project map, commands, rules for contributors and agents
- `docs/Architecture.md` — layers, data flow, storage
- `docs/Context.md` — business context and decisions
- `docs/Rules.md` — coding conventions
- `docs/Tasks.md` — backlog
- `PRD_GitHubWatcher.md` — original product requirements
