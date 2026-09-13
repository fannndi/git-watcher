import 'package:flutter_test/flutter_test.dart';
import 'package:git_watcher/models/commit.dart';
import 'package:git_watcher/services/notification_service.dart';
import 'package:git_watcher/utils/strings.dart';

void main() {
  group('buildUpdateNotificationBody', () {
    test('lists newest commits with authors and caps at three', () {
      final commits = [
        Commit(
          sha: 'a',
          message: 'Fix login crash',
          date: DateTime.now(),
          author: 'budi',
        ),
        Commit(
          sha: 'b',
          message: 'Add dark mode',
          date: DateTime.now(),
          author: 'alice',
        ),
        Commit(
          sha: 'c',
          message: 'Bump dependencies',
          date: DateTime.now(),
        ),
        Commit(
          sha: 'd',
          message: 'Tidy up tests',
          date: DateTime.now(),
          author: 'budi',
        ),
      ];

      final body = buildUpdateNotificationBody(
        {'owner/repo (main)': 4},
        {'owner/repo (main)': commits},
        stringsFor('id'),
      );

      expect(body, contains('owner/repo (main): +4 commits'));
      expect(body, contains('• Fix login crash — budi'));
      expect(body, contains('• Add dark mode — alice'));
      expect(body, contains('• Bump dependencies'));
      expect(body, contains('+1 lainnya'));
      expect(body, isNot(contains('Tidy up tests')));
    });

    test('handles repositories without commit details', () {
      final body = buildUpdateNotificationBody(
        {'owner/repo (dev)': 1},
        const {},
        stringsFor('en'),
      );

      expect(body, 'owner/repo (dev): +1 commit');
    });
  });

  group('AppStrings notification helpers', () {
    test('english and indonesian variants', () {
      expect(
          stringsFor('en').notificationCommitLine('Fix bug', ''), '• Fix bug');
      expect(stringsFor('en').notificationMore(2), '+2 more');
      expect(stringsFor('id').notificationMore(2), '+2 lainnya');
    });
  });
}
