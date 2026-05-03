import '../models/sync_log.dart';
import '../models/watched_repo.dart';
import 'github_service.dart';
import 'notification_service.dart';
import 'storage_service.dart';

class SyncService {
  static Future<Map<String, int>> checkUpdates({
    bool forceNotification = false,
  }) async {
    final storage = StorageService();
    final github = GitHubService();
    final repos = await storage.getRepos();
    final updates = <String, int>{};
    final updatedRepos = <WatchedRepo>[];

    for (final repo in repos) {
      try {
        final commits = await github.fetchCommits(repo.owner, repo.repo);
        if (commits.isEmpty) {
          updatedRepos.add(repo);
          continue;
        }

        final latest = commits.first;
        if (repo.lastSha.isNotEmpty && latest.sha != repo.lastSha) {
          final count = commits
              .takeWhile((commit) => commit.sha != repo.lastSha)
              .length;
          updates[repo.fullName] = count == 0 ? 1 : count;
        }

        repo.lastSha = latest.sha;
        updatedRepos.add(repo);
      } catch (_) {
        updatedRepos.add(repo);
      }
    }

    await storage.saveRepos(updatedRepos);
    await storage.saveUpdateSummary(updates);
    await storage.addSyncLog(
      SyncLog(
        syncedAt: DateTime.now(),
        updates: updates,
      ),
    );

    if (updates.isNotEmpty || forceNotification) {
      await NotificationService.showUpdateNotification();
    }

    return updates;
  }
}
