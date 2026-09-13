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

    await storage.acquireSyncLock();

    github ??= GitHubService();
    final updates = <String, int>{};
    final updatedRepos = <WatchedRepo>[];
    var reposChanged = false;

    try {
      final repos = await storage.getRepos();
      if (repos.isEmpty) {
        await storage.setLastSyncAt(DateTime.now());
        return {};
      }

      final settings = await storage.getAppSettings();
      final results = await _fetchAll(github, repos, onProgress);

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
          final count =
              commits.takeWhile((commit) => commit.sha != repo.lastSha).length;
          if (count > 0) {
            updates['${repo.fullName} (${repo.branch})'] = count;
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

      final now = DateTime.now();
      await storage.setLastSyncAt(now);

      if (updates.isNotEmpty) {
        await storage.addSyncLog(SyncLog(syncedAt: now, updates: updates));

        if (isBackground && settings.notificationsEnabled) {
          try {
            await NotificationService.showUpdateNotification(
              updates,
              stringsFor(settings.languageCode),
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

  static Future<List<_RepoFetch>> _fetchAll(
    GitHubService github,
    List<WatchedRepo> repos,
    void Function(int completed, int total)? onProgress,
  ) async {
    var completed = 0;
    onProgress?.call(completed, repos.length);

    return Future.wait(
      repos.map((repo) async {
        _RepoFetch result;
        try {
          result = _RepoFetch(
            repo,
            await github.fetchCommits(
              repo.owner,
              repo.repo,
              repo.branch,
            ),
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
