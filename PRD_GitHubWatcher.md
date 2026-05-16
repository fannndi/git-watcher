# Product Requirements Document (PRD)
# GitHub Watcher — Aplikasi Pemantau Commit GitHub

---

**Nama Proyek:** GitHub Watcher  
**Nama Package:** `github_watcher`  
**Platform:** Android (Flutter)  
**Versi Aplikasi:** 1.0.0+2 (Release Candidate)  
**Developer:** alisa ([github.com/fannndi](https://github.com/fannndi))  
**Tanggal Dokumen:** 16 Mei 2026  
**Jenis Dokumen:** Product Requirements Document

---

## Daftar Isi

1. [Ringkasan Eksekutif](#1-ringkasan-eksekutif)
2. [Latar Belakang & Motivasi](#2-latar-belakang--motivasi)
3. [Tujuan Produk](#3-tujuan-produk)
4. [Ruang Lingkup](#4-ruang-lingkup)
5. [Arsitektur Teknis](#5-arsitektur-teknis)
6. [Struktur Proyek](#6-struktur-proyek)
7. [Model Data](#7-model-data)
8. [Layanan (Services)](#8-layanan-services)
9. [Fitur & Spesifikasi Fungsional](#9-fitur--spesifikasi-fungsional)
10. [Spesifikasi Antarmuka (UI/UX)](#10-spesifikasi-antarmuka-uiux)
11. [Alur Navigasi Aplikasi](#11-alur-navigasi-aplikasi)
12. [Persyaratan Non-Fungsional](#12-persyaratan-non-fungsional)
13. [Dependensi & Library](#13-dependensi--library)
14. [Konfigurasi Platform Android](#14-konfigurasi-platform-android)
15. [Penanganan Error & Edge Cases](#15-penanganan-error--edge-cases)
16. [Lokalisasi (i18n)](#16-lokalisasi-i18n)
17. [Batasan & Limitasi](#17-batasan--limitasi)
18. [Rencana Pengujian](#18-rencana-pengujian)
19. [Kesimpulan](#19-kesimpulan)

---

## 1. Ringkasan Eksekutif

**GitHub Watcher** adalah aplikasi mobile berbasis Flutter yang memungkinkan pengguna memantau aktivitas commit dari satu atau beberapa repositori GitHub secara otomatis di latar belakang. Aplikasi ini dirancang untuk developer, mahasiswa, maupun tim kecil yang ingin mendapatkan notifikasi real-time ketika terdapat commit baru pada branch tertentu, tanpa perlu membuka browser atau platform GitHub secara manual.

Aplikasi mendukung repository publik maupun privat (dengan autentikasi Personal Access Token), dilengkapi background sync menggunakan **AndroidAlarmManager**, push notification lokal, cache data offline, serta antarmuka bilingual (Bahasa Indonesia dan English) dengan dukungan tema terang, gelap, dan sistem. Fitur unggulan **Extreme Precision** memastikan sinkronisasi tetap berjalan tepat waktu bahkan saat perangkat dalam mode hemat daya.

---

## 2. Latar Belakang & Motivasi

Dalam pengembangan perangkat lunak modern, tim developer sering bekerja secara kolaboratif pada satu repositori GitHub. Anggota tim perlu mengetahui perubahan kode terbaru yang dilakukan rekan mereka agar bisa menyinkronkan pekerjaan, melakukan code review tepat waktu, atau menghindari konflik merge.

Solusi yang ada umumnya mengharuskan pengguna:
- Membuka browser secara manual dan mengecek halaman commit GitHub.
- Menggunakan email notifikasi GitHub yang sering terlambat atau masuk sebagai spam.
- Memasang aplikasi GitHub resmi yang memiliki banyak fitur tidak relevan dan bobot yang besar.

**GitHub Watcher** hadir sebagai solusi ringan dan terfokus: sebuah aplikasi Android yang secara periodik mengecek commit terbaru pada branch yang dipantau, lalu mengirim notifikasi lokal kepada pengguna ketika ada pembaruan baru.

---

## 3. Tujuan Produk

### 3.1 Tujuan Utama
- Membangun aplikasi mobile Flutter Android yang fungsional dan siap pakai sebagai tugas pemrograman mobile.
- Mengimplementasikan integrasi dengan GitHub REST API untuk mengambil data commit repositori.
- Mengimplementasikan background task scheduling menggunakan **AndroidAlarmManager** (via plugin `android_alarm_manager_plus`) untuk akurasi tinggi.
- Mengimplementasikan push notification lokal menggunakan `flutter_local_notifications`.
- Mengimplementasikan penyimpanan data lokal persisten menggunakan `shared_preferences`.
- Mengimplementasikan mekanisme pengecualian optimalisasi baterai (**Battery Optimization Exemption**) untuk menjamin eksekusi latar belakang.

### 3.2 Tujuan Sekunder
- Mendemonstrasikan pola arsitektur yang bersih (pemisahan model, service, screen, widget).
- Menerapkan best practice Flutter: `ValueNotifier`, `WidgetsBindingObserver`, lifecycle management.
- Mendukung dua bahasa (Indonesia dan Inggris) sebagai implementasi internasionalisasi sederhana.
- Mendukung dark mode dan light mode.
- Mengimplementasikan keamanan dasar: token GitHub disimpan dalam format Base64-encoded di `SharedPreferences`.

---

## 4. Ruang Lingkup

### 4.1 Dalam Ruang Lingkup (In-Scope)
| Nomor | Fitur |
|-------|-------|
| F-01 | Menambahkan repositori GitHub (publik atau privat) untuk dipantau |
| F-02 | Memilih branch yang ingin dipantau dari daftar branch yang diambil via API |
| F-03 | Memilih mode sinkronisasi: Minimal, 500 commit, atau 5000 commit |
| F-04 | Menampilkan daftar repositori yang sedang dipantau di halaman utama |
| F-05 | Menghapus repositori dari daftar pantauan (swipe-to-delete) |
| F-06 | Menampilkan daftar commit per repositori, dikelompokkan per tanggal |
| F-07 | Pencarian commit berdasarkan pesan atau SHA |
| F-08 | Melihat detail commit: statistik file berubah, baris ditambah/dihapus, status file |
| F-09 | Membuka halaman commit di GitHub melalui browser eksternal |
| F-10 | Sinkronisasi manual (Pull-to-Refresh) dari halaman utama |
| F-11 | Background sync otomatis menggunakan AndroidAlarmManager (Exact Alarm) |
| F-12 | Notifikasi lokal ketika terdapat commit baru |
| F-13 | Riwayat sinkronisasi (sync history) maksimal 30 entri terakhir |
| F-14 | Pengaturan kredensial GitHub (username + Personal Access Token) |
| F-15 | Pengaturan bahasa (Indonesia / English) |
| F-16 | Pengaturan tema (System / Light / Dark) |
| F-17 | Fitur **Extreme Precision** (Request Battery Optimization Exemption) |
| F-18 | Sinkronisasi otomatis saat menambahkan repositori baru |
| F-19 | Deep link dari notifikasi langsung ke halaman riwayat update |

### 4.2 Di Luar Ruang Lingkup (Out-of-Scope)
- Push notification berbasis server (Firebase Cloud Messaging)
- Dukungan platform iOS (konfigurasi ada namun bukan target utama)
- Fitur membuat atau mengedit repositori GitHub
- Fitur kolaborasi tim multi-user
- Tampilan diff kode baris per baris
- Fitur pencarian repositori melalui GitHub search API

---

## 5. Arsitektur Teknis

### 5.1 Gambaran Umum Arsitektur

Aplikasi menggunakan arsitektur berlapis sederhana yang terdiri dari empat lapisan utama:

```
┌─────────────────────────────────────────────┐
│                  UI Layer                   │
│  Screens: Home, AddRepo, Detail, Settings,  │
│           Update                            │
│  Widgets: RepoTile                          │
├─────────────────────────────────────────────┤
│              Controller Layer               │
│  AppSettingsController (ValueNotifier)      │
├─────────────────────────────────────────────┤
│               Service Layer                 │
│  GitHubService | StorageService             │
│  SyncService   | NotificationService        │
│  StartupService | AlarmWorker                │
├─────────────────────────────────────────────┤
│               Data Layer                    │
│  Models: WatchedRepo, Commit, CommitDetail, │
│          CommitFile, AppSettings,           │
│          GitHubCredentials, SyncLog         │
│  Storage: SharedPreferences (JSON)          │
│  API: GitHub REST API v3                    │
└─────────────────────────────────────────────┘
```

### 5.2 Pola State Management

Aplikasi menggunakan `ValueNotifier<AppSettings>` (melalui `AppSettingsController`) sebagai state management global untuk pengaturan aplikasi. `ValueListenableBuilder` digunakan di widget tree untuk me-rebuild UI secara reaktif ketika settings berubah.

State lokal per screen dikelola menggunakan `StatefulWidget` dan `setState()`.

### 5.3 Pola Background Processing

Background sync diimplementasikan menggunakan dua mekanisme yang saling melengkapi:

1. **AndroidAlarmManager (Exact & Periodic)** — Menggunakan `AndroidAlarmManager.periodic` dengan flag `exact: true` dan `wakeup: true`. Ini memanfaatkan `setExactAndAllowWhileIdle` di Android untuk memastikan tugas berjalan tepat setiap 60 menit meskipun perangkat dalam mode Doze.

2. **Idempotent Registration** — Registrasi alarm dilakukan secara idempotent di `StartupService`. Sistem mengecek flag `alarm_registered` agar pembukaan aplikasi berulang kali tidak mereset jadwal sinkronisasi yang sudah ada.

3. **Battery Exemption Integration** — Menyediakan akses langsung bagi pengguna untuk mengecualikan aplikasi dari optimalisasi baterai sistem guna menjamin akurasi alarm 100%.

### 5.4 Strategi Fallback Autentikasi GitHub API

`GitHubService._get()` mengimplementasikan pola autentikasi proaktif:
1. Jika kredensial tersedia, gunakan langsung (mendapatkan limit 5000 req/jam).
2. Jika tidak ada atau gagal (HTTP 401), coba request publik (limit 60 req/jam).

Ini memungkinkan aplikasi bekerja optimal untuk repo publik tanpa memerlukan setup token.

---

## 6. Struktur Proyek

```
git-watcher-main/
├── lib/
│   ├── main.dart                          # Entry point aplikasi
│   ├── app.dart                           # Root widget (GitHubWatcherApp)
│   ├── models/
│   │   ├── app_settings.dart              # Model pengaturan aplikasi
│   │   ├── commit.dart                    # Model Commit, CommitDetail, CommitFile
│   │   ├── github_credentials.dart        # Model kredensial GitHub (Base64)
│   │   ├── sync_log.dart                  # Model riwayat sinkronisasi
│   │   └── watched_repo.dart              # Model repositori yang dipantau
│   ├── screens/
│   │   ├── home_screen.dart               # Halaman utama (daftar repo)
│   │   ├── add_repo_screen.dart           # Tambah repositori baru
│   │   ├── detail_screen.dart             # Detail commit per repo
│   │   ├── settings_screen.dart           # Pengaturan aplikasi
│   │   └── update_screen.dart             # Riwayat sinkronisasi
│   ├── services/
│   │   ├── app_settings_controller.dart   # ValueNotifier untuk settings
│   │   ├── github_service.dart            # Klien GitHub REST API
│   │   ├── notification_service.dart      # Factory/stub notifikasi
│   │   ├── notification_service_mobile.dart  # Implementasi notifikasi Android
│   │   ├── notification_service_stub.dart    # Stub untuk non-mobile
│   │   ├── startup_service.dart           # Factory/stub startup
│   │   ├── startup_service_mobile.dart    # Implementasi AlarmManager & Battery settings
│   │   ├── startup_service_stub.dart      # Stub untuk non-mobile
│   │   ├── storage_service.dart           # Manajemen SharedPreferences & Cache Capping
│   │   └── sync_service.dart              # Logika cek pembaruan (Mode-Aware)
│   ├── utils/
│   │   ├── constants.dart                 # Konstanta global aplikasi
│   │   └── strings.dart                   # Kelas lokalisasi (ID/EN)
│   ├── widgets/
│   │   └── repo_tile.dart                 # Tile item repository (Animated & Localized)
│   └── workers/
│       └── alarm_worker.dart              # Isolate entry point untuk AlarmManager
├── android/                               # Konfigurasi native Android
├── ios/                                   # Konfigurasi native iOS (opsional)
├── pubspec.yaml                           # Konfigurasi dependensi Flutter
└── test/
    └── widget_test.dart                   # Test dasar widget
```

---

## 7. Model Data

### 7.1 `WatchedRepo`

Merepresentasikan sebuah repositori GitHub yang sedang dipantau.

| Field | Tipe | Keterangan |
|-------|------|------------|
| `owner` | `String` | Nama pemilik/organisasi repositori |
| `repo` | `String` | Nama repositori |
| `branch` | `String` | Branch yang dipantau |
| `syncMode` | `String` | Mode sync: `minimal`, `latest_500`, `extended_5000` |
| `avatarUrl` | `String` | URL avatar pemilik (dari GitHub API) |
| `isPrivate` | `bool` | Status visibilitas repositori |
| `lastCommitAt` | `DateTime?` | Timestamp commit terakhir yang terdeteksi |
| `lastSha` | `String` | SHA commit terakhir yang terdeteksi |

**Computed property:** `fullName` → `"$owner/$repo"`

**Persistensi:** Disimpan sebagai JSON array di `SharedPreferences` dengan key `watched_repos`.

---

### 7.2 `Commit`

Merepresentasikan satu entri commit GitHub.

| Field | Tipe | Keterangan |
|-------|------|------------|
| `sha` | `String` | Hash SHA commit (40 karakter) |
| `message` | `String` | Pesan commit lengkap |
| `date` | `DateTime` | Waktu commit (dari `author.date`) |

**Computed property:** `title` → Baris pertama dari `message` (sebelum newline pertama).

**Dua factory constructor:**
- `Commit.fromJson()` — Parsing dari respons GitHub API langsung.
- `Commit.fromCacheJson()` — Parsing dari cache lokal (`SharedPreferences`).

---

### 7.3 `CommitDetail`

Detail lengkap satu commit, dimuat secara on-demand saat pengguna membuka detail commit.

| Field | Tipe | Keterangan |
|-------|------|------------|
| `sha` | `String` | Hash SHA commit |
| `additions` | `int` | Total baris ditambahkan di seluruh file |
| `deletions` | `int` | Total baris dihapus di seluruh file |
| `totalChanges` | `int` | Total perubahan (additions + deletions) |
| `files` | `List<CommitFile>` | Daftar file yang berubah |

---

### 7.4 `CommitFile`

Detail perubahan pada satu file dalam sebuah commit.

| Field | Tipe | Keterangan |
|-------|------|------------|
| `filename` | `String` | Path lengkap file relatif terhadap root repo |
| `status` | `String` | Status: `added`, `removed`, `modified`, `renamed` |
| `additions` | `int` | Baris ditambahkan pada file ini |
| `deletions` | `int` | Baris dihapus pada file ini |
| `changes` | `int` | Total perubahan pada file ini |

---

### 7.5 `AppSettings`

Pengaturan aplikasi yang dapat dikonfigurasi pengguna.

| Field | Tipe | Default | Keterangan |
|-------|------|---------|------------|
| `syncIntervalMinutes` | `int` | `60` | Interval background sync dalam menit |
| `languageCode` | `String` | `"id"` | Kode bahasa: `"id"` atau `"en"` |
| `themeMode` | `String` | `"system"` | Mode tema: `"system"`, `"light"`, `"dark"` |

**Persistensi:** Disimpan sebagai JSON object di `SharedPreferences` dengan key `app_settings`.

---

### 7.6 `GitHubCredentials`

Menyimpan kredensial GitHub untuk akses repositori privat.

| Field | Tipe | Keterangan |
|-------|------|------------|
| `username` | `String` | Username GitHub |
| `token` | `String` | Personal Access Token (PAT) |

**Keamanan:** Sebelum disimpan ke `SharedPreferences`, baik `username` maupun `token` di-encode menggunakan Base64. Saat membaca, keduanya di-decode kembali.

**Method `basicAuth`:** Menghasilkan header `Authorization: Basic <base64(username:token)>` untuk digunakan dalam GitHub API request.

---

### 7.7 `SyncLog`

Catatan satu sesi sinkronisasi yang berhasil mendeteksi pembaruan.

| Field | Tipe | Keterangan |
|-------|------|------------|
| `syncedAt` | `DateTime` | Waktu sinkronisasi dilakukan |
| `updates` | `Map<String, int>` | Peta `"owner/repo (branch)"` → jumlah commit baru |

**Computed properties:**
- `hasUpdates` → `true` jika `updates.isNotEmpty`
- `totalCommits` → Total semua commit baru dari semua repo pada sesi ini

**Persistensi:** Disimpan sebagai JSON array di `SharedPreferences` (key `sync_history`). Dibatasi maksimal 30 entri terbaru.

---

## 8. Layanan (Services)

### 8.1 `GitHubService`

Klien HTTP untuk berinteraksi dengan GitHub REST API v3.

**Endpoint yang Digunakan:**

| Method | Endpoint | Kegunaan |
|--------|----------|----------|
| GET | `/repos/{owner}/{repo}` | Mengambil metadata repositori |
| GET | `/repos/{owner}/{repo}/branches` | Mengambil daftar branch (paginated) |
| GET | `/repos/{owner}/{repo}/commits` | Mengambil daftar commit |
| GET | `/repos/{owner}/{repo}/commits/{sha}` | Mengambil detail satu commit |

**Request Headers:**
```
Accept: application/vnd.github+json
X-GitHub-Api-Version: 2022-11-28
Authorization: Basic <base64> (opsional, hanya jika 401/404)
```

**Metode Fetch Commit yang Tersedia:**

| Metode | Keterangan |
|--------|------------|
| `fetchCommits()` | Ambil maksimal `maxFetchedCommits` (20) commit terbaru, tanpa paginasi |
| `fetchLatestDayCommits()` | Ambil semua commit pada hari aktif terakhir saja |
| `fetchCommitsWithLimit()` | Ambil commit dengan batas jumlah tertentu (paginated) |
| `fetchCommitDetail()` | Ambil detail satu commit berdasarkan SHA |
| `fetchBranches()` | Ambil semua branch (paginated, 100 per halaman) |

---

### 8.2 `StorageService`

Lapisan abstraksi di atas `SharedPreferences` untuk semua operasi baca/tulis data lokal.

**Key-Value yang Dikelola:**

| Key | Tipe Data | Keterangan |
|-----|-----------|------------|
| `watched_repos` | `String` (JSON array) | Daftar repositori dipantau |
| `app_settings` | `String` (JSON object) | Pengaturan aplikasi |
| `github_credentials` | `String` (JSON object) | Kredensial GitHub (Base64) |
| `update_summary` | `String` (JSON object) | Ringkasan update sync terakhir |
| `sync_history` | `String` (JSON array) | Riwayat 30 sesi sync terakhir |
| `next_sync_at` | `String` (ISO 8601) | Estimasi waktu sync berikutnya |
| `last_sync_at` | `String` (ISO 8601) | Waktu sync terakhir berhasil |
| `commit_cache_{owner}_{repo}_{branch}_{syncMode}` | `String` (JSON array) | Cache commit per repo/branch |

**Commit Cache Strategy:**
- Cache disimpan per kombinasi `owner_repo_branch_syncMode`.
- `saveCachedCommits()`: Deduplikasi berdasarkan SHA, lalu sort descending berdasarkan tanggal. **Capping: Maksimal 1000 commit per repositori** untuk menjaga performa.
- `mergeCachedCommits()`: Menggabungkan commit baru ke cache yang ada.

---

### 8.3 `SyncService`

Orkestrasi logika pengecekan pembaruan commit. Dipanggil baik dari foreground maupun background worker.

**Alur `checkUpdates()`:**
1. Ambil semua repo yang dipantau dari `StorageService`.
2. Untuk setiap repo, panggil `GitHubService.fetchCommits()` (20 commit terbaru).
3. Bandingkan SHA commit terbaru dengan `repo.lastSha` tersimpan.
4. Jika berbeda, hitung jumlah commit baru (dengan `takeWhile` sampai SHA lama ditemukan).
5. Merge commit baru ke cache lokal.
6. Update `lastSha` dan `lastCommitAt` di objek repo.
7. Simpan kembali seluruh daftar repo yang telah diperbarui.
8. Jika ada pembaruan: buat `SyncLog`, simpan ke history, kirim notifikasi lokal.
9. Set `nextSyncAt` = sekarang + `syncIntervalMinutes`.
10. Return `Map<String, int>` berisi ringkasan pembaruan.

---

### 8.4 `NotificationService`

Mengelola notifikasi lokal menggunakan `flutter_local_notifications`.

**Konfigurasi:**
- Channel ID: `updates`
- Channel Name: `GitHub Updates`
- Importance: `HIGH`
- Ikon: `@mipmap/ic_launcher`

**Perilaku Notifikasi:**
- Jika hanya 1 repo yang update: judul `"Update di {repo}"`, body `"{repo}: +{N} commit"`.
- Jika lebih dari 1 repo: judul `"{N} repo ada update baru"`, body daftar semua repo (BigTextStyle).

**Deep Link:** Menekan notifikasi membuka `UpdateScreen` langsung.

**Mode Background vs Foreground:**
- Saat berjalan di background worker (`isBackground: true`), `onDidReceiveNotificationResponse` tidak diset untuk menghindari crash karena tidak ada `BuildContext`.

---

### 8.5 `StartupService`

Inisialisasi yang dijalankan saat aplikasi pertama kali dibuka.

**Tugas Startup:**
1. Inisialisasi `NotificationService` (minta izin notifikasi Android).
2. Inisialisasi `AndroidAlarmManager`.
3. Daftarkan background task secara idempotent (hanya jika belum terdaftar).
4. Tangani navigasi jika aplikasi dibuka dari notifikasi.

**`requestBatteryOptimizationExemption()`:** Mengarahkan pengguna ke pengaturan sistem Android untuk mengabaikan optimasi baterai, guna memastikan alarm berjalan presisi.

---

### 8.6 `AppSettingsController`

Singleton `ValueNotifier<AppSettings>` yang berfungsi sebagai state management global untuk pengaturan.

```dart
// Singleton global
final appSettingsController = AppSettingsController();
```

Method `update(AppSettings settings)` menyimpan settings ke `StorageService` dan memperbarui nilai `ValueNotifier`, sehingga semua `ValueListenableBuilder` yang mendengarkan otomatis rebuild.

---

## 9. Fitur & Spesifikasi Fungsional

### 9.1 F-01: Tambah Repositori

**Trigger:** Pengguna menekan FAB (+) di halaman utama.

**Pre-condition:** Jumlah repo yang dipantau < 5 (konstanta `maxWatchedRepos`).

**Alur:**
1. Pengguna memasukkan nama repo dalam format `owner/repo`.
2. Pengguna menekan tombol **Check**.
3. Aplikasi memanggil `GitHubService.getRepo()` untuk memvalidasi.
4. Jika berhasil, tampilkan kartu info repo (nama, branch default).
5. Aplikasi memanggil `GitHubService.fetchBranches()` dan populasi dropdown branch.
6. Pengguna memilih branch yang ingin dipantau.
7. Pengguna memilih mode sync (Minimal / 500 / 5000).
8. Pengguna menekan tombol **Tambahkan**.
9. Aplikasi menarik commit awal sesuai mode, membuat objek `WatchedRepo`, menyimpan ke storage.
10. Kembali ke halaman utama dengan repo baru muncul di daftar.

**Validasi:**
- Input tidak boleh kosong.
- Format wajib `owner/repo` (tepat satu `/`, kedua bagian tidak boleh kosong).
- Tidak boleh duplikat (`owner + repo + branch` yang sama).
- Jumlah repo tidak melebihi `maxWatchedRepos` = 5.

---

### 9.2 F-02: Hapus Repositori

**Metode 1 (Swipe):** Pengguna menggeser tile repo dari kanan ke kiri (`DismissDirection.endToStart`), muncul latar merah dengan ikon `delete_outline`, lalu tile dihapus dan snackbar konfirmasi ditampilkan.

**Metode 2 (Long-press/Context):** `RepoTile` menyediakan callback `onDelete` yang dapat dipanggil.

---

### 9.3 F-03: Sinkronisasi Manual

**Trigger:** Pull-to-Refresh di halaman utama atau auto-trigger saat aplikasi dibuka/resume. Selama sync berlangsung, indikator progres muncul di AppBar dan `SyncCard`.

---

### 9.4 F-04: Melihat Detail Commit

**Trigger:** Pengguna mengetuk kartu commit di `DetailScreen`.

**Tampilan:** Modal bottom sheet yang dapat di-drag (`DraggableScrollableSheet`), berisi:
- Short SHA (7 karakter pertama) sebagai judul besar.
- Pesan commit lengkap (selectable text).
- Tombol **Lihat Detail** untuk membuka commit di GitHub browser.
- Statistik total: jumlah file berubah, total additions (+), total deletions (-).
- Daftar file yang berubah, masing-masing menampilkan: ikon status, nama file, status string, additions, deletions.

**Ikon Status File:**
| Status | Ikon |
|--------|------|
| `added` | `add_circle_outline` (hijau) |
| `removed` | `remove_circle_outline` (merah/error) |
| `renamed` | `drive_file_rename_outline` (tersier) |
| lainnya | `edit_outlined` (primer) |

---

### 9.5 F-05: Riwayat Sinkronisasi

Menampilkan daftar `SyncLog` dari 30 sesi terakhir yang berhasil mendeteksi perubahan. Setiap kartu menampilkan: waktu sinkronisasi, total commit baru, dan rincian per repo.

Icon badge merah pada tombol notifikasi di AppBar `HomeScreen` muncul ketika ada update yang belum dilihat.

---

### 9.6 F-06: Pengaturan Kredensial

Pengguna dapat menyimpan `username` GitHub dan `Personal Access Token` untuk mengakses repositori privat. Token ditampilkan dalam field tersembunyi (obscured) dengan toggle visibilitas. Status kredensial ditampilkan sebagai "pill" berwarna:
- **Biru/Aktif:** Kredensial sudah tersimpan.
- **Abu/Kosong:** Belum ada kredensial.

---

### 9.7 F-07: Demo Mode Background Sync

Fitur "Extreme Precision" di halaman Settings memungkinkan pengguna memberikan izin pengecualian baterai secara manual. Ini krusial karena sistem Android sering menunda tugas latar belakang demi menghemat daya.

---

## 10. Spesifikasi Antarmuka (UI/UX)

### 10.1 Design System

- **Material Design 3** (`useMaterial3: true`) dengan `colorSchemeSeed: Colors.blue`.
- Background `HomeScreen` terang: `Color(0xFFF7F8FC)` (off-white).
- `CardTheme` dengan `elevation: 0` (flat card style) dengan border dari `outlineVariant`.
- Border radius konsisten: 14px (kartu commit), 16px (kartu settings), 12px (kartu general).

### 10.2 Tema

| Mode | Keterangan |
|------|------------|
| System | Mengikuti pengaturan sistem Android |
| Light | Brightness.light, background `0xFFF7F8FC` |
| Dark | Brightness.dark, default Material3 dark |

### 10.3 Komponen Kustom

**`RepoTile`** — Tile kartu untuk menampilkan satu repositori. Menampilkan: avatar circular owner (fallback ke ikon folder), nama repo, status publik/privat, nama branch, waktu commit terakhir.

**`_MetaChip`** — Chip kecil dengan ikon dan teks untuk menampilkan metadata (SHA, waktu commit). Background `surfaceContainerHighest`, teks `labelMedium`.

**`_ChangePill`** — Pill kecil berwarna untuk menampilkan jumlah additions (+, hijau) atau deletions (-, merah) pada suatu file.

**`_SettingsSection`** — Kartu section dengan header berikon untuk mengelompokkan pengaturan terkait.

**`_CredentialStatusPill`** — Pill status kredensial (Aktif/Kosong) di header section Private Access.

### 10.4 Empty States

- **Belum ada repo:** Ikon `folder_open_outlined` 64×64 dengan rounded corners, judul "Belum ada repo", subtitle ajakan menambahkan repo pertama.
- **Commit tidak ditemukan (setelah search):** Teks `commitNotFound` di tengah layar.
- **Belum ada riwayat sync:** Teks `noSyncHistory` di tengah layar.

---

## 11. Alur Navigasi Aplikasi

```
MainActivity
└── HomeScreen (root)
    ├── → AddRepoScreen (push, on FAB tap)
    │       └── ← pop(true) on success
    ├── → DetailScreen (push, on repo tile tap)
    │       └── CommitDetail BottomSheet (on commit card tap)
    ├── → UpdateScreen (push, on notification icon tap)
    └── → SettingsScreen (push, on settings icon tap)

Notification tap
└── → UpdateScreen (via navigatorKey.currentState?.push)
```

Aplikasi menggunakan `navigatorKey` global (`GlobalKey<NavigatorState>`) yang terdaftar di `MaterialApp` untuk memungkinkan navigasi dari luar widget tree (yaitu dari `NotificationService` ketika notifikasi ditekan saat app sudah terbuka).

---

## 12. Persyaratan Non-Fungsional

### 12.1 Performa
- Waktu muat halaman utama: < 500ms (data dibaca dari cache lokal).
- Akurasi sinkronisasi: ±1 menit (menggunakan Exact Alarm).
- Paginasi branch: 100 branch per request.
- Mode-Aware Sync: Mengambil jumlah commit sesuai kebutuhan mode (Minimal/500/5000) untuk akurasi data.

### 12.2 Keandalan
- Startup tidak boleh crash meski storage tidak tersedia (try-catch di `_bootstrap()`).
- Background worker me-return `false` jika terjadi error, memicu WorkManager retry sesuai backoff policy (linear, 5 menit).
- Sync per repo diisolasi: kegagalan satu repo tidak menghentikan sync repo lainnya.

### 12.3 Penggunaan Baterai
- WorkManager hanya memerlukan `networkType: NetworkType.connected` (tanpa `requiresBatteryNotLow` atau `requiresStorageNotLow` yang terlalu restriktif).
- `flexInterval` = 25% dari interval (min 5 menit, max 30 menit) untuk memberikan fleksibilitas eksekusi kepada sistem.

### 12.4 Penggunaan Data
- Credentials tidak pernah dikirim kecuali respons API adalah 401/404 (mengurangi overhead header).
- Cache commit disimpan lokal agar detail screen tidak perlu request API setiap dibuka.

### 12.5 Keamanan
- Token GitHub disimpan dalam Base64 (bukan plain text). **Catatan:** Base64 bukan enkripsi — untuk produksi disarankan menggunakan `flutter_secure_storage`.
- Tidak ada data sensitif yang dikirim ke server pihak ketiga selain GitHub API resmi.

---

## 13. Dependensi & Library

| Library | Versi | Kegunaan |
|---------|-------|----------|
| `http` | `^1.2.0` | HTTP client untuk GitHub API |
| `android_alarm_manager_plus` | `^4.0.0` | High-precision background scheduling |
| `flutter_local_notifications` | `^17.1.2` | Push notification lokal |
| `shared_preferences` | `^2.2.2` | Penyimpanan data persisten (key-value) |
| `android_intent_plus` | `^5.0.0` | Akses pengaturan sistem (Baterai) |
| `intl` | `^0.19.0` | Formatting tanggal dan waktu |
| `url_launcher` | `^6.3.1` | Membuka URL di browser eksternal |
| `flutter_lints` | `^3.0.0` | Analisis kode statis (dev dependency) |

**SDK Minimum:** Dart SDK `>=3.5.0 <4.0.0` (Flutter 3.24+)

---

## 14. Konfigurasi Platform Android

### 14.1 `AndroidManifest.xml` — Izin yang Diperlukan

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
```

### 14.2 Konfigurasi AlarmManager

- Didaftarkan via `AndroidAlarmManager.initialize()`.
- Fungsi `alarmCallback` di-annotate `@pragma('vm:entry-point')` dan dijalankan dalam Isolate terpisah dengan registrasi plugin manual (`DartPluginRegistrant`).

### 14.3 Notification Channel

- **Channel ID:** `updates`
- **Channel Name:** `GitHub Updates`
- **Importance:** `HIGH` (muncul di status bar dan sound)
- **Ikon notifikasi kustom:** `ic_stat_github` (vektor XML di `res/drawable/`)

### 14.4 App Icon

Icon aplikasi tersedia di semua densitas: `mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi` (termasuk versi round).

---

## 15. Penanganan Error & Edge Cases

| Skenario | Penanganan |
|----------|------------|
| Input repo kosong | Snackbar error: "Input repository tidak boleh kosong" |
| Format input salah | Snackbar error: "Format harus owner/repo" |
| Repo tidak ditemukan | Snackbar error: "Repository tidak ditemukan" |
| Koneksi gagal | Snackbar error: "Koneksi gagal. Cek internet lalu coba lagi." |
| Duplikat repo+branch | Snackbar error: "Repository dan branch sudah dipantau" |
| Maksimum 5 repo | Tombol FAB disembunyikan; snackbar jika dicoba |
| Gagal menambah repo | Snackbar error generik |
| Sync gagal (foreground) | Snackbar error: "Sync gagal" |
| Sync gagal per-repo (background) | Dilewati, repo tetap masuk daftar `updatedRepos` |
| Commit detail gagal dimuat | Widget `_CommitDetailError` dengan tombol retry |
| URL tidak bisa dibuka | Snackbar "Gagal membuka link" |
| Storage tidak tersedia saat startup | Di-catch, default settings digunakan |
| Background worker error | Return `false` → WorkManager retry sesuai backoff |
| `SharedPreferences` data korup | `try-catch` di tiap `fromJson`, fallback ke default |
| Base64 decode gagal | Return string kosong, credentials dianggap kosong |

---

## 16. Lokalisasi (i18n)

Aplikasi mendukung dua bahasa yang diimplementasikan melalui kelas `AppStrings` sederhana (bukan `flutter_localizations` resmi):

```dart
AppStrings stringsFor(String languageCode) => AppStrings(languageCode);
```

**Bahasa yang Didukung:**

| Kode | Bahasa |
|------|--------|
| `id` | Bahasa Indonesia (default) |
| `en` | English |

**Cakupan Lokalisasi:** Semua teks antarmuka pengguna, pesan error, label form, judul layar, pesan snackbar, dan teks kosong (empty state) tersedia dalam kedua bahasa.

**Perubahan bahasa** berlaku secara instan (reaktif melalui `ValueListenableBuilder`) tanpa perlu restart aplikasi.

---

## 17. Batasan & Limitasi

| Batasan | Nilai | Alasan |
|---------|-------|--------|
| Maksimal repositori dipantau | 5 | Menghindari terlalu banyak API request per sync |
| Commit ditampilkan saat sync cek update | 20 | Cukup untuk mendeteksi commit baru sejak sync terakhir |
| Riwayat sync disimpan | 30 entri | Membatasi penggunaan storage lokal |
| Commit mode Minimal | Hari terakhir saja | Hemat kuota API dan storage |
| Commit mode 500 | Maksimal 500 commit | Keseimbangan data vs performa |
| Commit mode 5000 | Maksimal 5000 commit | Untuk repo dengan history panjang |
| Interval sync minimum | ~15 menit | Batasan minimum WorkManager Android |
| Background sync | Bisa tertunda Android Doze | Keterbatasan sistem Android; diatasi dengan foreground checker |
| Keamanan token | Base64 (bukan enkripsi) | Versi beta; produksi disarankan `flutter_secure_storage` |
| GitHub API rate limit | 60 req/jam (unauthenticated), 5000 req/jam (authenticated) | Perlu dipertimbangkan pada mode Extended dengan banyak repo |

---

## 18. Rencana Pengujian

### 18.1 Unit Test
- Parsing `Commit.fromJson()` dari sample respons GitHub API.
- Parsing `AppSettings.fromJson()` termasuk edge case nilai tidak valid.
- `GitHubCredentials.basicAuth` menghasilkan header yang benar.
- `SyncLog.totalCommits` menghitung dengan benar.

### 18.2 Widget Test
- `HomeScreen` menampilkan empty state ketika tidak ada repo.
- `AddRepoScreen` menampilkan error saat input kosong.
- `HomeScreen` menampilkan FAB ketika jumlah repo < 5 dan menyembunyikannya saat = 5.

### 18.3 Integration / Manual Test
- Menambah repositori publik (`torvalds/linux`) → berhasil, commit muncul.
- Menambah repositori privat dengan PAT → berhasil, badge "Private" muncul.
- Swipe to delete repo → repo hilang dari daftar, snackbar muncul.
- Sync berhasil mendeteksi commit baru → notifikasi muncul.
- Mengganti bahasa → seluruh teks UI berubah tanpa restart.
- Mengganti tema ke Dark → seluruh layar menggunakan dark theme.
- Demo mode → notifikasi muncul setelah ±5 menit.
- Commit detail → statistik file tampil dengan benar.
- Pencarian commit dengan SHA parsial → filter berfungsi.

---

## 19. Kesimpulan

**GitHub Watcher** merupakan aplikasi Flutter Android yang mengimplementasikan sejumlah konsep penting dalam pemrograman mobile modern:

1. **Integrasi API REST** — Mengonsumsi GitHub REST API v3 dengan mekanisme autentikasi fallback yang elegan (publik → privat secara transparan).

2. **High-Precision Background Processing** — Memanfaatkan `AndroidAlarmManager` untuk menjalankan task periodik dengan akurasi tinggi, didukung oleh izin `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` untuk performa "Extreme Precision".

3. **Notifikasi Lokal** — Menggunakan `flutter_local_notifications` dengan konfigurasi channel yang tepat, termasuk deep link navigasi ke halaman riwayat.

4. **Persistensi & Caching Cerdas** — Semua data disimpan lokal dengan serialisasi JSON. Implementasi *Commit Capping* (1000 entri) menjaga performa jangka panjang.

5. **Keamanan Dasar** — Kredensial disimpan dalam Base64 sebagai lapisan obfuskasi minimal.

6. **Arsitektur Bersih** — Pemisahan yang jelas antara model, service, screen, dan widget. Penggunaan `ValueNotifier` untuk state management global yang sederhana namun efektif.

7. **UX yang Baik** — Material Design 3, dark mode, lokalisasi bilingual, empty states informatif, loading states yang jelas, dan penanganan error yang komprehensif melalui snackbar.

Aplikasi ini memenuhi seluruh kriteria yang ditetapkan sebagai tugas pemrograman mobile dan mendemonstrasikan penguasaan ekosistem Flutter secara menyeluruh.

---

*Dokumen ini dibuat berdasarkan analisis source code `git-watcher-main` dan mencerminkan kondisi implementasi aktual per tanggal 15 Mei 2026.*
