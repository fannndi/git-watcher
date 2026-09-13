import 'constants.dart';

class AppStrings {
  const AppStrings(this.code);

  final String code;

  bool get isEnglish => code == languageEnglish;

  String get appTitle => appName;
  String get settings => isEnglish ? 'Settings' : 'Pengaturan';
  String get history => isEnglish ? 'Sync History' : 'Riwayat Sinkron';
  String get syncNow => isEnglish ? 'Sync now' : 'Sync sekarang';
  String repoCount(int count) => isEnglish
      ? '$count of $maxWatchedRepos slots used'
      : '$count dari $maxWatchedRepos slot terpakai';
  String get lastSync => isEnglish ? 'Last sync' : 'Sinkron terakhir';
  String get never => isEnglish ? 'Never' : 'Belum pernah';
  String get syncing => isEnglish ? 'Syncing' : 'Menyinkronkan';
  String get undo => isEnglish ? 'Undo' : 'Urungkan';
  String get shaCopied => isEnglish ? 'SHA copied' : 'SHA disalin';
  String get openInBrowser => isEnglish ? 'Open in browser' : 'Buka di browser';
  String get copyLink => isEnglish ? 'Copy link' : 'Salin tautan';
  String get linkCopied => isEnglish ? 'Link copied' : 'Tautan disalin';
  String get muteRepo =>
      isEnglish ? 'Mute notifications' : 'Bisukan notifikasi';
  String get unmuteRepo =>
      isEnglish ? 'Unmute notifications' : 'Aktifkan notifikasi';
  String repoMuted(String repo) =>
      isEnglish ? '$repo muted' : '$repo dibisukan';
  String repoUnmuted(String repo) =>
      isEnglish ? '$repo unmuted' : 'Notifikasi $repo aktif';
  String get search => isEnglish ? 'Search' : 'Cari';
  String get closeSearch => isEnglish ? 'Close search' : 'Tutup pencarian';
  String get searchRepo => isEnglish ? 'Search repo...' : 'Cari repo...';
  String get offline => isEnglish ? 'Offline' : 'Offline';
  String get refresh => isEnglish ? 'Refresh' : 'Muat ulang';
  String get close => isEnglish ? 'Close' : 'Tutup';
  String get cancel => isEnglish ? 'Cancel' : 'Batal';
  String get delete => isEnglish ? 'Delete' : 'Hapus';
  String get tryAgain => isEnglish ? 'Try again' : 'Coba lagi';
  String get openLinkFailed =>
      isEnglish ? 'Could not open link' : 'Gagal membuka link';

  String get noReposTitle =>
      isEnglish ? 'No repositories yet' : 'Belum ada repo';
  String get noReposSubtitle => isEnglish
      ? 'Add a repository to start watching commit activity.'
      : 'Tambahkan repository untuk mulai memantau aktivitas commit.';
  String get noSearchResults =>
      isEnglish ? 'No repo matches your search' : 'Tidak ada repo yang cocok';
  String get addRepo => isEnglish ? 'Add repo' : 'Tambah repo';
  String repoDeleted(String repo) =>
      isEnglish ? '$repo deleted' : '$repo dihapus';
  String get confirmDelete => isEnglish ? 'Confirm Delete' : 'Konfirmasi Hapus';
  String confirmDeleteRepo(String repo) => isEnglish
      ? 'Remove $repo from watched list?'
      : 'Hapus $repo dari daftar pantauan?';
  String reposHaveUpdates(int count) => isEnglish
      ? '$count repo${count == 1 ? '' : 's'} have updates'
      : '$count repo memiliki update';
  String get syncFailed => isEnglish
      ? 'Sync failed. Check your internet connection.'
      : 'Sinkronisasi gagal. Cek koneksi internet.';
  String get loadReposFailed =>
      isEnglish ? 'Failed to load repos' : 'Gagal memuat repo';
  String updateAvailable(String version) =>
      isEnglish ? 'Update available: v$version' : 'Update tersedia: v$version';
  String get updateAction => isEnglish ? 'Update' : 'Perbarui';

