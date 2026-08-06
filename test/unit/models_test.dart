import 'package:flutter_test/flutter_test.dart';
import 'package:github_watcher/models/commit.dart';
import 'package:github_watcher/models/app_settings.dart';
import 'package:github_watcher/models/github_credentials.dart';
import 'package:github_watcher/models/sync_log.dart';
import 'package:github_watcher/models/watched_repo.dart';
import 'package:github_watcher/utils/constants.dart';

void main() {
  group('Commit', () {
    test('fromJson parses GitHub API response', () {
      final json = {
        'sha': 'abc123def456',
        'commit': {
          'message': 'Fix bug\n\nDetailed description',
          'author': {'date': '2024-01-15T10:30:00Z'},
        },
      };

      final commit = Commit.fromJson(json);
      expect(commit.sha, 'abc123def456');
      expect(commit.message, 'Fix bug\n\nDetailed description');
      expect(commit.title, 'Fix bug');
      expect(commit.date, DateTime.parse('2024-01-15T10:30:00Z'));
    });

    test('fromCacheJson parses cached JSON', () {
      final json = {
        'sha': 'abc123',
        'message': 'Test commit',
        'date': '2024-01-15T10:30:00Z',
      };

      final commit = Commit.fromCacheJson(json);
      expect(commit.sha, 'abc123');
      expect(commit.message, 'Test commit');
    });

    test('toJson serializes correctly', () {
      final commit = Commit(
        sha: 'abc123',
        message: 'Test',
        date: DateTime.utc(2024, 1, 15),
      );

      final json = commit.toJson();
      expect(json['sha'], 'abc123');
      expect(json['message'], 'Test');
      expect(json['date'], isA<String>());
    });

    test('title returns first line of message', () {
      final commit = Commit(
        sha: 'abc',
        message: 'First line\nSecond line\nThird',
        date: DateTime.now(),
      );
      expect(commit.title, 'First line');
    });

    test('title handles empty message', () {
      final commit = Commit(sha: 'abc', message: '', date: DateTime.now());
      expect(commit.title, '');
    });
  });

  group('CommitDetail', () {
    test('fromJson parses with files', () {
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
        ],
      };

      final detail = CommitDetail.fromJson(json);
      expect(detail.sha, 'abc123');
      expect(detail.additions, 10);
      expect(detail.deletions, 5);
      expect(detail.totalChanges, 15);
      expect(detail.files.length, 1);
      expect(detail.files.first.filename, 'lib/main.dart');
    });

    test('fromJson handles missing stats', () {
      final json = {'sha': 'abc123'};

      final detail = CommitDetail.fromJson(json);
      expect(detail.additions, 0);
      expect(detail.deletions, 0);
      expect(detail.files, isEmpty);
    });
  });

  group('CommitFile', () {
    test('fromJson parses correctly', () {
      final json = {
        'filename': 'lib/test.dart',
        'status': 'added',
        'additions': 5,
        'deletions': 0,
        'changes': 5,
      };

      final file = CommitFile.fromJson(json);
      expect(file.filename, 'lib/test.dart');
      expect(file.status, 'added');
      expect(file.additions, 5);
    });

    test('fromJson handles missing fields', () {
      final json = <String, dynamic>{};

      final file = CommitFile.fromJson(json);
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
    });

    test('fromJson parses valid data', () {
      final json = {
        'sync_interval_minutes': 30,
        'language_code': 'en',
        'theme_mode': 'dark',
      };

      final settings = AppSettings.fromJson(json);
      expect(settings.syncIntervalMinutes, 30);
      expect(settings.languageCode, 'en');
      expect(settings.themeMode, 'dark');
    });

    test('fromJson handles invalid theme', () {
      final json = {'theme_mode': 'invalid'};

      final settings = AppSettings.fromJson(json);
      expect(settings.themeMode, themeModeSystem);
    });

    test('fromJson handles invalid language', () {
      final json = {'language_code': 'fr'};

      final settings = AppSettings.fromJson(json);
      expect(settings.languageCode, languageIndonesian);
    });

    test('copyWith works', () {
      const original = AppSettings.defaults();
      final modified = original.copyWith(languageCode: 'en');

      expect(modified.languageCode, 'en');
      expect(modified.syncIntervalMinutes, original.syncIntervalMinutes);
      expect(modified.themeMode, original.themeMode);
    });

    test('toJson serializes correctly', () {
      const settings = AppSettings(
        syncIntervalMinutes: 45,
        languageCode: 'en',
        themeMode: 'dark',
      );

      final json = settings.toJson();
      expect(json['sync_interval_minutes'], 45);
      expect(json['language_code'], 'en');
      expect(json['theme_mode'], 'dark');
    });
  });

  group('GitHubCredentials', () {
    test('empty constructor', () {
      const creds = GitHubCredentials.empty();
      expect(creds.isEmpty, true);
      expect(creds.isNotEmpty, false);
    });

    test('toJson encodes to base64', () {
      const creds = GitHubCredentials(
        username: 'testuser',
        token: 'ghp_abc123',
      );

      final json = creds.toJson();
      // Should be base64 encoded, not plain text
      expect(json['username'], isNot('testuser'));
      expect(json['token'], isNot('ghp_abc123'));
    });

    test('fromJson decodes from base64', () {
      const original = GitHubCredentials(
        username: 'testuser',
        token: 'ghp_abc123',
      );
      final json = original.toJson();

      final decoded = GitHubCredentials.fromJson(json);
      expect(decoded.username, 'testuser');
      expect(decoded.token, 'ghp_abc123');
    });

    test('fromJson handles invalid base64', () {
      final json = {'username': '!!!invalid!!!', 'token': '!!!invalid!!!'};

      final creds = GitHubCredentials.fromJson(json);
      expect(creds.username, '');
      expect(creds.token, '');
    });

    test('basicAuth generates correct header', () {
      const creds = GitHubCredentials(username: 'user', token: 'token');
      final auth = creds.basicAuth;

      expect(auth, startsWith('Basic '));
      // Decode and verify
      expect(auth, 'Basic dXNlcjp0b2tlbg==');
    });
  });

  group('SyncLog', () {
    test('fromJson parses correctly', () {
      final json = {
        'synced_at': '2024-01-15T10:30:00Z',
        'updates': {'owner/repo (main)': 5},
      };

      final log = SyncLog.fromJson(json);
      expect(log.updates.length, 1);
      expect(log.updates['owner/repo (main)'], 5);
    });

    test('hasUpdates returns true when updates exist', () {
      final log = SyncLog(syncedAt: DateTime.now(), updates: {'repo': 1});
      expect(log.hasUpdates, true);
    });

    test('hasUpdates returns false when empty', () {
      final log = SyncLog(syncedAt: DateTime.now(), updates: {});
      expect(log.hasUpdates, false);
    });

    test('totalCommits sums correctly', () {
      final log = SyncLog(
        syncedAt: DateTime.now(),
        updates: {'repo1': 3, 'repo2': 7, 'repo3': 2},
      );
      expect(log.totalCommits, 12);
    });

    test('totalCommits returns 0 for empty', () {
      final log = SyncLog(syncedAt: DateTime.now(), updates: {});
      expect(log.totalCommits, 0);
    });
  });

  group('WatchedRepo', () {
    test('fromJson parses correctly', () {
      final json = {
        'owner': 'torvalds',
        'repo': 'linux',
        'branch': 'master',
        'sync_mode': 'minimal',
        'avatar_url': 'https://example.com/avatar.png',
        'is_private': false,
        'last_commit_at': '2024-01-15T10:30:00Z',
        'last_sha': 'abc123',
      };

      final repo = WatchedRepo.fromJson(json);
      expect(repo.owner, 'torvalds');
      expect(repo.repo, 'linux');
      expect(repo.branch, 'master');
      expect(repo.syncMode, 'minimal');
      expect(repo.isPrivate, false);
      expect(repo.fullName, 'torvalds/linux');
    });

    test('fromJson handles legacy full sync mode', () {
      final json = {
        'owner': 'test',
        'repo': 'test',
        'sync_mode': 'full',
        'last_sha': '',
      };

      final repo = WatchedRepo.fromJson(json);
      expect(repo.syncMode, 'extended_5000');
    });

    test('fromJson handles missing fields', () {
      final json = {'owner': 'test', 'repo': 'test', 'last_sha': ''};

      final repo = WatchedRepo.fromJson(json);
      expect(repo.branch, 'main');
      expect(repo.syncMode, 'minimal');
      expect(repo.avatarUrl, '');
      expect(repo.isPrivate, false);
    });

    test('fullName returns owner/repo', () {
      final repo = WatchedRepo(
        owner: 'flutter',
        repo: 'flutter',
        branch: 'master',
        syncMode: 'minimal',
        lastSha: 'abc',
      );
      expect(repo.fullName, 'flutter/flutter');
    });

    test('toJson serializes correctly', () {
      final repo = WatchedRepo(
        owner: 'test',
        repo: 'test',
        branch: 'main',
        syncMode: 'minimal',
        lastSha: 'abc123',
        isPrivate: true,
      );

      final json = repo.toJson();
      expect(json['owner'], 'test');
      expect(json['is_private'], true);
      expect(json['last_sha'], 'abc123');
    });
  });
}
