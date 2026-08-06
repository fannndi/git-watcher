import 'package:flutter_test/flutter_test.dart';
import 'package:github_watcher/workers/alarm_worker.dart';

void main() {
  group('AlarmWorker', () {
    test('alarm interval is 1 hour', () {
      expect(alarmInterval, const Duration(hours: 1));
    });

    test('alarm callback is top-level function', () {
      expect(alarmCallback, isA<Function>());
    });

    test('registerExactAlarm is top-level function', () {
      expect(registerExactAlarm, isA<Function>());
    });

    test('cancelExactAlarm is top-level function', () {
      expect(cancelExactAlarm, isA<Function>());
    });
  });
}
