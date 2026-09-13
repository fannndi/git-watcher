const String appName = 'GitHub Watcher';
const String appVersionName = '1.0.0';
const String appBuildNumber = '2';
const String appReleaseChannel = 'Beta';
const String developerName = 'alisa';
const String developerUrl = 'https://github.com/fannndi';
const String appId = 'com.ti24a4.app32';

const int maxWatchedRepos = 5;
const int maxFetchedCommits = 20;
const int maxCachedCommits = 1000;
const int maxSyncHistory = 30;
const int githubPageSize = 100;
const int backgroundSyncFetchLimit = 100;
const int defaultSyncIntervalMinutes = 60;

const String syncModeMinimal = 'minimal';
const String syncModeLatest = 'latest_500';
const String syncModeExtended = 'extended_5000';
const int latestSyncCommitLimit = 500;
const int extendedSyncCommitLimit = 5000;

const String languageIndonesian = 'id';
const String languageEnglish = 'en';
const String themeModeSystem = 'system';
const String themeModeLight = 'light';
const String themeModeDark = 'dark';

const String githubApiHost = 'api.github.com';
const String githubWebHost = 'github.com';
const String githubApiVersion = '2022-11-28';
const String githubAcceptHeader = 'application/vnd.github+json';
const Duration apiTimeout = Duration(seconds: 30);
const Duration foregroundSyncDebounce = Duration(seconds: 20);
const Duration syncLockTimeout = Duration(minutes: 10);
const Duration backgroundSyncTimeout = Duration(minutes: 8);

const String watchedReposKey = 'watched_repos';
const String appSettingsKey = 'app_settings';
const String syncHistoryKey = 'sync_history';
const String lastSyncAtKey = 'last_sync_at';
const String syncLockKey = 'sync_lock';
const String githubCredentialsKey = 'github_credentials';
const String commitCachePrefix = 'commit_cache_';
const String alarmRegisteredKey = 'alarm_registered';
const String hasSeenTourKey = 'has_seen_tour';

const String notificationChannelId = 'updates';
const String notificationChannelName = 'GitHub Updates';
const int updateNotificationId = 1;

const int alarmId = 42;
const Duration alarmInterval = Duration(hours: 1);
const Duration alarmInitialDelay = Duration(minutes: 15);
