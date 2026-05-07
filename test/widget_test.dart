import 'package:flutter_test/flutter_test.dart';
import 'package:github_watcher/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('GitHub Watcher home renders', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const GitHubWatcherApp());
    await tester.pumpAndSettle();

    expect(find.text('GitHub Watcher'), findsOneWidget);
    expect(find.text('Belum ada repo dipantau'), findsOneWidget);
  });
}
