import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../models/commit.dart';
import '../models/sync_log.dart';
import '../models/watched_repo.dart';
import '../utils/constants.dart';
import '../utils/strings.dart';
import 'github_service.dart';
import 'notification_service.dart';
import 'storage_service.dart';

class _RepoFetch {
  const _RepoFetch(this.repo, this.commits);

  final WatchedRepo repo;
  final List<Commit> commits;
}

class SyncService {
  static Future<Map<String, int>> checkUpdates({
    bool isBackground = false,
    bool morningDigest = false,
    StorageService? storage,
    GitHubService? github,
    void Function(int completed, int total)? onProgress,
  }) async {
    storage ??= StorageService();

    if (await storage.isSyncLocked()) {
      if (!isBackground) {
        return {};
      }
      await Future.delayed(const Duration(seconds: 5));
      if (await storage.isSyncLocked()) {
        return {};
      }
    }

    if (!isBackground) {
      final lastSyncAt = await storage.getLastSyncAt();
      if (lastSyncAt != null &&
          DateTime.now().difference(lastSyncAt) < foregroundSyncDebounce) {
        return {};
      }
    }

    final settings = await storage.getAppSettings();

    if (isBackground && settings.wifiOnly && !await _hasWifi()) {
      return {};
    }

    await storage.acquireSyncLock();

    github ??= GitHubService();
    final updates = <String, int>{};
    final notifyUpdates = <String, int>{};
    final newCommits = <String, List<Commit>>{};
    final updatedRepos = <WatchedRepo>[];
    var reposChanged = false;

    try {
      final repos = await storage.getRepos();
      if (repos.isEmpty) {
        await storage.setLastSyncAt(DateTime.now());
        return {};
      }

      final now = DateTime.now();
      final dueRepos = <WatchedRepo>[];
      for (final repo in repos) {
        if (_isDue(repo, now)) {
          dueRepos.add(repo);
        } else {
          updatedRepos.add(repo);
        }
      }

      final results = await _fetchAll(github, dueRepos, onProgress);

      for (final result in results) {
        final repo = result.repo;
        final commits = result.commits;

        if (commits.isEmpty) {
          updatedRepos.add(repo);
          continue;
        }

        final latest = commits.first;
        final isNewRepo = repo.lastSha.isEmpty;
        final hasNewCommits = !isNewRepo && latest.sha != repo.lastSha;

        if (hasNewCommits) {
          final newOnes = commits
              .takeWhile((commit) => commit.sha != repo.lastSha)
              .toList();
          if (newOnes.isNotEmpty) {
            final key = '${repo.fullName} (${repo.branch})';
            updates[key] = newOnes.length;
            if (!repo.muted) {
              notifyUpdates[key] = newOnes.length;
              newCommits[key] = newOnes;
            }
          }
        }

        if (hasNewCommits || isNewRepo) {
          await storage.mergeCachedCommits(repo, commits);
          updatedRepos.add(
            repo.copyWith(lastSha: latest.sha, lastCommitAt: latest.date),
          );
          reposChanged = true;
        } else {
          updatedRepos.add(repo);
        }
      }

      if (reposChanged) {
        await storage.saveRepos(updatedRepos);
      }

      final syncedAt = DateTime.now();
      await storage.setLastSyncAt(syncedAt);

      if (updates.isNotEmpty) {
        await storage.addSyncLog(SyncLog(syncedAt: syncedAt, updates: updates));
      }

      if (isBackground) {
        if (morningDigest) {
          await storage.setMorningDigestDate(_dateKey(syncedAt));
        }

        if (notifyUpdates.isNotEmpty && settings.notificationsEnabled) {
          try {
            await NotificationService.showUpdateNotification(
              notifyUpdates,
              newCommits,
              stringsFor(settings.languageCode),
              morningDigest: morningDigest,
            );
          } catch (e) {
            debugPrint('Sync notification failed: $e');
          }
        }
      }
    } finally {
      await storage.releaseSyncLock();
    }

    return updates;
  }

  static bool _isDue(WatchedRepo repo, DateTime now) {
    final lastCommitAt = repo.lastCommitAt;
    if (lastCommitAt == null) {
      return true;
    }
    if (now.difference(lastCommitAt).inDays < staleRepoDays) {
      return true;
    }
    return now.hour.isEven;
  }

  static Future<bool> _hasWifi() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet);
    } catch (_) {
      return true;
    }
  }

  static String _dateKey(DateTime time) =>
      '${time.year}-${time.month}-${time.day}';

  static Future<List<_RepoFetch>> _fetchAll(
    GitHubService github,
    List<WatchedRepo> repos,
    void Function(int completed, int total)? onProgress,
  ) async {
    if (repos.isEmpty) {
      return const [];
    }

    onProgress?.call(0, repos.length);

    final batched = await github.fetchCommitsBatch(repos);
    if (batched != null) {
      onProgress?.call(repos.length, repos.length);
      return [
        for (final repo in repos)
          _RepoFetch(
            repo,
            batched['${repo.fullName} (${repo.branch})'] ?? const [],
          ),
      ];
    }

    var completed = 0;
    return Future.wait(
      repos.map((repo) async {
        _RepoFetch result;
        try {
          result = _RepoFetch(
            repo,
            await github.fetchCommits(repo.owner, repo.repo, repo.branch),
          );
        } catch (e) {
          debugPrint('Sync error for ${repo.fullName}: $e');
          result = _RepoFetch(repo, const []);
        }

        completed++;
        onProgress?.call(completed, repos.length);
        return result;
      }),
    );
  }
}
