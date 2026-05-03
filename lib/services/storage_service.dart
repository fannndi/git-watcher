import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

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
}
