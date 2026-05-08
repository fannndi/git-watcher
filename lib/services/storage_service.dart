import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/commit.dart';
import '../models/app_settings.dart';
import '../models/github_credentials.dart';
import '../models/sync_log.dart';
import '../models/watched_repo.dart';
import '../utils/constants.dart';

class StorageService {
  Future<List<WatchedRepo>> getRepos() async {
    final prefs = await SharedPreferences.getInstance();
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
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(repos.map((repo) => repo.toJson()).toList());
    await prefs.setString(watchedReposKey, raw);
  }

  Future<AppSettings> getAppSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(appSettingsKey);
    if (raw == null || raw.isEmpty) {
      return const AppSettings.defaults();
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return AppSettings.fromJson(decoded);
  }

  Future<void> saveAppSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(appSettingsKey, jsonEncode(settings.toJson()));
  }

  Future<void> saveUpdateSummary(Map<String, int> updates) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(updateSummaryKey, jsonEncode(updates));
  }

  Future<Map<String, int>> getUpdateSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(updateSummaryKey);
    if (raw == null || raw.isEmpty) {
      return {};
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, (value as num).toInt()));
  }

  Future<List<SyncLog>> getSyncHistory() async {
    final prefs = await SharedPreferences.getInstance();
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
    final prefs = await SharedPreferences.getInstance();
    final history = await getSyncHistory();
    final updated = [log, ...history].take(30).toList();
    final raw = jsonEncode(updated.map((item) => item.toJson()).toList());
    await prefs.setString(syncHistoryKey, raw);
  }

  Future<List<Commit>> getCachedCommits(WatchedRepo repo) async {
    final prefs = await SharedPreferences.getInstance();
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
    final prefs = await SharedPreferences.getInstance();
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
    final prefs = await SharedPreferences.getInstance();
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      githubCredentialsKey,
      jsonEncode(credentials.toJson()),
    );
  }

  Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(githubCredentialsKey);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _commitCacheKey(WatchedRepo repo) {
    return '$commitCachePrefix'
        '${repo.owner}_${repo.repo}_${repo.branch}_${repo.syncMode}';
  }
}