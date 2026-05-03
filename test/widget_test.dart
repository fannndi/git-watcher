import 'package:flutter_test/flutter_test.dart';
import 'package:github_watcher/app.dart';

void main() {
  testWidgets('GitHub Watcher home renders', (WidgetTester tester) async {
    await tester.pumpWidget(const GitHubWatcherApp());

    expect(find.text('GitHub Watcher'), findsOneWidget);
    expect(find.text('Belum ada repo dipantau'), findsOneWidget);
  });
}
