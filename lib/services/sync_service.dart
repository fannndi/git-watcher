import '../models/sync_log.dart';
import '../models/watched_repo.dart';
import 'github_service.dart';
import 'notification_service.dart';
import 'storage_service.dart';

class SyncService {
  static Future<Map<String, int>> checkUpdates({bool isBackground = false}) async {
    final storage = StorageService();

    // Debounce: Hindari sinkronisasi berulang jika baru saja dilakukan (< 30 detik)
    // Ini krusial jika background worker dan UI mentrigger sync hampir bersamaan.
    final lastSyncAt = await storage.getLastSyncAt();
    if (lastSyncAt != null &&
        DateTime.now().difference(lastSyncAt).inSeconds < 30) {
      return {};
    }

    final github = GitHubService();
    final updates = <String, int>{};
    final updatedRepos = <WatchedRepo>[];

    try {
      final repos = await storage.getRepos();
      if (repos.isEmpty) {
        await storage.setLastSyncAt(DateTime.now());
        return {};
      }

      for (final repo in repos) {
        try {
          final commits = await github.fetchCommits(
            repo.owner,
            repo.repo,
            repo.branch,
          );

          if (commits.isEmpty) {
            updatedRepos.add(repo);
            continue;
          }

          final latest = commits.first;

          if (repo.lastSha.isNotEmpty && latest.sha != repo.lastSha) {
            final count = commits.takeWhile((c) => c.sha != repo.lastSha).length;
            final updateKey = '${repo.fullName} (${repo.branch})';
            updates[updateKey] = count == 0 ? 1 : count;
          }

          await storage.mergeCachedCommits(repo, commits);
          repo.lastSha = latest.sha;
          repo.lastCommitAt = latest.date;
          updatedRepos.add(repo);
        } catch (_) {
          updatedRepos.add(repo);
        }
      }

      if (updatedRepos.isNotEmpty) {
        await storage.saveRepos(updatedRepos);
      }

      final now = DateTime.now();
      await storage.setLastSyncAt(now);

      if (updates.isNotEmpty) {
        await storage.saveUpdateSummary(updates);
        await storage.addSyncLog(SyncLog(syncedAt: now, updates: updates));

        // Apps yang smart hanya mengirim notifikasi sistem jika user TIDAK sedang membuka apps.
        if (isBackground) {
          await NotificationService.showUpdateNotification(updates);
        }
      }
    } finally {
      final appSettings = await storage.getAppSettings();
      await storage.setNextSyncAt(
        DateTime.now().add(Duration(minutes: appSettings.syncIntervalMinutes)),
      );
    }

    return updates;
  }
}
