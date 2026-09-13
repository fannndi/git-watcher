import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:git_watcher/models/github_credentials.dart';
import 'package:git_watcher/models/watched_repo.dart';
import 'package:git_watcher/services/github_service.dart';
import 'package:git_watcher/services/storage_service.dart';
import 'package:git_watcher/services/sync_service.dart';
import 'package:git_watcher/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SyncService', () {
    late StorageService storage;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storage = StorageService();
    });

    GitHubService githubWith(MockClient client) {
      return GitHubService(client: client, storage: storage);
    }

    http.Response restCommits(List<Map<String, dynamic>> commits) {
      return http.Response(
        jsonEncode(commits),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    Map<String, dynamic> commitJson(String sha, String message, String date) {
      return {
        'sha': sha,
        'commit': {
          'message': message,
          'author': {'name': 'Budi', 'date': date},
        },
      };
    }

    test('empty repo list short-circuits and stamps last sync', () async {
      final github = githubWith(
        MockClient((_) async => fail('should not fetch without repos')),
      );

      final updates = await SyncService.checkUpdates(
        storage: storage,
        github: github,
      );

      expect(updates, isEmpty);
      expect(await storage.getLastSyncAt(), isNotNull);
    });

    test('skips while the sync lock is held', () async {
      await storage.acquireSyncLock();
      final github = githubWith(
        MockClient((_) async => fail('should not fetch while locked')),
      );

      final updates = await SyncService.checkUpdates(
        storage: storage,
        github: github,
      );

      expect(updates, isEmpty);
    });

    test('initializes lastSha for a new repo without reporting updates',
        () async {
      await storage.saveRepos([
        const WatchedRepo(
          owner: 'flutter',
          repo: 'flutter',
          branch: 'main',
          syncMode: syncModeMinimal,
        ),
      ]);

      final github = githubWith(
        MockClient(
          (_) async => restCommits([
            commitJson('aaa', 'First', '2026-01-01T10:00:00Z'),
          ]),
        ),
      );

      final updates = await SyncService.checkUpdates(
        storage: storage,
        github: github,
      );

      expect(updates, isEmpty);
      final repos = await storage.getRepos();
      expect(repos.single.lastSha, 'aaa');
      expect(repos.single.lastCommitAt, isNotNull);
      expect((await storage.getCachedCommits(repos.single)).length, 1);
    });

    test('counts commits newer than lastSha and logs history', () async {
      await storage.saveRepos([
        const WatchedRepo(
          owner: 'flutter',
          repo: 'flutter',
          branch: 'main',
          syncMode: syncModeMinimal,
          lastSha: 'old',
        ),
      ]);

      final github = githubWith(
        MockClient(
          (_) async => restCommits([
            commitJson('new2', 'Second', '2026-01-03T10:00:00Z'),
            commitJson('new1', 'First', '2026-01-02T10:00:00Z'),
            commitJson('old', 'Old', '2026-01-01T10:00:00Z'),
          ]),
        ),
      );

      final updates = await SyncService.checkUpdates(
        storage: storage,
        github: github,
      );

      expect(updates['flutter/flutter (main)'], 2);
      final repos = await storage.getRepos();
      expect(repos.single.lastSha, 'new2');
      expect((await storage.getSyncHistory()).single.totalCommits, 2);
    });

    test('does not write repos when nothing changed', () async {
      const repo = WatchedRepo(
        owner: 'flutter',
        repo: 'flutter',
        branch: 'main',
        syncMode: syncModeMinimal,
        lastSha: 'same',
      );
      await storage.saveRepos([repo]);
      await storage.saveCachedCommits(repo, []);

      final github = githubWith(
        MockClient(
          (_) async => restCommits([
            commitJson('same', 'Unchanged', '2026-01-01T10:00:00Z'),
          ]),
        ),
      );

      final updates = await SyncService.checkUpdates(
        storage: storage,
        github: github,
      );

      expect(updates, isEmpty);
      expect((await storage.getRepos()).single.lastSha, 'same');
      expect(await storage.getSyncHistory(), isEmpty);
    });

    test('uses one batched GraphQL request when credentials exist', () async {
      await storage.saveCredentials(
        const GitHubCredentials(username: 'user', token: 'token'),
      );
      await storage.saveRepos([
        const WatchedRepo(
          owner: 'flutter',
          repo: 'flutter',
          branch: 'main',
          syncMode: syncModeMinimal,
          lastSha: 'old',
        ),
      ]);

      var graphqlCalls = 0;
      final github = githubWith(
        MockClient((request) async {
          if (request.url.path == '/graphql') {
            graphqlCalls++;
            return http.Response(
              jsonEncode({
                'data': {
                  'r0': {
                    'ref': {
                      'target': {
                        'history': {
                          'nodes': [
                            {
                              'oid': 'new',
                              'message': 'New commit',
                              'committedDate': '2026-01-02T10:00:00Z',
                              'author': {
                                'name': 'Budi',
                                'user': {'login': 'budi'},
                              },
                            },
                            {
                              'oid': 'old',
                              'message': 'Old',
                              'committedDate': '2026-01-01T10:00:00Z',
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
          }
          fail('REST fallback should not be used with credentials');
        }),
      );

      final updates = await SyncService.checkUpdates(
        storage: storage,
        github: github,
      );

      expect(graphqlCalls, 1);
      expect(updates['flutter/flutter (main)'], 1);
      final repos = await storage.getRepos();
      expect(repos.single.lastSha, 'new');
    });
  });
}
