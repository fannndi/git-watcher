import '../models/sync_log.dart';
import '../models/watched_repo.dart';
import 'github_service.dart';
import 'notification_service.dart';
import 'storage_service.dart';

class SyncService {
  static Future<Map<String, int>> checkUpdates({
    bool isBackground = false,
    int? customInterval,
  }) async {
    final storage = StorageService();
    
    // Check sync lock
    if (await storage.isSyncLocked()) {
      // Jika background, jangan menyerah begitu saja. 
      // Tunggu sebentar (retry lokal) sebelum menyerah.
      if (isBackground) {
        await Future.delayed(const Duration(seconds: 5));
        if (await storage.isSyncLocked()) {
          return {};
        }
      } else {
        return {};
      }
    }

    // Debounce: Hindari sinkronisasi berulang jika baru saja dilakukan (< 20 detik)
    // (diperpendek dari 30s agar lebih responsif)
    final lastSyncAt = await storage.getLastSyncAt();
    if (!isBackground && 
        lastSyncAt != null &&
        DateTime.now().difference(lastSyncAt).inSeconds < 20) {
      return {};
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
            // Hitung jumlah commit baru
            final count = commits.takeWhile((c) => c.sha != repo.lastSha).length;
            if (count > 0) {
              final updateKey = '${repo.fullName} (${repo.branch})';
              updates[updateKey] = count;
            }
          } else if (repo.lastSha.isEmpty) {
            // Inisialisasi lastSha jika kosong (misal repo baru atau error sebelumnya)
            repo.lastSha = latest.sha;
            repo.lastCommitAt = latest.date;
          }

          await storage.mergeCachedCommits(repo, commits);
          repo.lastSha = latest.sha;
          repo.lastCommitAt = latest.date;
          updatedRepos.add(repo);
        } catch (_) {
          // Tetap tambahkan ke updatedRepos agar tidak hilang dari storage
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
      await storage.releaseSyncLock();
      
      final appSettings = await storage.getAppSettings();
      final interval = customInterval ?? appSettings.syncIntervalMinutes;
      
      await storage.setNextSyncAt(
        DateTime.now().add(Duration(minutes: interval)),
      );
    }

    return updates;
  }
}
