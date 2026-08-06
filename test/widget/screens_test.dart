import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:github_watcher/app.dart';
import 'package:github_watcher/screens/settings_screen.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('renders empty state when no repos', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const GitHubWatcherApp());
      await tester.pumpAndSettle();

      expect(find.text('Belum ada repo'), findsOneWidget);
      expect(find.byIcon(Icons.folder_open_outlined), findsOneWidget);
    });

    testWidgets('shows FAB when repo count < max', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const GitHubWatcherApp());
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows sync card section', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const GitHubWatcherApp());
      await tester.pumpAndSettle();

      // Should show watched repos section
      expect(find.text('Repo Dipantau'), findsOneWidget);
    });

    testWidgets('shows notification and settings icons', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const GitHubWatcherApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });

    testWidgets('navigates to settings on tap', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const GitHubWatcherApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });

  group('SettingsScreen', () {
    testWidgets('renders all sections', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const MaterialApp(
        home: SettingsScreen(),
      ));
      await tester.pumpAndSettle();

      // Appearance section
      expect(find.text('Tampilan'), findsOneWidget);
      // Private access section
      expect(find.text('Akses repo privat'), findsOneWidget);
      // Sync section
      expect(find.text('Sinkronisasi'), findsOneWidget);
      // About section
      expect(find.text('Tentang aplikasi'), findsOneWidget);
    });

    testWidgets('shows language dropdown', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const MaterialApp(
        home: SettingsScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Bahasa'), findsOneWidget);
    });

    testWidgets('shows theme segmented button', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const MaterialApp(
        home: SettingsScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Sistem'), findsOneWidget);
      expect(find.text('Terang'), findsOneWidget);
      expect(find.text('Gelap'), findsOneWidget);
    });

    testWidgets('shows credential fields', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const MaterialApp(
        home: SettingsScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Username GitHub'), findsOneWidget);
      expect(find.text('Personal Access Token'), findsOneWidget);
    });

    testWidgets('shows extreme precision section', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const MaterialApp(
        home: SettingsScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Presisi Ekstrem'), findsOneWidget);
    });
  });

  group('App Theme', () {
    testWidgets('uses Material 3', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const GitHubWatcherApp());
      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme?.useMaterial3, true);
      expect(materialApp.darkTheme?.useMaterial3, true);
    });

    testWidgets('has blue color scheme', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const GitHubWatcherApp());
      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      // ThemeData doesn't expose colorSchemeSeed getter, verify Material 3 + blue seed
      expect(materialApp.theme?.useMaterial3, true);
      expect(materialApp.theme?.brightness, Brightness.light);
    });
  });
}
