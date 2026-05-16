import '../models/sync_log.dart';
import '../models/watched_repo.dart';
import 'github_service.dart';
import 'notification_service.dart';
import 'storage_service.dart';

class SyncService {
  static Future<Map<String, int>> checkUpdates({
    bool isBackground = false,
  }) async {
    final storage = StorageService();

    // Cek sync lock — hindari dua proses sync berjalan bersamaan
    if (await storage.isSyncLocked()) {
      if (isBackground) {
        // Background: tunggu sebentar lalu coba sekali lagi
        await Future.delayed(const Duration(seconds: 5));
        if (await storage.isSyncLocked()) return {};
      } else {
        return {};
      }
    }

    // Debounce foreground: jangan sync jika baru saja dilakukan (< 20 detik)
    if (!isBackground) {
      final lastSyncAt = await storage.getLastSyncAt();
      if (lastSyncAt != null &&
          DateTime.now().difference(lastSyncAt).inSeconds < 20) {
        return {};
      }
    }

    await storage.acquireSyncLock();

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
            if (count > 0) {
              updates['${repo.fullName} (${repo.branch})'] = count;
            }
          } else if (repo.lastSha.isEmpty) {
            // Inisialisasi lastSha untuk repo baru
            repo.lastSha = latest.sha;
            repo.lastCommitAt = latest.date;
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

        // Kirim notifikasi hanya dari background — foreground cukup snackbar
        if (isBackground) {
          try {
            await NotificationService.showUpdateNotification(updates);
          } catch (_) {
            // Non-fatal: jangan gagalkan sync karena notifikasi gagal
          }
        }
      }
    } finally {
      await storage.releaseSyncLock();
    }

    return updates;
  }
}
