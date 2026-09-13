import 'package:flutter_test/flutter_test.dart';
import 'package:git_watcher/utils/strings.dart';

void main() {
  group('AppStrings.timeAgo', () {
    test('Indonesian', () {
      final strings = stringsFor('id');

      expect(strings.timeAgo(DateTime.now()), 'baru saja');
      expect(
        strings.timeAgo(DateTime.now().subtract(const Duration(minutes: 5))),
        '5 mnt lalu',
      );
      expect(
        strings.timeAgo(DateTime.now().subtract(const Duration(hours: 3))),
        '3 jam lalu',
      );
      expect(
        strings.timeAgo(DateTime.now().subtract(const Duration(days: 2))),
        '2 hari lalu',
      );
      expect(
        strings.timeAgo(DateTime.now().subtract(const Duration(days: 40))),
        '1 bln lalu',
      );
      expect(
        strings.timeAgo(DateTime.now().subtract(const Duration(days: 400))),
        '1 thn lalu',
      );
    });

    test('English', () {
      final strings = stringsFor('en');

      expect(strings.timeAgo(DateTime.now()), 'just now');
      expect(
        strings.timeAgo(DateTime.now().subtract(const Duration(minutes: 5))),
        '5m ago',
      );
      expect(
        strings.timeAgo(DateTime.now().subtract(const Duration(hours: 3))),
        '3h ago',
      );
      expect(
        strings.timeAgo(DateTime.now().subtract(const Duration(days: 2))),
        '2d ago',
      );
      expect(
        strings.timeAgo(DateTime.now().subtract(const Duration(days: 40))),
        '1mo ago',
      );
      expect(
        strings.timeAgo(DateTime.now().subtract(const Duration(days: 400))),
        '1y ago',
      );
    });
  });
}
