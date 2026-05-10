import 'constants.dart';

class AppStrings {
  final String code;

  const AppStrings(this.code);

  bool get isEnglish => code == languageEnglish;

  String get appTitle => 'GitHub Watcher';
  String get history => isEnglish ? 'Sync History' : 'Riwayat Sinkron';
  String get settings => isEnglish ? 'Settings' : 'Pengaturan';
  String get watchedRepos =>
      isEnglish ? 'Watched repositories' : 'Repo Dipantau';
  String repoCount(int count) => isEnglish
      ? '$count of $maxWatchedRepos slots used'
      : '$count dari $maxWatchedRepos slot terpakai';
  String get homeSubtitle => isEnglish
      ? 'Keep an eye on recent commits across public and private repositories.'
      : 'Pantau commit terbaru dari repo publik dan privat.';
  String get nextSync => isEnglish ? 'Next sync' : 'Sync berikutnya';
  String get normalInterval =>
      isEnglish ? 'Normal interval' : 'Interval normal';
  String get demoIntervalActive =>
      isEnglish ? 'Demo interval active' : 'Interval demo aktif';
  String get demoModeActive =>
      isEnglish ? 'Demo Mode Active' : 'Demo Mode Aktif';
  String get demoMode => isEnglish ? 'Demo Mode' : 'Demo Mode';
  String get demoModeSubtitle => isEnglish
      ? 'Show countdown on Home and allow faster sync.'
      : 'Tampilkan countdown di Home dan aktifkan sync lebih cepat.';
  String get language => isEnglish ? 'Language' : 'Bahasa';
  String get theme => isEnglish ? 'Theme' : 'Tema';
  String get systemTheme => isEnglish ? 'System' : 'Sistem';
  String get lightTheme => isEnglish ? 'Light' : 'Terang';
  String get darkTheme => isEnglish ? 'Dark' : 'Gelap';
  String get syncInterval => isEnglish ? 'Sync interval' : 'Interval Sync';
  String minutes(int value) => isEnglish ? '$value minutes' : '$value menit';
  String get oneHour => isEnglish ? '1 hour' : '1 jam';
  String get syncNow => isEnglish ? 'Sync Now' : 'Sinkronkan Sekarang';
  String get noRepos =>
      isEnglish ? 'No watched repos yet' : 'Belum ada repo dipantau';
  String repoDeleted(String repo) =>
      isEnglish ? '$repo deleted' : '$repo dihapus';
  String get maxRepos => isEnglish
      ? 'Maximum $maxWatchedRepos repos can be watched'
      : 'Maksimal $maxWatchedRepos repo dapat dipantau';
  String get addRepo => isEnglish ? 'Add repo' : 'Tambah repo';
  String get openSettings => isEnglish ? 'Open settings' : 'Buka pengaturan';
  String get noReposTitle =>
      isEnglish ? 'No repositories yet' : 'Belum ada repo';
  String get noReposSubtitle => isEnglish
      ? 'Add a repository to start watching commit activity.'
      : 'Tambahkan repository untuk mulai memantau aktivitas commit.';
  String get noUpdates =>
      isEnglish ? 'No new updates' : 'Tidak ada update baru';
  String reposHaveUpdates(int count) => isEnglish
      ? '$count repo${count == 1 ? '' : 's'} have updates'
      : '$count repo memiliki update';
  String get syncFailed => isEnglish
      ? 'Sync failed. Check your internet connection.'
      : 'Sinkronisasi gagal. Cek koneksi internet.';

  // Private mode
  String get privateMode => isEnglish ? 'Private Mode' : 'Mode Privat';
  String get privateModeSubtitle => isEnglish
      ? 'Use credentials to access private repositories.'
      : 'Gunakan kredensial untuk mengakses repo privat.';
  String get githubUsername =>
      isEnglish ? 'GitHub Username' : 'Username GitHub';
  String get githubToken =>
      isEnglish ? 'Personal Access Token' : 'Personal Access Token';
  String get githubTokenHelper => isEnglish
      ? 'Token is stored encoded on this device only.'
      : 'Token disimpan terenkode di perangkat ini saja.';
  String get credentialsSaved =>
      isEnglish ? 'Credentials saved' : 'Kredensial disimpan';
  String get credentialsCleared =>
      isEnglish ? 'Credentials cleared' : 'Kredensial dihapus';
  String get saveCredentials => isEnglish ? 'Save' : 'Simpan';
  String get clearCredentials => isEnglish ? 'Clear' : 'Hapus';
  String get credentialsActive =>
      isEnglish ? 'Credentials saved' : 'Kredensial tersimpan';
  String get credentialsEmpty =>
      isEnglish ? 'No credentials saved' : 'Belum ada kredensial';
  String get appearance => isEnglish ? 'Appearance' : 'Tampilan';
  String get syncAndDemo => isEnglish ? 'Sync & demo' : 'Sync & demo';
  String get privateAccess =>
      isEnglish ? 'Private repository access' : 'Akses repo privat';
  String get aboutApp => isEnglish ? 'About app' : 'Tentang aplikasi';
  String get aboutAppSubtitle => isEnglish
      ? 'Version, description, and platform target.'
      : 'Versi, deskripsi, dan target platform.';
  String get appDescription => isEnglish
      ? 'A lightweight GitHub watcher for tracking recent commits, update notifications, and private repository access from one device.'
      : 'GitHub Watcher ringan untuk memantau commit terbaru, notifikasi update, dan akses repo privat dari satu perangkat.';
  String get version => isEnglish ? 'Version' : 'Versi';
  String get build => isEnglish ? 'Build' : 'Build';
  String get androidApiSupport =>
      isEnglish ? 'Android API 29-36' : 'Android API 29-36';
  String get close => isEnglish ? 'Close' : 'Tutup';
}

AppStrings stringsFor(String code) => AppStrings(code);
