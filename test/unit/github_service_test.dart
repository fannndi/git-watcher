import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:git_watcher/models/github_credentials.dart';
import 'package:git_watcher/models/watched_repo.dart';
import 'package:git_watcher/services/github_service.dart';
import 'package:git_watcher/services/storage_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const repo = WatchedRepo(
    owner: 'flutter',
    repo: 'flutter',
    branch: 'main',
    syncMode: 'minimal',
  );

  StorageService buildStorage() {
    SharedPreferences.setMockInitialValues({});
    return StorageService();
  }

  test('fetchCommitsBatch returns null without credentials', () async {
    var called = false;
    final client = MockClient((request) async {
      called = true;
      return http.Response('{}', 200);
    });

    final result = await GitHubService(
      client: client,
      storage: buildStorage(),
    ).fetchCommitsBatch([repo]);

    expect(result, isNull);
    expect(called, false);
  });

  test('fetchCommitsBatch parses the GraphQL response', () async {
    final storage = buildStorage();
    await storage.saveCredentials(
      const GitHubCredentials(username: 'user', token: 'token'),
    );

    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode({
          'data': {
            'r0': {
              'ref': {
                'target': {
                  'history': {
                    'nodes': [
                      {
                        'oid': 'abc123',
                        'message': 'Fix bug\n\nBody',
                        'committedDate': '2024-01-15T10:30:00Z',
                        'author': {
                          'name': 'Budi',
                          'user': {'login': 'budi'},
                        },
                      },
                    ],
                  },
                },
              },
            },
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final result = await GitHubService(
      client: client,
      storage: storage,
    ).fetchCommitsBatch([repo]);

    expect(result, isNotNull);
    final commits = result!['flutter/flutter (main)'];
    expect(commits, isNotNull);
    expect(commits!.single.sha, 'abc123');
    expect(commits.single.author, 'budi');
    expect(commits.single.title, 'Fix bug');

    expect(captured.url.path, '/graphql');
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    final variables = body['variables'] as Map<String, dynamic>;
    expect(variables['owner0'], 'flutter');
    expect(variables['name0'], 'flutter');
    expect(variables['ref0'], 'refs/heads/main');
    expect(variables['first'], 25);
  });

  test('fetchCommitsBatch returns null when GraphQL reports errors', () async {
    final storage = buildStorage();
    await storage.saveCredentials(
      const GitHubCredentials(username: 'user', token: 'token'),
    );

    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'errors': [
            {'message': 'Something went wrong'},
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final result = await GitHubService(
      client: client,
      storage: storage,
    ).fetchCommitsBatch([repo]);

    expect(result, isNull);
  });

  test('fetchCommitsPage sends If-None-Match and handles 304', () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response('', 304);
    });

    final page = await GitHubService(
      client: client,
      storage: buildStorage(),
    ).fetchCommitsPage('flutter', 'flutter', 'main', etag: 'W/"abc"');

    expect(page.notModified, true);
    expect(page.commits, isEmpty);
    expect(captured.headers['If-None-Match'], 'W/"abc"');
  });

  test('fetchCommitsPage returns the response etag', () async {
    final client = MockClient((request) async {
      return http.Response(
        '[]',
        200,
        headers: {'etag': 'W/"new"', 'content-type': 'application/json'},
      );
    });

    final page = await GitHubService(
      client: client,
      storage: buildStorage(),
    ).fetchCommitsPage('flutter', 'flutter', 'main');

    expect(page.notModified, false);
    expect(page.etag, 'W/"new"');
  });
}
