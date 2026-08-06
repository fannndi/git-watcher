import 'package:flutter_test/flutter_test.dart';
import 'package:github_watcher/models/app_settings.dart';
import 'package:github_watcher/models/watched_repo.dart';
import 'package:github_watcher/models/commit.dart';
import 'package:github_watcher/utils/constants.dart';
import 'package:github_watcher/utils/extensions.dart';

void main() {
  group('AppSettings notificationsEnabled', () {
    test('default is true', () {
      const settings = AppSettings.defaults();
      expect(settings.notificationsEnabled, true);
    });

    test('copyWith notificationsEnabled', () {
      const settings = AppSettings.defaults();
      final modified = settings.copyWith(notificationsEnabled: false);
      expect(modified.notificationsEnabled, false);
      expect(modified.syncIntervalMinutes, settings.syncIntervalMinutes);
    });

    test('toJson includes notificationsEnabled', () {
      const settings = AppSettings(
        syncIntervalMinutes: 60,
        languageCode: 'id',
        themeMode: 'system',
        notificationsEnabled: false,
      );
      final json = settings.toJson();
      expect(json['notifications_enabled'], false);
    });

    test('fromJson parses notificationsEnabled', () {
      final json = {
        'sync_interval_minutes': 60,
        'language_code': 'id',
        'theme_mode': 'system',
        'notifications_enabled': false,
      };
      final settings = AppSettings.fromJson(json);
      expect(settings.notificationsEnabled, false);
    });

    test('fromJson defaults notificationsEnabled to true', () {
      final json = {
        'sync_interval_minutes': 60,
        'language_code': 'id',
        'theme_mode': 'system',
      };
      final settings = AppSettings.fromJson(json);
      expect(settings.notificationsEnabled, true);
    });
  });

  group('WatchedRepo copyWith', () {
    late WatchedRepo repo;

    setUp(() {
      repo = WatchedRepo(
        owner: 'flutter',
        repo: 'flutter',
        branch: 'master',
        syncMode: 'minimal',
        lastSha: 'abc123',
        lastCommitAt: DateTime.utc(2024, 1, 15),
      );
    });

    test('copyWith owner', () {
      final modified = repo.copyWith(owner: 'dart-lang');
      expect(modified.owner, 'dart-lang');
      expect(modified.repo, 'flutter');
    });

    test('copyWith multiple fields', () {
      final modified = repo.copyWith(
        branch: 'main',
        syncMode: 'extended_5000',
        isPrivate: true,
      );
      expect(modified.branch, 'main');
      expect(modified.syncMode, 'extended_5000');
      expect(modified.isPrivate, true);
      expect(modified.owner, 'flutter'); // unchanged
    });

    test('copyWith no args returns same values', () {
      final copy = repo.copyWith();
      expect(copy.owner, repo.owner);
      expect(copy.repo, repo.repo);
      expect(copy.branch, repo.branch);
      expect(copy.syncMode, repo.syncMode);
      expect(copy.lastSha, repo.lastSha);
    });
  });

  group('String extensions', () {
    test('truncate short string', () {
      expect('hello'.truncate(10), 'hello');
    });

    test('truncate long string', () {
      expect('hello world this is test'.truncate(10), 'hello w...');
    });

    test('take', () {
      expect('hello'.take(3), 'hel');
      expect('hello'.take(10), 'hello');
    });

    test('capitalize', () {
      expect('hello'.capitalize(), 'Hello');
      expect(''.capitalize(), '');
    });

    test('isEmail', () {
      expect('test@example.com'.isEmail, true);
      expect('invalid'.isEmail, false);
      expect('test@'.isEmail, false);
    });

    test('isUrl', () {
      expect('https://example.com'.isUrl, true);
      expect('http://example.com'.isUrl, true);
      expect('ftp://example.com'.isUrl, false);
      expect('example.com'.isUrl, false);
    });

    test('removeWhitespace', () {
      expect('hello world'.removeWhitespace, 'helloworld');
      expect('  hi  '.removeWhitespace, 'hi');
    });
  });

  group('DateTime extensions', () {
    test('timeAgo just now', () {
      final now = DateTime.now();
      expect(now.timeAgo, 'Just now');
    });

    test('timeAgo minutes', () {
      final ago = DateTime.now().subtract(const Duration(minutes: 5));
      expect(ago.timeAgo, '5 minutes ago');
    });

    test('timeAgo hours', () {
      final ago = DateTime.now().subtract(const Duration(hours: 3));
      expect(ago.timeAgo, '3 hours ago');
    });

    test('timeAgo days', () {
      final ago = DateTime.now().subtract(const Duration(days: 7));
      expect(ago.timeAgo, '7 days ago');
    });

    test('shortDate', () {
      final date = DateTime(2024, 1, 15);
      expect(date.shortDate, 'Jan 15');
    });

    test('isToday', () {
      expect(DateTime.now().isToday, true);
      expect(DateTime(2020, 1, 1).isToday, false);
    });

    test('isYesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(yesterday.isYesterday, true);
      expect(DateTime.now().isYesterday, false);
    });
  });

  group('List extensions', () {
    test('getOrNull valid index', () {
      expect([1, 2, 3].getOrNull(1), 2);
    });

    test('getOrNull invalid index', () {
      expect([1, 2, 3].getOrNull(5), null);
      expect([1, 2, 3].getOrNull(-1), null);
    });

    test('chunk', () {
      final result = [1, 2, 3, 4, 5].chunk(2);
      expect(result.length, 3);
      expect(result[0], [1, 2]);
      expect(result[1], [3, 4]);
      expect(result[2], [5]);
    });
  });

  group('CommitDetail', () {
    test('fromJson with stats and files', () {
      final json = {
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
          {
            'filename': 'lib/app.dart',
            'status': 'added',
            'additions': 2,
            'deletions': 0,
            'changes': 2,
          },
        ],
      };

      final detail = CommitDetail.fromJson(json);
      expect(detail.sha, 'abc123');
      expect(detail.additions, 10);
      expect(detail.deletions, 5);
      expect(detail.totalChanges, 15);
      expect(detail.files.length, 2);
      expect(detail.files.first.filename, 'lib/main.dart');
      expect(detail.files.first.status, 'modified');
      expect(detail.files.last.status, 'added');
    });

    test('fromJson with minimal data', () {
      final json = {'sha': 'def456'};
      final detail = CommitDetail.fromJson(json);
      expect(detail.sha, 'def456');
      expect(detail.additions, 0);
      expect(detail.deletions, 0);
      expect(detail.files, isEmpty);
    });
  });

  group('CommitFile', () {
    test('fromJson parses all fields', () {
      final json = {
        'filename': 'lib/test.dart',
        'status': 'renamed',
        'additions': 15,
        'deletions': 10,
        'changes': 25,
      };

      final file = CommitFile.fromJson(json);
      expect(file.filename, 'lib/test.dart');
      expect(file.status, 'renamed');
      expect(file.additions, 15);
      expect(file.deletions, 10);
      expect(file.changes, 25);
    });

    test('fromJson handles empty', () {
      final json = <String, dynamic>{};
      final file = CommitFile.fromJson(json);
      expect(file.filename, '');
      expect(file.status, 'modified');
      expect(file.additions, 0);
      expect(file.deletions, 0);
    });
  });

  group('Constants', () {
    test('app version exists', () {
      expect(appVersionName, isNotEmpty);
      expect(appBuildNumber, isNotEmpty);
      expect(developerName, isNotEmpty);
      expect(developerUrl, isNotEmpty);
    });

    test('limits are reasonable', () {
      expect(maxWatchedRepos, 5);
      expect(defaultSyncIntervalMinutes, 60);
    });

    test('sync modes exist', () {
      expect(syncModeMinimal, 'minimal');
      expect(syncModeLatest, 'latest_500');
      expect(syncModeExtended, 'extended_5000');
    });

    test('storage keys exist', () {
      expect(watchedReposKey, isNotEmpty);
      expect(appSettingsKey, isNotEmpty);
      expect(githubCredentialsKey, isNotEmpty);
      expect(updateSummaryKey, isNotEmpty);
      expect(syncHistoryKey, isNotEmpty);
    });
  });
}
