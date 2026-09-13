import 'package:flutter_test/flutter_test.dart';
import 'package:git_watcher/models/app_settings.dart';
import 'package:git_watcher/models/commit.dart';
import 'package:git_watcher/models/github_credentials.dart';
import 'package:git_watcher/models/sync_log.dart';
import 'package:git_watcher/models/watched_repo.dart';
import 'package:git_watcher/utils/constants.dart';

void main() {
  group('Commit', () {
    test('fromJson parses GitHub API response', () {
      final commit = Commit.fromJson({
        'sha': 'abc123def456',
        'commit': {
          'message': 'Fix bug\n\nDetailed description',
          'author': {'date': '2024-01-15T10:30:00Z'},
        },
      });

      expect(commit.sha, 'abc123def456');
      expect(commit.message, 'Fix bug\n\nDetailed description');
      expect(commit.title, 'Fix bug');
      expect(commit.date, DateTime.parse('2024-01-15T10:30:00Z'));
    });

    test('fromJson tolerates missing fields', () {
      final commit = Commit.fromJson(const {});

      expect(commit.sha, '');
      expect(commit.message, '');
      expect(commit.title, '');
      expect(commit.author, '');
    });

    test('fromJson prefers GitHub login, falls back to git author name', () {
      final withLogin = Commit.fromJson({
        'sha': 'abc',
        'commit': {
          'message': 'Fix',
          'author': {'name': 'Budi', 'date': '2024-01-15T10:30:00Z'},
        },
        'author': {'login': 'budi'},
      });
      final withoutLogin = Commit.fromJson({
        'sha': 'abc',
        'commit': {
          'message': 'Fix',
          'author': {'name': 'Budi', 'date': '2024-01-15T10:30:00Z'},
        },
      });

      expect(withLogin.author, 'budi');
      expect(withoutLogin.author, 'Budi');
    });

    test('fromCacheJson parses cached JSON', () {
      final commit = Commit.fromCacheJson({
        'sha': 'abc123',
        'message': 'Test commit',
        'date': '2024-01-15T10:30:00Z',
      });

      expect(commit.sha, 'abc123');
      expect(commit.message, 'Test commit');
    });

    test('toJson round-trips through fromCacheJson', () {
      final commit = Commit(
        sha: 'abc123',
        message: 'Test',
        date: DateTime.utc(2024, 1, 15),
      );

      final restored = Commit.fromCacheJson(commit.toJson());
      expect(restored.sha, 'abc123');
      expect(restored.message, 'Test');
      expect(restored.date, commit.date);
    });

    test('title returns first line of message', () {
      final commit = Commit(
        sha: 'abc',
        message: 'First line\nSecond line\nThird',
        date: DateTime.now(),
      );

      expect(commit.title, 'First line');
    });
  });

  group('CommitDetail', () {
    test('fromJson parses stats and files', () {
      final detail = CommitDetail.fromJson({
        'sha': 'abc123',
        'stats': {'additions': 10, 'deletions': 5, 'total': 15},
        'files': [
          {
            'filename': 'lib/main.dart',
            'status': 'modified',
            'additions': 8,
            'deletions': 3,
            'changes': 11,
          },
        ],
      });

      expect(detail.sha, 'abc123');
      expect(detail.additions, 10);
      expect(detail.deletions, 5);
      expect(detail.totalChanges, 15);
      expect(detail.files.single.filename, 'lib/main.dart');
    });

    test('fromJson handles missing stats', () {
      final detail = CommitDetail.fromJson(const {'sha': 'abc123'});

      expect(detail.additions, 0);
      expect(detail.deletions, 0);
      expect(detail.files, isEmpty);
    });
  });

  group('CommitFile', () {
    test('fromJson parses all fields', () {
      final file = CommitFile.fromJson(const {
        'filename': 'lib/test.dart',
        'status': 'added',
        'additions': 5,
        'deletions': 0,
        'changes': 5,
      });

      expect(file.filename, 'lib/test.dart');
      expect(file.status, 'added');
      expect(file.additions, 5);
    });

    test('fromJson falls back to modified', () {
      final file = CommitFile.fromJson(const {});

      expect(file.filename, '');
      expect(file.status, 'modified');
      expect(file.additions, 0);
    });
  });

  group('AppSettings', () {
    test('defaults constructor', () {
      const settings = AppSettings.defaults();

      expect(settings.syncIntervalMinutes, defaultSyncIntervalMinutes);
      expect(settings.languageCode, languageIndonesian);
      expect(settings.themeMode, themeModeSystem);
      expect(settings.notificationsEnabled, true);
    });

    test('fromJson parses valid data', () {
      final settings = AppSettings.fromJson(const {
        'sync_interval_minutes': 30,
        'language_code': 'en',
        'theme_mode': 'dark',
        'notifications_enabled': false,
      });

      expect(settings.syncIntervalMinutes, 30);
      expect(settings.languageCode, 'en');
      expect(settings.themeMode, 'dark');
      expect(settings.notificationsEnabled, false);
    });

    test('fromJson rejects invalid language and theme', () {
      final settings = AppSettings.fromJson(const {
        'language_code': 'fr',
        'theme_mode': 'invalid',
      });

      expect(settings.languageCode, languageIndonesian);
      expect(settings.themeMode, themeModeSystem);
    });

    test('fromJson normalizes unsupported sync interval', () {
      expect(
        AppSettings.fromJson(const {'sync_interval_minutes': 7})
            .syncIntervalMinutes,
        defaultSyncIntervalMinutes,
      );
      expect(
        AppSettings.fromJson(const {'sync_interval_minutes': 30})
            .syncIntervalMinutes,
        30,
      );
    });

    test('fromJson parses sync efficiency fields', () {
      final settings = AppSettings.fromJson(const {
        'precise_sync': true,
        'wifi_only': true,
        'alert_on_unread': true,
        'quiet_hours_enabled': true,
        'wake_minutes': 390,
        'sleep_minutes': 1350,
      });

      expect(settings.preciseSync, true);
      expect(settings.wifiOnly, true);
      expect(settings.alertOnUnread, true);
      expect(settings.wakeMinutes, 390);
      expect(settings.sleepMinutes, 1350);
    });

    test('fromJson migrates legacy quiet hour keys', () {
      final settings = AppSettings.fromJson(const {
        'quiet_start_hour': 22,
        'quiet_end_hour': 6,
      });

      expect(settings.sleepMinutes, 22 * 60);
      expect(settings.wakeMinutes, 6 * 60);
    });

    test('isSleepTime handles overnight windows', () {
      const overnight = AppSettings(
        syncIntervalMinutes: 60,
        languageCode: languageIndonesian,
        themeMode: themeModeSystem,
        wakeMinutes: 7 * 60,
        sleepMinutes: 23 * 60,
      );

      expect(overnight.isSleepTime(DateTime(2026, 1, 1, 23)), true);
      expect(overnight.isSleepTime(DateTime(2026, 1, 1, 3)), true);
      expect(overnight.isSleepTime(DateTime(2026, 1, 1, 7)), false);
      expect(overnight.isSleepTime(DateTime(2026, 1, 1, 12)), false);
    });

    test('isSleepTime respects the toggle', () {
      const disabled = AppSettings(
        syncIntervalMinutes: 60,
        languageCode: languageIndonesian,
        themeMode: themeModeSystem,
        quietHoursEnabled: false,
      );

      expect(disabled.isSleepTime(DateTime(2026, 1, 1, 2)), false);
    });

    test('isMorningWindow covers wake-up plus three hours', () {
      const settings = AppSettings(
        syncIntervalMinutes: 60,
        languageCode: languageIndonesian,
        themeMode: themeModeSystem,
        wakeMinutes: 7 * 60,
        sleepMinutes: 23 * 60,
      );

      expect(settings.isMorningWindow(DateTime(2026, 1, 1, 7)), true);
      expect(settings.isMorningWindow(DateTime(2026, 1, 1, 9, 59)), true);
      expect(settings.isMorningWindow(DateTime(2026, 1, 1, 10)), false);
    });

    test('dynamic color defaults to true and can be disabled', () {
      const defaults = AppSettings.defaults();

      expect(defaults.dynamicColor, true);
      expect(
        AppSettings.fromJson(const {'dynamic_color': false}).dynamicColor,
        false,
      );
      expect(defaults.copyWith(dynamicColor: false).dynamicColor, false);
    });

    test('hide notification content defaults off', () {
      const defaults = AppSettings.defaults();

      expect(defaults.hideNotificationContent, false);
      expect(
        AppSettings.fromJson(const {'hide_notification_content': true})
            .hideNotificationContent,
        true,
      );
    });

    test('copyWith only changes given fields', () {
      const original = AppSettings.defaults();
      final modified = original.copyWith(
        languageCode: 'en',
        notificationsEnabled: false,
      );

      expect(modified.languageCode, 'en');
      expect(modified.notificationsEnabled, false);
      expect(modified.syncIntervalMinutes, original.syncIntervalMinutes);
      expect(modified.themeMode, original.themeMode);
    });

    test('toJson round-trips through fromJson', () {
      const settings = AppSettings(
        syncIntervalMinutes: 30,
        languageCode: 'en',
        themeMode: 'dark',
        notificationsEnabled: false,
      );

      final restored = AppSettings.fromJson(settings.toJson());
      expect(restored.syncIntervalMinutes, 30);
      expect(restored.languageCode, 'en');
      expect(restored.themeMode, 'dark');
      expect(restored.notificationsEnabled, false);
    });
  });

  group('GitHubCredentials', () {
    test('empty constructor is empty', () {
      const credentials = GitHubCredentials.empty();

      expect(credentials.isEmpty, true);
      expect(credentials.isNotEmpty, false);
    });

    test('toJson encodes values to base64', () {
      const credentials = GitHubCredentials(
        username: 'testuser',
        token: 'ghp_abc123',
      );

      final json = credentials.toJson();
      expect(json['username'], isNot('testuser'));
      expect(json['token'], isNot('ghp_abc123'));
    });

    test('fromJson decodes base64 values', () {
      const original = GitHubCredentials(
        username: 'testuser',
        token: 'ghp_abc123',
      );

      final decoded = GitHubCredentials.fromJson(original.toJson());
      expect(decoded.username, 'testuser');
      expect(decoded.token, 'ghp_abc123');
    });

    test('fromJson handles invalid base64', () {
      final credentials = GitHubCredentials.fromJson(const {
        'username': '!!!invalid!!!',
        'token': '!!!invalid!!!',
      });

      expect(credentials.username, '');
      expect(credentials.token, '');
    });

    test('basicAuth builds Basic header', () {
      const credentials = GitHubCredentials(username: 'user', token: 'token');

      expect(credentials.basicAuth, 'Basic dXNlcjp0b2tlbg==');
    });
  });

  group('SyncLog', () {
    test('fromJson parses updates', () {
      final log = SyncLog.fromJson(const {
        'synced_at': '2024-01-15T10:30:00Z',
        'updates': {'owner/repo (main)': 5},
      });

      expect(log.updates['owner/repo (main)'], 5);
      expect(log.syncedAt, DateTime.parse('2024-01-15T10:30:00Z'));
    });

    test('hasUpdates and totalCommits', () {
      final empty = SyncLog(syncedAt: DateTime.now(), updates: const {});
      final filled = SyncLog(
        syncedAt: DateTime.now(),
        updates: const {'repo1': 3, 'repo2': 7},
      );

      expect(empty.hasUpdates, false);
      expect(empty.totalCommits, 0);
      expect(filled.hasUpdates, true);
      expect(filled.totalCommits, 10);
    });

    test('toJson round-trips through fromJson', () {
      final log = SyncLog(
        syncedAt: DateTime.utc(2024, 1, 15),
        updates: const {'owner/repo (main)': 2},
      );

      final restored = SyncLog.fromJson(log.toJson());
      expect(restored.syncedAt, log.syncedAt);
      expect(restored.totalCommits, 2);
    });
  });

  group('WatchedRepo', () {
    test('fromJson parses all fields', () {
      final repo = WatchedRepo.fromJson(const {
        'owner': 'torvalds',
        'repo': 'linux',
        'branch': 'master',
        'sync_mode': 'minimal',
        'avatar_url': 'https://example.com/avatar.png',
        'is_private': true,
        'last_commit_at': '2024-01-15T10:30:00Z',
        'last_sha': 'abc123',
      });

      expect(repo.owner, 'torvalds');
      expect(repo.repo, 'linux');
      expect(repo.branch, 'master');
      expect(repo.syncMode, 'minimal');
      expect(repo.avatarUrl, 'https://example.com/avatar.png');
      expect(repo.isPrivate, true);
      expect(repo.lastSha, 'abc123');
      expect(repo.fullName, 'torvalds/linux');
    });

    test('fromJson migrates legacy full sync mode', () {
      final repo = WatchedRepo.fromJson(const {
        'owner': 'test',
        'repo': 'test',
        'sync_mode': 'full',
      });

      expect(repo.syncMode, syncModeExtended);
    });

    test('fromJson handles missing fields', () {
      final repo = WatchedRepo.fromJson(const {
        'owner': 'test',
        'repo': 'test',
      });

      expect(repo.branch, 'main');
      expect(repo.syncMode, syncModeMinimal);
      expect(repo.avatarUrl, '');
      expect(repo.isPrivate, false);
      expect(repo.lastSha, '');
      expect(repo.lastCommitAt, isNull);
    });

    test('copyWith only changes given fields', () {
      final repo = WatchedRepo(
        owner: 'flutter',
        repo: 'flutter',
        branch: 'master',
        syncMode: syncModeMinimal,
        lastSha: 'abc123',
        lastCommitAt: DateTime.utc(2024, 1, 15),
      );

      final modified = repo.copyWith(lastSha: 'def456', isPrivate: true);
      expect(modified.owner, 'flutter');
      expect(modified.branch, 'master');
      expect(modified.lastSha, 'def456');
      expect(modified.isPrivate, true);
      expect(modified.lastCommitAt, repo.lastCommitAt);
    });

    test('muted flag round-trips and copies', () {
      const repo = WatchedRepo(
        owner: 'a',
        repo: 'b',
        branch: 'main',
        syncMode: syncModeMinimal,
        muted: true,
      );

      expect(WatchedRepo.fromJson(repo.toJson()).muted, true);
      expect(repo.copyWith(muted: false).muted, false);
    });

    test('etag round-trips through json', () {
      const repo = WatchedRepo(
        owner: 'a',
        repo: 'b',
        branch: 'main',
        syncMode: syncModeMinimal,
        etag: 'W/"x"',
      );

      expect(WatchedRepo.fromJson(repo.toJson()).etag, 'W/"x"');
    });

    test('toJson round-trips through fromJson', () {
      const repo = WatchedRepo(
        owner: 'test',
        repo: 'test',
        branch: 'main',
        syncMode: syncModeExtended,
        lastSha: 'abc123',
        isPrivate: true,
      );

      final restored = WatchedRepo.fromJson(repo.toJson());
      expect(restored.fullName, 'test/test');
      expect(restored.syncMode, syncModeExtended);
      expect(restored.isPrivate, true);
      expect(restored.lastSha, 'abc123');
    });
  });
}
