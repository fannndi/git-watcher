# Git Watcher

Flutter Android app to watch GitHub repositories and get local notifications when new
commits land. Public repos work without login; private repos use a Personal Access Token.

Package: `com.fannndi.gitwatcher` (Dart package `git_watcher`).

## Features

- Watch up to 10 repositories, each with its own branch and sync mode
- Sync modes: latest day (minimal), latest 500 commits, latest 5000 commits
- Battery-first scheduling: inexact alarms by default (exact only with Extreme
  Precision), quiet hours, adaptive backoff while a notification stays unread,
  Wi-Fi-only option, and per-repo throttling for stale repositories
- One batched GraphQL request for all repos when a token is configured (REST fallback)
- Local notifications that name the new commits and their authors, deep-linking
  straight to the updated repo (or sync history when several repos changed), plus
  a once-a-day morning digest after quiet hours
- Per-repo mute (long-press), persisted unread badge, offline commit cache grouped
  by day, search by message/SHA, and a commit detail sheet with copy-SHA
- Parallel repo fetch with live "Syncing n/m" progress; cache writes skipped when
  nothing changed, detail refresh merges only the newest commits
- Swipe to delete with Undo; long-press a repo to open/copy/delete; tap a SHA to copy
- Repo preview when adding: description, visibility, language, stars
- Relative "last commit" time on repo tiles
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
- `docs/PRD.md` — original product requirements
