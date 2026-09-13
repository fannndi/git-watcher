import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/commit.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

class GitHubService {
  GitHubService({http.Client? client, StorageService? storage})
      : _client = client ?? http.Client(),
        _storage = storage ?? StorageService();

  final http.Client _client;
  final StorageService _storage;

  Future<Map<String, dynamic>?> getRepo(String owner, String repo) async {
    final response = await _get(_uri('/repos/$owner/$repo'));
    if (response.statusCode != 200) {
      return null;
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<String>> fetchBranches(String owner, String repo) async {
    final branches = <String>[];
    var page = 1;

    while (true) {
      final response = await _get(_uri('/repos/$owner/$repo/branches', {
        'per_page': '$githubPageSize',
        'page': '$page',
      }));
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch branches ($owner/$repo)');
      }

      final decoded = jsonDecode(response.body) as List<dynamic>;
      if (decoded.isEmpty) {
        break;
      }

      for (final item in decoded) {
        branches.add((item as Map<String, dynamic>)['name'] as String);
      }
      page++;
    }

    return branches;
  }

  Future<List<Commit>> fetchCommits(
    String owner,
    String repo,
    String branch, {
    int limit = syncFetchLimit,
  }) async {
    final commits = <Commit>[];
    var page = 1;

    while (commits.length < limit) {
      final remaining = limit - commits.length;
      final perPage = remaining < githubPageSize ? remaining : githubPageSize;
      final response = await _get(_uri('/repos/$owner/$repo/commits', {
        'sha': branch,
        'per_page': '$perPage',
        'page': '$page',
      }));
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch commits ($owner/$repo@$branch)');
      }

      final decoded = jsonDecode(response.body) as List<dynamic>;
      if (decoded.isEmpty) {
        break;
      }

      commits.addAll(
        decoded.map((item) => Commit.fromJson(item as Map<String, dynamic>)),
      );
      page++;
    }

    return commits.take(limit).toList();
  }

  Future<List<Commit>> fetchLatestDayCommits(
    String owner,
    String repo,
    String branch,
  ) async {
    final commits = <Commit>[];
    DateTime? latestDay;
    var page = 1;

    while (true) {
      final pageCommits = await _fetchCommitPage(owner, repo, branch, page);
      if (pageCommits.isEmpty) {
        break;
      }

      for (final commit in pageCommits) {
        final local = commit.date.toLocal();
        final day = DateTime(local.year, local.month, local.day);
        latestDay ??= day;

        if (day != latestDay) {
          return commits;
        }

        commits.add(commit);
      }
      page++;
    }

    return commits;
  }

  Future<List<Commit>> fetchCommitsForMode(
    String owner,
    String repo,
    String branch,
    String syncMode,
  ) {
    if (syncMode == syncModeExtended) {
      return fetchCommits(owner, repo, branch, limit: extendedSyncCommitLimit);
    }
    if (syncMode == syncModeLatest) {
      return fetchCommits(owner, repo, branch, limit: latestSyncCommitLimit);
    }
    return fetchLatestDayCommits(owner, repo, branch);
  }

  Future<CommitDetail> fetchCommitDetail(
    String owner,
    String repo,
    String sha,
  ) async {
    final response = await _get(_uri('/repos/$owner/$repo/commits/$sha'));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch commit detail ($sha)');
    }

    return CommitDetail.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<List<Commit>> _fetchCommitPage(
    String owner,
    String repo,
    String branch,
    int page,
  ) async {
    final response = await _get(_uri('/repos/$owner/$repo/commits', {
      'sha': branch,
      'per_page': '$githubPageSize',
      'page': '$page',
    }));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch commits ($owner/$repo@$branch)');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((item) => Commit.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.https(githubApiHost, path, query);
  }

  Future<http.Response> _get(Uri uri) async {
    final credentials = await _storage.getCredentials();
    final authHeaders = _headers(
      credentials.isNotEmpty ? credentials.basicAuth : null,
    );

    var response =
        await _client.get(uri, headers: authHeaders).timeout(apiTimeout);
    if (response.statusCode == 401 && credentials.isNotEmpty) {
      response =
          await _client.get(uri, headers: _headers(null)).timeout(apiTimeout);
    }

    if (response.statusCode >= 500) {
      await Future.delayed(const Duration(seconds: 2));
      response =
          await _client.get(uri, headers: authHeaders).timeout(apiTimeout);
    }

    return response;
  }

  Map<String, String> _headers(String? authorization) => {
        'Accept': githubAcceptHeader,
        'X-GitHub-Api-Version': githubApiVersion,
        if (authorization != null) 'Authorization': authorization,
      };
}
