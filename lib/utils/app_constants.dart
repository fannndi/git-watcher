/// App-wide constants
class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'GitHub Watcher';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '2';
  static const String appDescription =
      'A lightweight GitHub watcher for tracking recent commits, '
      'update notifications, and private repository access from one device.';

  // URLs
  static const String githubApiBase = 'https://api.github.com';
  static const String githubWebBase = 'https://github.com';
  static const String developerUrl = 'https://github.com/fannndi';

  // Limits
  static const int maxWatchedRepos = 5;
  static const int maxFetchedCommits = 20;
  static const int maxCachedCommits = 1000;
  static const int maxSyncHistory = 30;
  static const int defaultSyncIntervalMinutes = 60;

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration syncTimeout = Duration(minutes: 8);
  static const Duration debounceDelay = Duration(seconds: 20);
  static const Duration lockTimeout = Duration(minutes: 10);

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 100);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 800);

  // Sync modes
  static const String syncModeMinimal = 'minimal';
  static const String syncModeLatest = 'latest_500';
  static const String syncModeExtended = 'extended_5000';

  // Commit limits per mode
  static const int minimalSyncLimit = 20;
  static const int latestSyncLimit = 500;
  static const int extendedSyncLimit = 5000;

  // Storage keys
  static const String keyWatchedRepos = 'watched_repos';
  static const String keyAppSettings = 'app_settings';
  static const String keyGithubCredentials = 'github_credentials';
  static const String keyUpdateSummary = 'update_summary';
  static const String keySyncHistory = 'sync_history';
  static const String keyLastSyncAt = 'last_sync_at';
  static const String keyAlarmRegistered = 'alarm_registered';

  // Notification
  static const String notificationChannelId = 'updates';
  static const String notificationChannelName = 'GitHub Updates';
  static const int notificationId = 1;
  static const int testNotificationId = 99;

  // Alarm
  static const int alarmId = 42;
  static const Duration alarmInterval = Duration(hours: 1);
  static const Duration alarmInitialDelay = Duration(minutes: 15);
}
