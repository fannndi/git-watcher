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
  String get language => isEnglish ? 'Language' : 'Bahasa';
  String get theme => isEnglish ? 'Theme' : 'Tema';
  String get systemTheme => isEnglish ? 'System' : 'Sistem';
  String get lightTheme => isEnglish ? 'Light' : 'Terang';
  String get darkTheme => isEnglish ? 'Dark' : 'Gelap';
  String get syncSettings => isEnglish ? 'Sync' : 'Sinkronisasi';
  String get syncInterval =>
      isEnglish ? 'Background sync interval' : 'Interval sync background';
  String minutes(int value) => isEnglish ? '$value minutes' : '$value menit';
  String get oneHour => isEnglish ? '1 hour' : '1 jam';
  String get twoHours => isEnglish ? '2 hours' : '2 jam';
  String get syncNow => isEnglish ? 'Sync Now' : 'Sync Sekarang';
  String get lastSync => isEnglish ? 'Last sync' : 'Sinkron terakhir';
  String get never => isEnglish ? 'Never' : 'Belum pernah';
  String get nextSyncAuto => isEnglish
      ? 'Background sync runs automatically'
      : 'Sync background berjalan otomatis';
  String get noRepos =>
      isEnglish ? 'No watched repos yet' : 'Belum ada repo dipantau';
  String repoDeleted(String repo) =>
      isEnglish ? '$repo deleted' : '$repo dihapus';
  String get deleteRepo => isEnglish ? 'Delete repo' : 'Hapus repo';
  String get maxRepos => isEnglish
      ? 'Maximum $maxWatchedRepos repos can be watched'
      : 'Maksimal $maxWatchedRepos repo dapat dipantau';
  String get addRepo => isEnglish ? 'Add repo' : 'Tambah repo';
  String get openSettings => isEnglish ? 'Open settings' : 'Buka pengaturan';
  String get repository => isEnglish ? 'Repository' : 'Repository';
  String get repositoryInputHelper => isEnglish
      ? 'Use owner/repo format, for example: torvalds/linux'
      : 'Masukkan format owner/repo, contoh: torvalds/linux';
  String get check => isEnglish ? 'Check' : 'Check';
  String get repositoryFound =>
      isEnglish ? 'Repository found' : 'Repository ditemukan';
  String get defaultBranch => isEnglish ? 'Default branch' : 'Branch default';
  String get watchedBranch => isEnglish ? 'Watched branch' : 'Branch Dipantau';
  String get branch => isEnglish ? 'Branch' : 'Branch';
  String get publicRepo => isEnglish ? 'Public' : 'Public';
  String get privateRepo => isEnglish ? 'Private' : 'Private';
  String get lastUpdate => isEnglish ? 'Last update' : 'Update terakhir';
  String get today => isEnglish ? 'Today' : 'Today';
  String get neverSynced => isEnglish ? 'Not synced yet' : 'Belum sinkron';
  String get syncMode => isEnglish ? 'Sync mode' : 'Mode Sync';
  String get add => isEnglish ? 'Add' : 'Tambahkan';
  String get emptyRepositoryInput => isEnglish
      ? 'Repository input cannot be empty'
      : 'Input repository tidak boleh kosong';
  String get invalidRepositoryFormat =>
      isEnglish ? 'Format must be owner/repo' : 'Format harus owner/repo';
  String get repositoryNotFound =>
      isEnglish ? 'Repository not found' : 'Repository tidak ditemukan';
  String get connectionFailed => isEnglish
      ? 'Connection failed. Check your internet and try again.'
      : 'Koneksi gagal. Cek internet lalu coba lagi.';
  String get duplicateRepository => isEnglish
      ? 'Repository and branch are already watched'
      : 'Repository dan branch sudah dipantau';
  String get addRepositoryFailed => isEnglish
      ? 'Failed to add repo. Check your internet connection.'
      : 'Gagal menambahkan repo. Cek koneksi internet.';
  String get minimalSyncDescription => isEnglish
      ? 'Store commits from the latest date.'
      : 'Simpan commit pada tanggal terbaru.';
  String get latestSyncDescription => isEnglish
      ? 'Store up to the latest 500 commits.'
      : 'Simpan maksimal 500 commit terbaru.';
  String get extendedSyncDescription => isEnglish
      ? 'Store up to the latest 5000 commits.'
      : 'Simpan maksimal 5000 commit terbaru.';
  String get largeSyncWarning => isEnglish
      ? 'Large modes can take longer and may hit GitHub rate limits.'
      : 'Mode besar dapat memerlukan waktu lebih lama dan terkena rate limit GitHub.';
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
  String get fetchCommitsFailed => isEnglish
      ? 'Failed to fetch latest commits'
      : 'Gagal mengambil commit terbaru';
  String get clearSearch => isEnglish ? 'Clear search' : 'Bersihkan pencarian';
  String get searchCommit => isEnglish ? 'Search commit' : 'Cari commit';
  String get searchCommitHelper => isEnglish
      ? 'Search by message or SHA'
      : 'Cari berdasarkan message atau SHA';
  String get commitNotFound =>
      isEnglish ? 'No commits found' : 'Commit tidak ditemukan';
  String changedFiles(int count) =>
      isEnglish ? '$count changed files' : '$count file berubah';
  String get noFileDetail => isEnglish
      ? 'No file detail from GitHub API.'
      : 'Tidak ada detail file dari GitHub API.';
  String get fetchCommitDetailFailed => isEnglish
      ? 'Failed to fetch commit file details.'
      : 'Gagal mengambil detail file commit.';
  String get tryAgain => isEnglish ? 'Try again' : 'Coba lagi';

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
  String get usernameTokenRequired => isEnglish
      ? 'Username and token cannot be empty'
      : 'Username dan token tidak boleh kosong';
  String get show => isEnglish ? 'Show' : 'Tampilkan';
  String get hide => isEnglish ? 'Hide' : 'Sembunyikan';
  String get saveCredentials => isEnglish ? 'Save' : 'Simpan';
  String get clearCredentials => isEnglish ? 'Clear' : 'Hapus';
  String get credentialsActive =>
      isEnglish ? 'Credentials saved' : 'Kredensial tersimpan';
  String get credentialsEmpty =>
      isEnglish ? 'No credentials saved' : 'Belum ada kredensial';
  String get appearance => isEnglish ? 'Appearance' : 'Tampilan';
  String get privateAccess =>
      isEnglish ? 'Private repository access' : 'Akses repo privat';
  String get aboutApp => isEnglish ? 'About app' : 'Tentang aplikasi';
  String get aboutAppSubtitle => isEnglish
      ? 'Version, release channel, and developer.'
      : 'Versi, channel rilis, dan developer.';
  String get appDescription => isEnglish
      ? 'A lightweight GitHub watcher for tracking recent commits, update notifications, and private repository access from one device.'
      : 'GitHub Watcher ringan untuk memantau commit terbaru, notifikasi update, dan akses repo privat dari satu perangkat.';
  String get version => isEnglish ? 'Version' : 'Versi';
  String get channel => isEnglish ? 'Channel' : 'Channel';
  String get developer => isEnglish ? 'Developer' : 'Developer';
  String get seeDetail => isEnglish ? 'See detail' : 'See detail';
  String get openLinkFailed =>
      isEnglish ? 'Could not open link' : 'Gagal membuka link';
  String get close => isEnglish ? 'Close' : 'Tutup';
  String get noSyncHistory =>
      isEnglish ? 'No sync results yet' : 'Belum ada hasil sinkron';
  String get noNewCommits =>
      isEnglish ? 'No new commits' : 'Tidak ada commit baru';
  String get notSynced =>
      isEnglish ? 'Not synced yet' : 'Belum tersinkron';

  // Sync section
  String get syncEveryHour => isEnglish
      ? 'Background Sync: Every 1 hour'
      : 'Sync Latar Belakang: Setiap 1 jam';

  String get syncingNow => isEnglish ? 'Syncing...' : 'Sinkronisasi...';

  // Extreme Precision
  String get extremePrecision =>
      isEnglish ? 'Extreme Precision' : 'Presisi Ekstrem';
  String get extremePrecisionDesc => isEnglish
      ? 'Ensures sync runs exactly every 1 hour, even when the phone is idle for a long time. Requires battery exemption.'
      : 'Memastikan sync berjalan tepat setiap 1 jam, meskipun HP diam lama. Membutuhkan izin baterai.';
  String get allowBatteryExemption => isEnglish
      ? 'Allow Battery Exemption'
      : 'Izinkan Pengecualian Baterai';
}

AppStrings stringsFor(String code) => AppStrings(code);
