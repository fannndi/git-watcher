import 'package:flutter_test/flutter_test.dart';
import 'package:git_watcher/models/app_settings.dart';
import 'package:git_watcher/models/commit.dart';
import 'package:git_watcher/models/github_credentials.dart';
import 'package:git_watcher/models/sync_log.dart';
import 'package:git_watcher/models/watched_repo.dart';
import 'package:git_watcher/services/storage_service.dart';
import 'package:git_watcher/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late StorageService storage;

  WatchedRepo buildRepo({String syncMode = syncModeMinimal}) {
    return WatchedRepo(
      owner: 'flutter',
      repo: 'flutter',
      branch: 'master',
      syncMode: syncMode,
      lastSha: 'abc123',
      lastCommitAt: DateTime.utc(2024, 1, 15),
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    storage = StorageService();
  });

  group('repos', () {
    test('save and load round-trip', () async {
      final repos = [
        buildRepo(),
        const WatchedRepo(
          owner: 'torvalds',
          repo: 'linux',
          branch: 'master',
          syncMode: syncModeExtended,
          lastSha: 'def456',
        ),
      ];

      await storage.saveRepos(repos);
      final loaded = await storage.getRepos();

      expect(loaded.length, 2);
      expect(loaded[0].fullName, 'flutter/flutter');
      expect(loaded[1].syncMode, syncModeExtended);
    });

    test('corrupt json falls back to empty list', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(watchedReposKey, '{not json');

      expect(await storage.getRepos(), isEmpty);
    });
  });

  group('credentials', () {
    test('save and load round-trip', () async {
      await storage.saveCredentials(
        const GitHubCredentials(username: 'testuser', token: 'ghp_abc123'),
      );

      final loaded = await storage.getCredentials();
      expect(loaded.username, 'testuser');
      expect(loaded.token, 'ghp_abc123');
      expect(loaded.isNotEmpty, true);
    });

    test('clear removes credentials', () async {
      await storage.saveCredentials(
        const GitHubCredentials(username: 'user', token: 'token'),
      );
      await storage.clearCredentials();

      expect((await storage.getCredentials()).isEmpty, true);
    });
  });

  group('app settings', () {
    test('defaults when unset', () async {
      final settings = await storage.getAppSettings();

      expect(settings.languageCode, languageIndonesian);
      expect(settings.themeMode, themeModeSystem);
    });

    test('save and load round-trip', () async {
      await storage.saveAppSettings(
        const AppSettings(
          syncIntervalMinutes: 30,
          languageCode: languageEnglish,
          themeMode: themeModeDark,
          notificationsEnabled: false,
        ),
      );

      final loaded = await storage.getAppSettings();
      expect(loaded.syncIntervalMinutes, 30);
      expect(loaded.languageCode, languageEnglish);
      expect(loaded.themeMode, themeModeDark);
      expect(loaded.notificationsEnabled, false);
    });
  });

  group('sync history', () {
    test('newest log is first', () async {
      await storage.addSyncLog(
        SyncLog(
          syncedAt: DateTime.utc(2024, 1, 15, 10),
          updates: const {'flutter/flutter (master)': 5},
        ),
      );
      await storage.addSyncLog(
        SyncLog(
          syncedAt: DateTime.utc(2024, 1, 15, 11),
          updates: const {'torvalds/linux (master)': 3},
        ),
      );

      final history = await storage.getSyncHistory();
      expect(history.length, 2);
      expect(history.first.totalCommits, 3);
    });

    test('capped at $maxSyncHistory entries', () async {
      for (var i = 0; i < maxSyncHistory + 5; i++) {
        await storage.addSyncLog(
          SyncLog(syncedAt: DateTime.utc(2024, 1, 1), updates: {'repo': i}),
        );
      }

      expect((await storage.getSyncHistory()).length, maxSyncHistory);
    });

    test('clear removes all entries', () async {
      await storage.addSyncLog(
        SyncLog(
          syncedAt: DateTime.utc(2024, 1, 15),
          updates: const {'repo': 1},
        ),
      );

      await storage.clearSyncHistory();
      expect(await storage.getSyncHistory(), isEmpty);
    });
  });

  group('commit cache', () {
    test('deduplicates by sha and sorts newest first', () async {
      final repo = buildRepo();
      await storage.saveCachedCommits(repo, [
        Commit(sha: 'abc', message: 'First', date: DateTime.utc(2024, 1, 15)),
        Commit(sha: 'def', message: 'Second', date: DateTime.utc(2024, 1, 14)),
        Commit(
            sha: 'abc', message: 'Duplicate', date: DateTime.utc(2024, 1, 16)),
      ]);

      final loaded = await storage.getCachedCommits(repo);
      expect(loaded.length, 2);
      expect(loaded.first.sha, 'abc');
      expect(loaded.first.date.isAfter(loaded.last.date), true);
    });

    test('capped at $maxCachedCommits commits', () async {
      final repo = buildRepo(syncMode: syncModeExtended);
      final commits = List.generate(
        maxCachedCommits + 200,
        (i) => Commit(
          sha: 'sha_$i',
          message: 'Commit $i',
          date: DateTime.utc(2024, 1, 1).add(Duration(minutes: i)),
        ),
      );

      await storage.saveCachedCommits(repo, commits);
      expect((await storage.getCachedCommits(repo)).length, maxCachedCommits);
    });

    test('merge keeps existing commits', () async {
      final repo = buildRepo();
      await storage.saveCachedCommits(repo, [
        Commit(sha: 'abc', message: 'First', date: DateTime.utc(2024, 1, 15)),
      ]);
      await storage.mergeCachedCommits(repo, [
        Commit(sha: 'def', message: 'Second', date: DateTime.utc(2024, 1, 16)),
      ]);

      final loaded = await storage.getCachedCommits(repo);
      expect(loaded.length, 2);
      expect(loaded.first.sha, 'def');
    });
  });

  group('sync lock', () {
    test('acquire and release', () async {
      expect(await storage.isSyncLocked(), false);

      await storage.acquireSyncLock();
      expect(await storage.isSyncLocked(), true);

      await storage.releaseSyncLock();
      expect(await storage.isSyncLocked(), false);
    });

    test('auto-releases stale lock', () async {
      final prefs = await SharedPreferences.getInstance();
      final stale = DateTime.now().subtract(syncLockTimeout * 2);
      await prefs.setString(syncLockKey, stale.toIso8601String());

      expect(await storage.isSyncLocked(), false);
    });
  });

  group('flags', () {
    test('alarm registration flag', () async {
      expect(await storage.isAlarmRegistered(), false);

      await storage.setAlarmRegistered(true);
      expect(await storage.isAlarmRegistered(), true);

      await storage.setAlarmRegistered(false);
      expect(await storage.isAlarmRegistered(), false);
    });

    test('alarm interval minutes', () async {
      expect(await storage.getAlarmIntervalMinutes(), isNull);

      await storage.setAlarmIntervalMinutes(30);
      expect(await storage.getAlarmIntervalMinutes(), 30);
    });

    test('alarm precise flag', () async {
      expect(await storage.isAlarmPrecise(), false);

      await storage.setAlarmPrecise(true);
      expect(await storage.isAlarmPrecise(), true);
    });

    test('sync backoff level is clamped', () async {
      expect(await storage.getSyncBackoffLevel(), 0);

      await storage.setSyncBackoffLevel(5);
      expect(await storage.getSyncBackoffLevel(), maxSyncBackoffLevel);

      await storage.setSyncBackoffLevel(-1);
      expect(await storage.getSyncBackoffLevel(), 0);
    });

    test('last seen timestamp', () async {
      expect(await storage.getLastSeenAt(), isNull);

      final now = DateTime.now();
      await storage.setLastSeenAt(now);
      final loaded = await storage.getLastSeenAt();

      expect(loaded, isNotNull);
      expect(loaded!.difference(now).inSeconds, lessThan(1));
    });

    test('morning digest date', () async {
      expect(await storage.getMorningDigestDate(), isNull);

      await storage.setMorningDigestDate('2026-1-1');
      expect(await storage.getMorningDigestDate(), '2026-1-1');
    });

    test('tour flag', () async {
      expect(await storage.hasSeenTour(), false);

      await storage.setHasSeenTour(true);
      expect(await storage.hasSeenTour(), true);
    });

    test('last sync timestamp', () async {
      expect(await storage.getLastSyncAt(), isNull);

      final now = DateTime.now();
      await storage.setLastSyncAt(now);
      final loaded = await storage.getLastSyncAt();

      expect(loaded, isNotNull);
      expect(loaded!.difference(now).inSeconds, lessThan(1));
    });
  });
}
