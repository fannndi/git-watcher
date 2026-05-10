import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/commit.dart';
import '../models/github_credentials.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

class GitHubService {
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
        throw Exception('Gagal mengambil branch repository.');
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
      throw Exception('Gagal mengambil commit repository.');
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
      throw Exception('Gagal mengambil commit repository.');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((item) => Commit.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Coba request tanpa auth dulu.
  /// Kalau dapat 401 atau 404, retry pakai credentials yang tersimpan.
  /// Kalau credentials kosong, kembalikan response asli.
  Future<http.Response> _get(Uri uri) async {
    final publicResponse = await _client.get(uri, headers: _publicHeaders);

    // Sukses atau error selain auth — langsung return
    if (publicResponse.statusCode != 401 &&
        publicResponse.statusCode != 404) {
      return publicResponse;
    }

    // Coba ambil credentials untuk fallback
    final credentials = await _storage.getCredentials();
    if (credentials.isEmpty) {
      return publicResponse;
    }

    // Retry dengan auth
    final authResponse = await _client.get(
      uri,
      headers: _authHeaders(credentials),
    );

    return authResponse;
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
