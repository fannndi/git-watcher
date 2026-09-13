import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/commit.dart';
import '../models/watched_repo.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

class CommitPage {
  const CommitPage({
    required this.commits,
    this.etag = '',
    this.notModified = false,
  });

  final List<Commit> commits;
  final String etag;
  final bool notModified;
}

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
    final page = await fetchCommitsPage(owner, repo, branch, limit: limit);
    return page.commits;
  }

  Future<CommitPage> fetchCommitsPage(
    String owner,
    String repo,
    String branch, {
    int limit = syncFetchLimit,
    String etag = '',
  }) async {
    final commits = <Commit>[];
    var responseEtag = etag;
    var page = 1;

    while (commits.length < limit) {
      final remaining = limit - commits.length;
      final perPage = remaining < githubPageSize ? remaining : githubPageSize;
      final response = await _get(
        _uri('/repos/$owner/$repo/commits', {
          'sha': branch,
          'per_page': '$perPage',
          'page': '$page',
        }),
        etag: page == 1 ? etag : null,
      );

      if (page == 1 && response.statusCode == 304) {
        return CommitPage(commits: const [], etag: etag, notModified: true);
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch commits ($owner/$repo@$branch)');
      }

      if (page == 1) {
        responseEtag = response.headers['etag'] ?? '';
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

    return CommitPage(
        commits: commits.take(limit).toList(), etag: responseEtag);
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

  Future<Map<String, List<Commit>>?> fetchCommitsBatch(
    List<WatchedRepo> repos, {
    int limit = syncFetchLimit,
  }) async {
    if (repos.isEmpty) {
      return const {};
    }

    final credentials = await _storage.getCredentials();
    if (credentials.isEmpty) {
      return null;
    }

    final variables = <String, dynamic>{'first': limit};
    final variableDefs = <String>['\$first: Int!'];
    final fields = StringBuffer();

    for (var i = 0; i < repos.length; i++) {
      final repo = repos[i];
      variables['owner$i'] = repo.owner;
      variables['name$i'] = repo.repo;
      variables['ref$i'] = 'refs/heads/${repo.branch}';
      variableDefs
        ..add('\$owner$i: String!')
        ..add('\$name$i: String!')
        ..add('\$ref$i: String!');
      fields.write(
        'r$i: repository(owner: \$owner$i, name: \$name$i) {'
        ' ref(qualifiedName: \$ref$i) { target { ... on Commit {'
        ' history(first: \$first) { nodes { oid message committedDate'
        ' author { name user { login } } } } } } } }',
      );
    }

    final query = 'query(${variableDefs.join(', ')}) { $fields }';

    http.Response response;
    try {
      response = await _client
          .post(
            Uri.https(githubApiHost, '/graphql'),
            headers: _headers(credentials.basicAuth),
            body: jsonEncode({'query': query, 'variables': variables}),
          )
          .timeout(apiTimeout);
    } catch (_) {
      return null;
    }

    if (response.statusCode != 200) {
      return null;
    }

    try {
      final decoded =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (decoded['errors'] != null) {
        return null;
      }

      final data = decoded['data'] as Map<String, dynamic>?;
      if (data == null) {
        return null;
      }

      final result = <String, List<Commit>>{};
      for (var i = 0; i < repos.length; i++) {
        final repoData = data['r$i'] as Map<String, dynamic>?;
        final ref = repoData?['ref'] as Map<String, dynamic>?;
        final target = ref?['target'] as Map<String, dynamic>?;
        final history = target?['history'] as Map<String, dynamic>?;
        final nodes = history?['nodes'] as List<dynamic>? ?? const [];

        result['${repos[i].fullName} (${repos[i].branch})'] = nodes
            .map((node) => _commitFromGraphql(node as Map<String, dynamic>))
            .toList();
      }

      return result;
    } catch (_) {
      return null;
    }
  }

  Commit _commitFromGraphql(Map<String, dynamic> node) {
    final author = node['author'] as Map<String, dynamic>? ?? const {};
    final user = author['user'] as Map<String, dynamic>? ?? const {};

    return Commit(
      sha: node['oid'] as String? ?? '',
      message: node['message'] as String? ?? '',
      date: parseDate(node['committedDate']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      author: (user['login'] as String?) ?? (author['name'] as String?) ?? '',
    );
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

  Future<http.Response> _get(Uri uri, {String? etag}) async {
    final credentials = await _storage.getCredentials();
    final authHeaders = _headers(
      credentials.isNotEmpty ? credentials.basicAuth : null,
      etag: etag,
    );

    var response =
        await _client.get(uri, headers: authHeaders).timeout(apiTimeout);
    if (response.statusCode == 401 && credentials.isNotEmpty) {
      response = await _client
          .get(uri, headers: _headers(null, etag: etag))
          .timeout(apiTimeout);
    }

    if (response.statusCode >= 500) {
      await Future.delayed(const Duration(seconds: 2));
      response =
          await _client.get(uri, headers: authHeaders).timeout(apiTimeout);
    }

    return response;
  }

  Map<String, String> _headers(String? authorization, {String? etag}) => {
        'Accept': githubAcceptHeader,
        'X-GitHub-Api-Version': githubApiVersion,
        if (authorization != null) 'Authorization': authorization,
        if (etag != null && etag.isNotEmpty) 'If-None-Match': etag,
      };
}
