import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_watcher/app.dart';
import 'package:github_watcher/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'has_seen_tour': true});
  });

  group('HomeScreen', () {
    testWidgets('renders empty state when no repos', (tester) async {
      await tester.pumpWidget(const GitHubWatcherApp());
      await tester.pumpAndSettle();

      expect(find.text('Belum ada repo'), findsOneWidget);
      expect(find.byIcon(Icons.folder_open_outlined), findsOneWidget);
    });

    testWidgets('shows FAB and app bar actions', (tester) async {
      await tester.pumpWidget(const GitHubWatcherApp());
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.sync), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });

    testWidgets('navigates to settings', (tester) async {
      await tester.pumpWidget(const GitHubWatcherApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('toggles search field', (tester) async {
      await tester.pumpWidget(const GitHubWatcherApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      expect(find.text('Cari repo...'), findsOneWidget);
    });
  });

  group('SettingsScreen', () {
    Future<void> pumpSettings(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();
    }

    testWidgets('renders all sections', (tester) async {
      await pumpSettings(tester);

      expect(find.text('Tampilan'), findsOneWidget);
      expect(find.text('Akses repo privat'), findsOneWidget);
      expect(find.text('Sinkronisasi'), findsOneWidget);
      expect(find.text('Tentang aplikasi'), findsOneWidget);
    });

    testWidgets('shows language, theme and credential controls', (tester) async {
      await pumpSettings(tester);

      expect(find.text('Bahasa'), findsOneWidget);
      expect(find.text('Sistem'), findsOneWidget);
      expect(find.text('Terang'), findsOneWidget);
      expect(find.text('Gelap'), findsOneWidget);
      expect(find.text('Username GitHub'), findsOneWidget);
      expect(find.text('Personal Access Token'), findsOneWidget);
      expect(find.text('Presisi Ekstrem'), findsOneWidget);
    });
  });

  group('App theme', () {
    testWidgets('uses Material 3 with light and dark themes', (tester) async {
      await tester.pumpWidget(const GitHubWatcherApp());
      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme?.useMaterial3, true);
      expect(materialApp.darkTheme?.useMaterial3, true);
      expect(materialApp.theme?.brightness, Brightness.light);
      expect(materialApp.darkTheme?.brightness, Brightness.dark);
    });
  });
}
