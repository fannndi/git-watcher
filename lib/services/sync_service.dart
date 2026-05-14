import '../models/sync_log.dart';
import '../models/watched_repo.dart';
import 'github_service.dart';
import 'notification_service.dart';
import 'storage_service.dart';

class SyncService {
  static Future<Map<String, int>> checkUpdates() async {
    final storage = StorageService();
    final github = GitHubService();
    final repos = await storage.getRepos();
    final updates = <String, int>{};
    final updatedRepos = <WatchedRepo>[];

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
        await storage.mergeCachedCommits(repo, commits);
        if (repo.lastSha.isNotEmpty && latest.sha != repo.lastSha) {
          final count =
              commits.takeWhile((commit) => commit.sha != repo.lastSha).length;
          final updateKey = '${repo.fullName} (${repo.branch})';
          updates[updateKey] = count == 0 ? 1 : count;
        }

        repo.lastSha = latest.sha;
        repo.lastCommitAt = latest.date;
        updatedRepos.add(repo);
      } catch (_) {
        updatedRepos.add(repo);
      }
    }

    await storage.saveRepos(updatedRepos);
    await storage.saveUpdateSummary(updates);
    
    final now = DateTime.now();
    await storage.setLastSyncAt(now);

    if (updates.isNotEmpty) {
      await storage.addSyncLog(
        SyncLog(
          syncedAt: now,
          updates: updates,
        ),
      );
      await NotificationService.showUpdateNotification(updates);
    }

    final appSettings = await storage.getAppSettings();
    await storage.setNextSyncAt(
        DateTime.now().add(Duration(minutes: appSettings.syncIntervalMinutes)));

    return updates;
  }
}
