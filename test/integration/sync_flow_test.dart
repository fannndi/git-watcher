import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:github_watcher/models/commit.dart';
import 'package:github_watcher/models/watched_repo.dart';
import 'package:github_watcher/models/sync_log.dart';
import 'package:github_watcher/models/github_credentials.dart';
import 'package:github_watcher/models/app_settings.dart';
import 'package:github_watcher/services/storage_service.dart';

void main() {
  group('Sync Flow Integration', () {
    late StorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = StorageService();
    });

    test('save and load repos', () async {
      final repos = [
        WatchedRepo(
          owner: 'flutter',
          repo: 'flutter',
          branch: 'master',
          syncMode: 'minimal',
          lastSha: 'abc123',
          lastCommitAt: DateTime.utc(2024, 1, 15),
        ),
        WatchedRepo(
          owner: 'torvalds',
          repo: 'linux',
          branch: 'master',
          syncMode: 'extended_5000',
          lastSha: 'def456',
          isPrivate: false,
        ),
      ];

      await storage.saveRepos(repos);
      final loaded = await storage.getRepos();

      expect(loaded.length, 2);
      expect(loaded[0].fullName, 'flutter/flutter');
      expect(loaded[0].lastSha, 'abc123');
      expect(loaded[1].fullName, 'torvalds/linux');
      expect(loaded[1].syncMode, 'extended_5000');
    });

    test('save and load credentials', () async {
      final creds = GitHubCredentials(
        username: 'testuser',
        token: 'ghp_abc123',
      );

      await storage.saveCredentials(creds);
      final loaded = await storage.getCredentials();

      expect(loaded.username, 'testuser');
      expect(loaded.token, 'ghp_abc123');
      expect(loaded.isNotEmpty, true);
    });

    test('save and load app settings', () async {
      final settings = AppSettings(
        syncIntervalMinutes: 30,
        languageCode: 'en',
        themeMode: 'dark',
      );

      await storage.saveAppSettings(settings);
      final loaded = await storage.getAppSettings();

      expect(loaded.syncIntervalMinutes, 30);
      expect(loaded.languageCode, 'en');
      expect(loaded.themeMode, 'dark');
    });

    test('save and load sync history', () async {
      final log1 = SyncLog(
        syncedAt: DateTime.utc(2024, 1, 15, 10, 0),
        updates: {'flutter/flutter (master)': 5},
      );
      final log2 = SyncLog(
        syncedAt: DateTime.utc(2024, 1, 15, 11, 0),
        updates: {'torvalds/linux (master)': 3, 'flutter/flutter (master)': 1},
      );

      await storage.addSyncLog(log1);
      await storage.addSyncLog(log2);
      final history = await storage.getSyncHistory();

      expect(history.length, 2);
      expect(history[0].totalCommits, 4); // log2 is newest (prepended)
      expect(history[1].totalCommits, 5);
    });

    test('sync history capped at 30', () async {
      for (var i = 0; i < 35; i++) {
        await storage.addSyncLog(SyncLog(
          syncedAt: DateTime.utc(2024, 1, 1, i % 24),
          updates: {'repo': i},
        ));
      }

      final history = await storage.getSyncHistory();
      expect(history.length, 30);
    });

    test('cached commits deduplication', () async {
      final repo = WatchedRepo(
        owner: 'test',
        repo: 'test',
        branch: 'main',
        syncMode: 'minimal',
        lastSha: 'abc',
      );

      final commits = [
        Commit(sha: 'abc', message: 'First', date: DateTime.utc(2024, 1, 15)),
        Commit(sha: 'def', message: 'Second', date: DateTime.utc(2024, 1, 14)),
        Commit(
            sha: 'abc',
            message: 'First duplicate',
            date: DateTime.utc(2024, 1, 15)),
      ];

      await storage.saveCachedCommits(repo, commits);
      final loaded = await storage.getCachedCommits(repo);

      expect(loaded.length, 2); // deduplicated
      expect(loaded[0].date.isAfter(loaded[1].date), true); // sorted desc
    });

    test('cached commits capped at 1000', () async {
      final repo = WatchedRepo(
        owner: 'test',
        repo: 'test',
        branch: 'main',
        syncMode: 'extended_5000',
        lastSha: 'abc',
      );

      final commits = List.generate(
          1500,
          (i) => Commit(
                sha: 'sha_$i',
                message: 'Commit $i',
                date: DateTime.utc(2024, 1, 1).add(Duration(hours: i)),
              ));

      await storage.saveCachedCommits(repo, commits);
      final loaded = await storage.getCachedCommits(repo);

      expect(loaded.length, 1000); // capped
    });

    test('sync lock prevents concurrent sync', () async {
      expect(await storage.isSyncLocked(), false);

      await storage.acquireSyncLock();
      expect(await storage.isSyncLocked(), true);

      await storage.releaseSyncLock();
      expect(await storage.isSyncLocked(), false);
    });

    test('sync lock auto-releases after timeout', () async {
      // Simulate old lock by setting time in the past
      final prefs = await storage.getPrefsForInternal();
      final oldTime = DateTime.now().subtract(const Duration(minutes: 15));
      await prefs.setString('sync_lock', oldTime.toIso8601String());

      expect(await storage.isSyncLocked(), false); // auto-released
    });

    test('last sync time tracking', () async {
      expect(await storage.getLastSyncAt(), isNull);

      final now = DateTime.now();
      await storage.setLastSyncAt(now);
      final loaded = await storage.getLastSyncAt();

      expect(loaded, isNotNull);
      expect(loaded!.difference(now).inSeconds, lessThan(1));
    });

    test('update summary', () async {
      final updates = {
        'flutter/flutter (master)': 5,
        'torvalds/linux (master)': 3
      };

      await storage.saveUpdateSummary(updates);
      final loaded = await storage.getUpdateSummary();

      expect(loaded.length, 2);
      expect(loaded['flutter/flutter (master)'], 5);
      expect(loaded['torvalds/linux (master)'], 3);
    });
  });
}