  String get repository => isEnglish ? 'Repository' : 'Repository';
  String get repositoryInputHelper => isEnglish
      ? 'Use owner/repo format, for example: torvalds/linux'
      : 'Masukkan format owner/repo, contoh: torvalds/linux';
  String get paste => isEnglish ? 'Paste' : 'Tempel';
  String get check => 'Check';
  String get repositoryFound =>
      isEnglish ? 'Repository found' : 'Repository ditemukan';
  String get defaultBranch => isEnglish ? 'Default branch' : 'Branch default';
  String get watchedBranch => isEnglish ? 'Watched branch' : 'Branch Dipantau';
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
  String get maxRepos => isEnglish
      ? 'Maximum $maxWatchedRepos repos can be watched'
      : 'Maksimal $maxWatchedRepos repo dapat dipantau';

  String get publicRepo => isEnglish ? 'Public' : 'Public';
  String get privateRepo => isEnglish ? 'Private' : 'Private';
  String get notSynced => isEnglish ? 'Not synced yet' : 'Belum tersinkron';

  String get shareRepo => isEnglish ? 'Open repository' : 'Buka repository';
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
  String get seeDetail => isEnglish ? 'See detail' : 'Lihat detail';
  String commitCount(int count) =>
      isEnglish ? '$count commits' : '$count commit';
  String stars(int count) => isEnglish ? '$count stars' : '$count bintang';

  String get appearance => isEnglish ? 'Appearance' : 'Tampilan';
  String get language => isEnglish ? 'Language' : 'Bahasa';
  String get systemTheme => isEnglish ? 'System' : 'Sistem';
  String get lightTheme => isEnglish ? 'Light' : 'Terang';
  String get darkTheme => isEnglish ? 'Dark' : 'Gelap';
  String get privateAccess =>
      isEnglish ? 'Private repository access' : 'Akses repo privat';
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
  String get syncSettings => isEnglish ? 'Sync' : 'Sinkronisasi';
  String get syncInterval =>
      isEnglish ? 'Background sync interval' : 'Interval sync background';
  String minutes(int value) => isEnglish ? '$value minutes' : '$value menit';
  String get syncIntervalHelper => isEnglish
      ? 'Exact alarms may still be delayed by battery optimization.'
      : 'Alarm exact tetap dapat tertunda oleh optimasi baterai.';
  String get enableNotifications =>
      isEnglish ? 'Enable Notifications' : 'Aktifkan Notifikasi';
  String get enableNotificationsDesc => isEnglish
      ? 'Receive push notifications for new commits and updates.'
      : 'Terima notifikasi push untuk commit dan update baru.';
  String get testNotification =>
      isEnglish ? 'Send test notification' : 'Kirim notifikasi uji';
  String get wifiOnly =>
      isEnglish ? 'Sync on Wi-Fi only' : 'Sync hanya via Wi-Fi';
  String get wifiOnlyDesc => isEnglish
      ? 'Skip scheduled syncs on mobile data.'
      : 'Lewati sync terjadwal saat memakai data seluler.';
  String get quietHours => isEnglish ? 'Quiet hours' : 'Jam tenang';
  String get quietHoursDesc => isEnglish
      ? 'No syncs during these hours; the first sync after wakes up with a morning digest.'
      : 'Tidak ada sync di jam ini; sync pertama setelahnya dikirim sebagai digest pagi.';
  String get quietStart => isEnglish ? 'Start' : 'Mulai';
  String get quietEnd => isEnglish ? 'End' : 'Selesai';
  String hourLabel(int hour) => '${hour.toString().padLeft(2, '0')}:00';
  String morningDigestTitle(int count) => isEnglish
      ? 'Good morning — $count repo${count == 1 ? '' : 's'} updated'
      : 'Selamat pagi — $count repo update';
  String get testNotificationTitle =>
      isEnglish ? 'Test notification' : 'Notifikasi uji';
  String get testNotificationBody => isEnglish
      ? 'If you can see this, notifications work on this device.'
      : 'Jika Anda melihat ini, notifikasi berfungsi di perangkat ini.';
  String get notificationsBlocked => isEnglish
      ? 'Notifications are blocked in system settings.'
      : 'Notifikasi diblokir di pengaturan sistem.';
  String get extremePrecision =>
      isEnglish ? 'Extreme Precision' : 'Presisi Ekstrem';
  String get extremePrecisionDesc => isEnglish
      ? 'Keeps sync alarms precise at your chosen interval, even when the phone is idle. Requires battery exemption.'
      : 'Memastikan alarm sync berjalan presisi sesuai interval pilihan, meskipun HP diam lama. Membutuhkan izin baterai.';
  String get allowBatteryExemption =>
      isEnglish ? 'Allow Battery Exemption' : 'Izinkan Pengecualian Baterai';
  String get aboutApp => isEnglish ? 'About app' : 'Tentang aplikasi';
  String get appDescription => isEnglish
      ? 'A lightweight GitHub watcher for tracking recent commits, update notifications, and private repository access from one device.'
      : 'GitHub Watcher ringan untuk memantau commit terbaru, notifikasi update, dan akses repo privat dari satu perangkat.';
  String get version => isEnglish ? 'Version' : 'Versi';
  String get channel => isEnglish ? 'Channel' : 'Channel';
  String get developer => isEnglish ? 'Developer' : 'Developer';
  String get rateApp => isEnglish ? 'Rate App' : 'Beri Nilai';
  String get rateAppDesc => isEnglish
      ? 'Rate this app on Google Play Store'
      : 'Beri nilai aplikasi ini di Google Play Store';

