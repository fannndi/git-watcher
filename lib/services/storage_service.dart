import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/commit.dart';
import '../models/github_credentials.dart';
import '../models/sync_log.dart';
import '../models/watched_repo.dart';
import '../utils/constants.dart';

class StorageService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  SharedPreferences? _prefs;

  Future<SharedPreferences> _instance() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<List<WatchedRepo>> getRepos() async {
    final raw = (await _instance()).getString(watchedReposKey);
    return _decodeList(raw, WatchedRepo.fromJson);
  }

  Future<void> saveRepos(List<WatchedRepo> repos) async {
    final prefs = await _instance();
    await prefs.setString(
      watchedReposKey,
      jsonEncode(repos.map((repo) => repo.toJson()).toList()),
    );
  }

  Future<AppSettings> getAppSettings() async {
    final raw = (await _instance()).getString(appSettingsKey);
    if (raw == null || raw.isEmpty) {
      return const AppSettings.defaults();
    }

    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const AppSettings.defaults();
    }
  }

  Future<void> saveAppSettings(AppSettings settings) async {
    final prefs = await _instance();
    await prefs.setString(appSettingsKey, jsonEncode(settings.toJson()));
  }

  Future<List<SyncLog>> getSyncHistory() async {
    final raw = (await _instance()).getString(syncHistoryKey);
    return _decodeList(raw, SyncLog.fromJson);
  }

  Future<void> addSyncLog(SyncLog log) async {
    final history = await getSyncHistory();
    final updated = [log, ...history].take(maxSyncHistory).toList();
    final prefs = await _instance();
    await prefs.setString(
      syncHistoryKey,
      jsonEncode(updated.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> clearSyncHistory() async {
    final prefs = await _instance();
    await prefs.remove(syncHistoryKey);
  }

  Future<List<Commit>> getCachedCommits(WatchedRepo repo) async {
    final raw = (await _instance()).getString(_commitCacheKey(repo));
    return _decodeList(raw, Commit.fromCacheJson);
  }

  Future<void> saveCachedCommits(WatchedRepo repo, List<Commit> commits) async {
    final unique = <String, Commit>{};
    for (final commit in commits) {
      unique[commit.sha] = commit;
    }

    final sorted = unique.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final capped = sorted.take(maxCachedCommits).toList();

    final prefs = await _instance();
    await prefs.setString(
      _commitCacheKey(repo),
      jsonEncode(capped.map((commit) => commit.toJson()).toList()),
    );
  }

  Future<void> mergeCachedCommits(
    WatchedRepo repo,
    List<Commit> commits,
  ) async {
    final existing = await getCachedCommits(repo);
    await saveCachedCommits(repo, [...commits, ...existing]);
  }

  Future<void> removeCachedCommits(WatchedRepo repo) async {
    final prefs = await _instance();
    await prefs.remove(_commitCacheKey(repo));
  }

  Future<void> replaceRepo(WatchedRepo repo) async {
    final repos = await getRepos();
    final updated = repos
        .map(
          (item) => item.owner == repo.owner &&
                  item.repo == repo.repo &&
                  item.branch == repo.branch
              ? repo
              : item,
        )
        .toList();
    await saveRepos(updated);
  }

  Future<GitHubCredentials> getCredentials() async {
    final secure = await _readSecure(githubCredentialsKey);
    if (secure != null && secure.isNotEmpty) {
      return _decodeCredentials(secure);
    }

    final raw = (await _instance()).getString(githubCredentialsKey);
    if (raw == null || raw.isEmpty) {
      return const GitHubCredentials.empty();
    }

    final credentials = _decodeCredentials(raw);
    if (credentials.isNotEmpty) {
      await _writeSecure(githubCredentialsKey, raw);
      await (await _instance()).remove(githubCredentialsKey);
    }
    return credentials;
  }

  Future<void> saveCredentials(GitHubCredentials credentials) async {
    final raw = jsonEncode(credentials.toJson());
    if (await _writeSecure(githubCredentialsKey, raw)) {
      await (await _instance()).remove(githubCredentialsKey);
      return;
    }

    final prefs = await _instance();
    await prefs.setString(githubCredentialsKey, raw);
  }

  Future<void> clearCredentials() async {
    await _deleteSecure(githubCredentialsKey);
    final prefs = await _instance();
    await prefs.remove(githubCredentialsKey);
  }

  GitHubCredentials _decodeCredentials(String raw) {
    try {
      return GitHubCredentials.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return const GitHubCredentials.empty();
    }
  }

  Future<String?> _readSecure(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (_) {
      return null;
    }
  }

  Future<bool> _writeSecure(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _deleteSecure(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (_) {}
  }

  Future<DateTime?> getLastSyncAt() async {
    final raw = (await _instance()).getString(lastSyncAtKey);
    return parseDate(raw);
  }

  Future<void> setLastSyncAt(DateTime time) async {
    final prefs = await _instance();
    await prefs.setString(lastSyncAtKey, time.toIso8601String());
  }

  Future<bool> isAlarmRegistered() async {
    final prefs = await _instance();
    return prefs.getBool(alarmRegisteredKey) ?? false;
  }

  Future<void> setAlarmRegistered(bool value) async {
    final prefs = await _instance();
    await prefs.setBool(alarmRegisteredKey, value);
  }

  Future<int?> getAlarmIntervalMinutes() async {
    final prefs = await _instance();
    return prefs.getInt(alarmIntervalKey);
  }

  Future<void> setAlarmIntervalMinutes(int minutes) async {
    final prefs = await _instance();
    await prefs.setInt(alarmIntervalKey, minutes);
  }

  Future<bool> isAlarmPrecise() async {
    final prefs = await _instance();
    return prefs.getBool(alarmPreciseKey) ?? false;
  }

  Future<void> setAlarmPrecise(bool value) async {
    final prefs = await _instance();
    await prefs.setBool(alarmPreciseKey, value);
  }

  Future<int> getUnreadCycles() async {
    final prefs = await _instance();
    return (prefs.getInt(unreadCyclesKey) ?? 0).clamp(0, maxUnreadCycles);
  }

  Future<void> setUnreadCycles(int cycles) async {
    final prefs = await _instance();
    await prefs.setInt(unreadCyclesKey, cycles.clamp(0, maxUnreadCycles));
  }

  Future<bool> hasCompletedSetup() async {
    final prefs = await _instance();
    return prefs.getBool(setupCompletedKey) ?? false;
  }

  Future<void> setCompletedSetup(bool value) async {
    final prefs = await _instance();
    await prefs.setBool(setupCompletedKey, value);
  }

  Future<DateTime?> getLastSeenAt() async {
    final raw = (await _instance()).getString(lastSeenAtKey);
    return parseDate(raw);
  }

  Future<void> setLastSeenAt(DateTime time) async {
    final prefs = await _instance();
    await prefs.setString(lastSeenAtKey, time.toIso8601String());
  }

  Future<String?> getMorningDigestDate() async {
    final prefs = await _instance();
    return prefs.getString(morningDigestKey);
  }

  Future<void> setMorningDigestDate(String date) async {
    final prefs = await _instance();
    await prefs.setString(morningDigestKey, date);
  }

  Future<bool> hasSeenTour() async {
    final prefs = await _instance();
    return prefs.getBool(hasSeenTourKey) ?? false;
  }

  Future<void> setHasSeenTour(bool value) async {
    final prefs = await _instance();
    await prefs.setBool(hasSeenTourKey, value);
  }

  Future<bool> isSyncLocked() async {
    final raw = (await _instance()).getString(syncLockKey);
    final lockTime = parseDate(raw);
    if (lockTime == null) {
      return false;
    }

    if (DateTime.now().difference(lockTime) > syncLockTimeout) {
      await releaseSyncLock();
      return false;
    }

    return true;
  }

  Future<void> acquireSyncLock() async {
    final prefs = await _instance();
    await prefs.setString(syncLockKey, DateTime.now().toIso8601String());
  }

  Future<void> releaseSyncLock() async {
    final prefs = await _instance();
    await prefs.remove(syncLockKey);
  }

  String _commitCacheKey(WatchedRepo repo) {
    return '$commitCachePrefix'
        '${repo.owner}_${repo.repo}_${repo.branch}_${repo.syncMode}';
  }

  List<T> _decodeList<T>(
    String? raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
