# sub-project: Git Watcher

## Ringkasan

- **Nama:** Git Watcher (dulu GitHub Watcher)
- **Satu kalimat:** Flutter app Android untuk memantau commit GitHub dengan background
  sync dan notifikasi lokal
- **Path:** C:\Users\FANNNDI\Documents\git-watcher
- **App id:** `com.fannndi.gitwatcher` • **Dart package:** `git_watcher`
- **Profile:** Pro
- **Fase:** Pengembangan aktif (stabil — `flutter analyze` 0 issue, 52 test hijau)
- **Task aktif:** `docs/Tasks.md` (prioritas: `flutter_secure_storage`, perbaikan
  environment build Gradle/Java)

## Docs

- [x] PRD_GitHubWatcher.md (spesifikasi awal, sebagian historis)
- [x] docs/Architecture.md
- [x] docs/Context.md
- [x] docs/Rules.md
- [x] docs/Tasks.md
- [x] AGENTS.md (entry point untuk agent/LLM)
- [ ] Schema.md (N/A — tanpa database)
- [ ] API_Contract.md (N/A — GitHub public API)

## Konteks bisnis singkat

Developer memantau commit repo GitHub tanpa membuka browser. Sync background presisi
dengan interval yang dapat diatur (15/30/60/120 menit, default 60), notifikasi lokal,
mendukung repo publik dan privat. Target Android-only (minSdk 29).

## Struktur kunci

- `lib/utils/constants.dart` — satu-satunya sumber konstanta
- `lib/services/storage_service.dart` — satu-satunya akses SharedPreferences
- `lib/services/sync_service.dart` — inti deteksi commit baru
- `lib/services/app_settings_controller.dart` — state global (ValueNotifier)
- `lib/workers/alarm_worker.dart` — isolate background + penjadwalan ulang alarm

## Aturan penting untuk agent

1. Jangan hidupkan lagi folder platform non-Android / stub conditional export.
2. Jangan buat `.kts`; config Gradle resmi ada di `android/**/*.gradle` (Groovy).
3. Semua teks UI lewat `AppStrings` (id + en).
4. `flutter analyze` wajib 0 issue, `flutter test` wajib hijau.
