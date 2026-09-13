import 'package:flutter/foundation.dart';

import '../models/sync_log.dart';
import '../models/watched_repo.dart';
import '../utils/constants.dart';
import '../utils/strings.dart';
import 'github_service.dart';
import 'notification_service.dart';
import 'storage_service.dart';

class SyncService {
  static Future<Map<String, int>> checkUpdates({
    bool isBackground = false,
    StorageService? storage,
    GitHubService? github,
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

    try {
      final repos = await storage.getRepos();
      if (repos.isEmpty) {
        await storage.setLastSyncAt(DateTime.now());
        return {};
      }

      final settings = await storage.getAppSettings();

      for (final repo in repos) {
        try {
          final limit = repo.syncMode == syncModeMinimal
              ? maxFetchedCommits
              : backgroundSyncFetchLimit;
          final commits = await github.fetchCommits(
            repo.owner,
            repo.repo,
            repo.branch,
            limit: limit,
          );

          if (commits.isEmpty) {
            updatedRepos.add(repo);
            continue;
          }

          final latest = commits.first;
          if (repo.lastSha.isNotEmpty && latest.sha != repo.lastSha) {
            final count = commits
                .takeWhile((commit) => commit.sha != repo.lastSha)
                .length;
            if (count > 0) {
              updates['${repo.fullName} (${repo.branch})'] = count;
            }
          }

          await storage.mergeCachedCommits(repo, commits);
          updatedRepos.add(
            repo.copyWith(lastSha: latest.sha, lastCommitAt: latest.date),
          );
        } catch (e) {
          debugPrint('Sync error for ${repo.fullName}: $e');
          updatedRepos.add(repo);
        }
      }

      if (updatedRepos.isNotEmpty) {
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
}
