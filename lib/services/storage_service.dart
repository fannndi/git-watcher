import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/commit.dart';
import '../models/app_settings.dart';
import '../models/github_credentials.dart';
import '../models/sync_log.dart';
import '../models/watched_repo.dart';
import '../utils/constants.dart';

class StorageService {
  Future<SharedPreferences> _getPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs;
  }

  Future<List<WatchedRepo>> getRepos() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(watchedReposKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => WatchedRepo.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveRepos(List<WatchedRepo> repos) async {
    final prefs = await _getPrefs();
    final raw = jsonEncode(repos.map((repo) => repo.toJson()).toList());
    await prefs.setString(watchedReposKey, raw);
  }

  Future<AppSettings> getAppSettings() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(appSettingsKey);
    if (raw == null || raw.isEmpty) {
      return const AppSettings.defaults();
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return AppSettings.fromJson(decoded);
  }

  Future<void> saveAppSettings(AppSettings settings) async {
    final prefs = await _getPrefs();
    await prefs.setString(appSettingsKey, jsonEncode(settings.toJson()));
  }

  Future<void> saveUpdateSummary(Map<String, int> updates) async {
    final prefs = await _getPrefs();
    await prefs.setString(updateSummaryKey, jsonEncode(updates));
  }

  Future<Map<String, int>> getUpdateSummary() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(updateSummaryKey);
    if (raw == null || raw.isEmpty) {
      return {};
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, (value as num).toInt()));
  }

  Future<DateTime?> getLastSyncAt() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(lastSyncAtKey);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> setLastSyncAt(DateTime time) async {
    final prefs = await _getPrefs();
    await prefs.setString(lastSyncAtKey, time.toIso8601String());
  }

  Future<List<SyncLog>> getSyncHistory() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(syncHistoryKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => SyncLog.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> addSyncLog(SyncLog log) async {
    final prefs = await _getPrefs();
    final history = await getSyncHistory();
    final updated = [log, ...history].take(30).toList();
    final raw = jsonEncode(updated.map((item) => item.toJson()).toList());
    await prefs.setString(syncHistoryKey, raw);
  }

  Future<List<Commit>> getCachedCommits(WatchedRepo repo) async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_commitCacheKey(repo));
    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => Commit.fromCacheJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveCachedCommits(
    WatchedRepo repo,
    List<Commit> commits,
  ) async {
    final prefs = await _getPrefs();
    final unique = <String, Commit>{};
    for (final commit in commits) {
      unique[commit.sha] = commit;
    }

    final sorted = unique.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final raw = jsonEncode(sorted.map((commit) => commit.toJson()).toList());
    await prefs.setString(_commitCacheKey(repo), raw);
  }

  Future<void> mergeCachedCommits(
    WatchedRepo repo,
    List<Commit> commits,
  ) async {
    final existing = await getCachedCommits(repo);
    await saveCachedCommits(repo, [...commits, ...existing]);
  }

  // ── Credentials ──────────────────────────────────────────────────────────

  Future<GitHubCredentials> getCredentials() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(githubCredentialsKey);
    if (raw == null || raw.isEmpty) {
      return const GitHubCredentials.empty();
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return GitHubCredentials.fromJson(decoded);
    } catch (_) {
      return const GitHubCredentials.empty();
    }
  }

  Future<void> saveCredentials(GitHubCredentials credentials) async {
    final prefs = await _getPrefs();
    await prefs.setString(
      githubCredentialsKey,
      jsonEncode(credentials.toJson()),
    );
  }

  Future<void> clearCredentials() async {
    final prefs = await _getPrefs();
    await prefs.remove(githubCredentialsKey);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _commitCacheKey(WatchedRepo repo) {
    return '$commitCachePrefix'
        '${repo.owner}_${repo.repo}_${repo.branch}_${repo.syncMode}';
  }

  // ── Background Sync Diagnostics ──────────────────────────────────────────

  Future<DateTime?> getLastBackgroundSyncAt() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(lastBackgroundSyncAtKey);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> setLastBackgroundSyncAt(DateTime time) async {
    final prefs = await _getPrefs();
    await prefs.setString(lastBackgroundSyncAtKey, time.toIso8601String());
  }

  Future<String?> getLastBackgroundSyncStatus() async {
    final prefs = await _getPrefs();
    return prefs.getString(lastBackgroundSyncStatusKey);
  }

  Future<void> setLastBackgroundSyncStatus(String status) async {
    final prefs = await _getPrefs();
    await prefs.setString(lastBackgroundSyncStatusKey, status);
  }

  // ── Sync Lock ────────────────────────────────────────────────────────────

  Future<bool> isSyncLocked() async {
    final prefs = await _getPrefs();
    final lockTimeStr = prefs.getString(syncLockKey);
    if (lockTimeStr == null || lockTimeStr.isEmpty) return false;

    final lockTime = DateTime.tryParse(lockTimeStr);
    if (lockTime == null) return false;

    // Auto-release lock after 10 minutes (safety against crashes)
    if (DateTime.now().difference(lockTime).inMinutes > 10) {
      await releaseSyncLock();
      return false;
    }

    return true;
  }

  Future<void> acquireSyncLock() async {
    final prefs = await _getPrefs();
    await prefs.setString(syncLockKey, DateTime.now().toIso8601String());
  }

  Future<void> releaseSyncLock() async {
    final prefs = await _getPrefs();
    await prefs.remove(syncLockKey);
  }
}