  String get noSyncHistory =>
      isEnglish ? 'No sync results yet' : 'Belum ada hasil sinkron';
  String get clearHistory =>
      isEnglish ? 'Clear sync history' : 'Hapus riwayat sinkron';
  String get historyCleared =>
      isEnglish ? 'Sync history cleared' : 'Riwayat sinkron dihapus';
  String get clearHistoryConfirm => isEnglish
      ? 'Remove all sync history entries?'
      : 'Hapus semua entri riwayat sinkron?';
  String get noNewCommits =>
      isEnglish ? 'No new commits' : 'Tidak ada commit baru';

  String get tourWelcome => isEnglish
      ? 'Track your favorite GitHub repos easily!'
      : 'Pantau repo GitHub favoritmu dengan mudah!';
  String get tourAddRepo =>
      isEnglish ? 'Tap + to add a repo' : 'Tekan + untuk menambah repo';
  String get tourSync => isEnglish
      ? 'Pull down to sync updates'
      : 'Tarik ke bawah untuk sinkron update';
  String get tourSwipe =>
      isEnglish ? 'Swipe left to delete' : 'Geser kiri untuk menghapus';
  String get tourGotIt => isEnglish ? 'Got it!' : 'Mengerti!';

  String notificationTitle(String repo) =>
      isEnglish ? 'Update in $repo' : 'Update di $repo';
  String notificationTitleMultiple(int count) =>
      isEnglish ? '$count repos have updates' : '$count repo ada update baru';
  String notificationLine(String repo, int count) =>
      '$repo: +$count commit${count == 1 ? '' : 's'}';
  String notificationMore(int count) =>
      isEnglish ? '+$count more' : '+$count lainnya';
  String notificationCommitLine(String title, String author) =>
      author.isEmpty ? '• $title' : '• $title — $author';

  String timeAgo(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inMinutes < 1) {
      return isEnglish ? 'just now' : 'baru saja';
    }
    if (difference.inHours < 1) {
      return isEnglish
          ? '${difference.inMinutes}m ago'
          : '${difference.inMinutes} mnt lalu';
    }
    if (difference.inDays < 1) {
      return isEnglish
          ? '${difference.inHours}h ago'
          : '${difference.inHours} jam lalu';
    }
    if (difference.inDays < 30) {
      return isEnglish
          ? '${difference.inDays}d ago'
          : '${difference.inDays} hari lalu';
    }
    if (difference.inDays < 365) {
      final months = difference.inDays ~/ 30;
      return isEnglish ? '${months}mo ago' : '$months bln lalu';
    }
    final years = difference.inDays ~/ 365;
    return isEnglish ? '${years}y ago' : '$years thn lalu';
  }
}

AppStrings stringsFor(String code) => AppStrings(code);
