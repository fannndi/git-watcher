import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/commit.dart';
import '../utils/constants.dart';

class GitHubService {
  final http.Client _client;

  GitHubService({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>?> getRepo(String owner, String repo) async {
    final uri = Uri.parse('$githubBaseUrl/repos/$owner/$repo');
    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode != 200) {
      return null;
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<Commit>> fetchCommits(String owner, String repo) async {
    final uri = Uri.parse(
      '$githubBaseUrl/repos/$owner/$repo/commits?per_page=$maxFetchedCommits',
    );
    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil commit repository.');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .take(maxFetchedCommits)
        .map((item) => Commit.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Map<String, String> get _headers => const {
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
      };
}
