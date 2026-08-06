import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/commit.dart';
import '../models/github_credentials.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

class GitHubService {
  static const Duration _timeout = Duration(seconds: 30);

  final http.Client _client;
  final StorageService _storage;

  GitHubService({http.Client? client, StorageService? storage})
      : _client = client ?? http.Client(),
        _storage = storage ?? StorageService();

  // ── Public API ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getRepo(String owner, String repo) async {
    final uri = Uri.parse('$githubBaseUrl/repos/$owner/$repo');
    final response = await _get(uri);

    if (response.statusCode != 200) {
      return null;
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<String>> fetchBranches(String owner, String repo) async {
    final branches = <String>[];
    var page = 1;

    while (true) {
      final uri = Uri.https(
        'api.github.com',
        '/repos/$owner/$repo/branches',
        {'per_page': '100', 'page': '$page'},
      );
      final response = await _get(uri);

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch repository branches.');
      }

      final decoded = jsonDecode(response.body) as List<dynamic>;
      if (decoded.isEmpty) break;

      branches.addAll(
        decoded.map((item) {
          final branch = item as Map<String, dynamic>;
          return branch['name'] as String;
        }),
      );
      page++;
    }

    return branches;
  }

  Future<List<Commit>> fetchCommits(
    String owner,
    String repo,
    String branch,
  ) async {
    final uri = Uri.https(
      'api.github.com',
      '/repos/$owner/$repo/commits',
      {'sha': branch, 'per_page': '$maxFetchedCommits'},
    );
    final response = await _get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch repository commits.');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .take(maxFetchedCommits)
        .map((item) => Commit.fromJson(item as Map<String, dynamic>))
        .toList();
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
      if (pageCommits.isEmpty) break;

      for (final commit in pageCommits) {
        final day = DateTime(
          commit.date.toLocal().year,
          commit.date.toLocal().month,
          commit.date.toLocal().day,
        );
        latestDay ??= day;

        if (day != latestDay) return commits;

        commits.add(commit);
      }

      page++;
    }

    return commits;
  }

  Future<List<Commit>> fetchCommitsWithLimit(
    String owner,
    String repo,
    String branch,
    int limit,
  ) async {
    final commits = <Commit>[];
    var page = 1;

    while (commits.length < limit) {
      final pageCommits = await _fetchCommitPage(owner, repo, branch, page);
      if (pageCommits.isEmpty) break;

      commits.addAll(pageCommits);
      page++;
    }

    return commits.take(limit).toList();
  }

  Future<CommitDetail> fetchCommitDetail(
    String owner,
    String repo,
    String sha,
  ) async {
    final uri = Uri.https(
      'api.github.com',
      '/repos/$owner/$repo/commits/$sha',
    );
    final response = await _get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch commit detail.');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return CommitDetail.fromJson(decoded);
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<List<Commit>> _fetchCommitPage(
    String owner,
    String repo,
    String branch,
    int page,
  ) async {
    final uri = Uri.https(
      'api.github.com',
      '/repos/$owner/$repo/commits',
      {'sha': branch, 'per_page': '100', 'page': '$page'},
    );
    final response = await _get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch repository commits.');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((item) => Commit.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<http.Response> _get(Uri uri, {int retries = 2}) async {
    final credentials = await _storage.getCredentials();

    for (var attempt = 0; attempt <= retries; attempt++) {
      http.Response response;

      // If we have credentials, use them first for better rate limits (5000/hr)
      if (credentials.isNotEmpty) {
        response = await _client
            .get(
              uri,
              headers: _authHeaders(credentials),
            )
            .timeout(_timeout);

        // If auth fails, try public as fallback
        if (response.statusCode == 401) {
          response =
              await _client.get(uri, headers: _publicHeaders).timeout(_timeout);
        }
      } else {
        // Public request (60/hr limit)
        response =
            await _client.get(uri, headers: _publicHeaders).timeout(_timeout);
      }

      // Rate limit: wait and retry
      if (response.statusCode == 403 || response.statusCode == 429) {
        if (attempt < retries) {
          final resetTime = response.headers['x-ratelimit-reset'];
          if (resetTime != null) {
            final reset = DateTime.fromMillisecondsSinceEpoch(
              int.parse(resetTime) * 1000,
            );
            final wait = reset.difference(DateTime.now());
            if (wait.inSeconds > 0 && wait.inMinutes < 5) {
              await Future.delayed(wait);
              continue;
            }
          }
          // Default wait: 60 seconds
          await Future.delayed(const Duration(seconds: 60));
          continue;
        }
      }

      // Server error: retry
      if (response.statusCode >= 500 && attempt < retries) {
        await Future.delayed(Duration(seconds: (attempt + 1) * 2));
        continue;
      }

      return response;
    }

    // Should not reach here, but return error response
    return http.Response('Max retries exceeded', 503);
  }

  Map<String, String> get _publicHeaders => const {
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
      };

  Map<String, String> _authHeaders(GitHubCredentials credentials) => {
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
        'Authorization': credentials.basicAuth,
      };
}
