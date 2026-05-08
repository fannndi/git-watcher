import 'constants.dart';

class AppStrings {
  final String code;

  const AppStrings(this.code);

  bool get isEnglish => code == languageEnglish;

  String get appTitle => 'GitHub Watcher';
  String get history => isEnglish ? 'Sync History' : 'Riwayat Sinkron';
  String get settings => isEnglish ? 'Settings' : 'Pengaturan';
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
      ? 'Maximum 3 repos can be watched'
      : 'Maksimal 3 repo dapat dipantau';
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
  String get githubUsername => isEnglish ? 'GitHub Username' : 'Username GitHub';
  String get githubToken => isEnglish ? 'Personal Access Token' : 'Personal Access Token';
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
}

AppStrings stringsFor(String code) => AppStrings(code);