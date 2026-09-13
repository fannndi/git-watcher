# sub-project: GitHub Watcher

## Ringkasan

- **Nama:** GitHub Watcher
- **Satu kalimat:** Flutter app Android untuk memantau commit GitHub dengan background
  sync dan notifikasi lokal
- **Path:** C:\Users\FANNNDI\Documents\git-watcher
- **Profile:** Pro
- **Fase:** Maintenance (stabil — `flutter analyze` 0 issue, 50 test hijau)
- **Task aktif:** Backlog di `docs/Tasks.md` (prioritas: `flutter_secure_storage`)

## Docs

- [x] PRD_GitHubWatcher.md
- [x] docs/Architecture.md
- [x] docs/Context.md
- [x] docs/Rules.md
- [x] docs/Tasks.md
- [x] AGENTS.md (entry point untuk agent/LLM)
- [ ] Schema.md (N/A — tanpa database)
- [ ] API_Contract.md (N/A — GitHub public API)

## Konteks bisnis singkat

Developer memantau commit repo GitHub tanpa membuka browser. Sync background tiap 60
menit via exact alarm, notifikasi lokal, mendukung repo publik dan privat.
Target Android-only (minSdk 29).

## Struktur kunci

- `lib/utils/constants.dart` — satu-satunya sumber konstanta
- `lib/services/storage_service.dart` — satu-satunya akses SharedPreferences
- `lib/services/sync_service.dart` — inti deteksi commit baru
- `lib/services/app_settings_controller.dart` — state global (ValueNotifier)
- `lib/workers/alarm_worker.dart` — isolate background

## Aturan penting untuk agent

1. Jangan hidupkan lagi folder platform non-Android / stub conditional export.
2. Jangan buat `.kts`; config Gradle resmi ada di `android/**/*.gradle` (Groovy).
3. Semua teks UI lewat `AppStrings` (id + en).
4. `flutter analyze` wajib 0 issue, `flutter test` wajib hijau.
