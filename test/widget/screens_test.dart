import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:git_watcher/app.dart';
import 'package:git_watcher/models/sync_log.dart';
import 'package:git_watcher/models/watched_repo.dart';
import 'package:git_watcher/screens/about_settings_screen.dart';
import 'package:git_watcher/screens/appearance_settings_screen.dart';
import 'package:git_watcher/screens/private_access_screen.dart';
import 'package:git_watcher/screens/settings_screen.dart';
import 'package:git_watcher/screens/sync_settings_screen.dart';
import 'package:git_watcher/screens/update_screen.dart';
import 'package:git_watcher/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'has_seen_tour': true,
      'setup_completed': true,
    });
    setupCompletedNotifier.value = true;
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    Size size = const Size(420, 900),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const GitHubWatcherApp());
    await tester.pumpAndSettle();
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    Size size = const Size(420, 1600),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(home: screen));
    await tester.pumpAndSettle();
  }

  group('First launch', () {
    testWidgets('shows the setup wizard when not completed', (tester) async {
      SharedPreferences.setMockInitialValues({});
      setupCompletedNotifier.value = false;
      addTearDown(() => setupCompletedNotifier.value = true);

      await pumpApp(tester);

      expect(find.text('Selamat datang di Git Watcher'), findsOneWidget);
      expect(find.text('Lanjut'), findsOneWidget);
    });
  });

  group('HomeScreen', () {
    testWidgets('renders empty state when no repos', (tester) async {
      await pumpApp(tester);

      expect(find.text('Belum ada repo'), findsOneWidget);
      expect(find.byIcon(Icons.folder_open_outlined), findsOneWidget);
    });

    testWidgets('shows FAB and app bar actions', (tester) async {
      await pumpApp(tester);

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.sync), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });

    testWidgets('navigates to settings', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('toggles search field', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      expect(find.text('Cari repo...'), findsOneWidget);
    });

    testWidgets('delete offers undo and restores the repo', (tester) async {
      final repo = WatchedRepo(
        owner: 'flutter',
        repo: 'flutter',
        branch: 'master',
        syncMode: syncModeMinimal,
        lastSha: 'abc123',
        lastCommitAt: DateTime.now(),
      );
      SharedPreferences.setMockInitialValues({
        'has_seen_tour': true,
        'setup_completed': true,
        watchedReposKey: jsonEncode([repo.toJson()]),
      });

      await pumpApp(tester);

      expect(
          find.text('flutter / flutter', findRichText: true), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();

      expect(find.text('Urungkan'), findsOneWidget);

      await tester.tap(find.text('Urungkan'));
      await tester.pumpAndSettle();

      expect(
          find.text('flutter / flutter', findRichText: true), findsOneWidget);
    });

    testWidgets('uses two-pane layout on wide screens', (tester) async {
      await pumpApp(tester, size: const Size(1200, 800));

      expect(find.text('Pilih repository'), findsOneWidget);
      expect(find.text('Pilih repo di kiri untuk melihat commit-nya.'),
          findsOneWidget);
    });
  });

  group('Settings hub', () {
    testWidgets('shows all sections and navigates', (tester) async {
      await pumpScreen(tester, const SettingsScreen());

      expect(find.text('Tampilan'), findsOneWidget);
      expect(find.text('Sinkronisasi'), findsOneWidget);
      expect(find.text('Akses repo privat'), findsOneWidget);
      expect(find.text('Tentang aplikasi'), findsOneWidget);

      await tester.tap(find.text('Sinkronisasi'));
      await tester.pumpAndSettle();

      expect(find.byType(SyncSettingsScreen), findsOneWidget);
    });
  });

  group('AppearanceSettingsScreen', () {
    testWidgets('shows language, theme and dynamic color', (tester) async {
      await pumpScreen(tester, const AppearanceSettingsScreen());

      expect(find.text('Bahasa'), findsOneWidget);
      expect(find.text('Sistem'), findsOneWidget);
      expect(find.text('Terang'), findsOneWidget);
      expect(find.text('Gelap'), findsOneWidget);
      expect(find.text('Warna dinamis (Material You)'), findsOneWidget);
    });
  });

  group('SyncSettingsScreen', () {
    testWidgets('shows sync and notification controls', (tester) async {
      await pumpScreen(tester, const SyncSettingsScreen(),
          size: const Size(420, 2000));

      expect(find.text('Interval sync background'), findsOneWidget);
      expect(find.text('Kirim notifikasi uji'), findsOneWidget);
      expect(find.text('Presisi Ekstrem'), findsOneWidget);
      expect(find.text('Sync hanya via Wi-Fi'), findsOneWidget);
      expect(find.text('Jam bangun'), findsOneWidget);
      expect(find.text('Jam tidur'), findsOneWidget);
      expect(find.text('Suara jika belum dibaca'), findsOneWidget);
      expect(find.text('Pengaturan notifikasi Android'), findsOneWidget);
    });
  });

  group('PrivateAccessScreen', () {
    testWidgets('shows credential fields', (tester) async {
      await pumpScreen(tester, const PrivateAccessScreen());

      expect(find.text('Username GitHub'), findsOneWidget);
      expect(find.text('Personal Access Token'), findsOneWidget);
    });
  });

  group('AboutSettingsScreen', () {
    testWidgets('shows about entries', (tester) async {
      await pumpScreen(tester, const AboutSettingsScreen());

      expect(find.text('Kode sumber'), findsOneWidget);
      expect(find.text('alisa'), findsOneWidget);
    });
  });

  group('UpdateScreen', () {
    testWidgets('clears sync history after confirmation', (tester) async {
      final log = SyncLog(
        syncedAt: DateTime.now(),
        updates: const {'flutter/flutter (master)': 2},
      );
      SharedPreferences.setMockInitialValues({
        'has_seen_tour': true,
        'setup_completed': true,
        syncHistoryKey: jsonEncode([log.toJson()]),
      });

      await pumpScreen(tester, const UpdateScreen());

      expect(find.text('Riwayat Sinkron'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_sweep_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();

      expect(find.text('Belum ada hasil sinkron'), findsOneWidget);
    });
  });

  group('App theme', () {
    testWidgets('uses Material 3 with light and dark themes', (tester) async {
      await pumpApp(tester);

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme?.useMaterial3, true);
      expect(materialApp.darkTheme?.useMaterial3, true);
      expect(materialApp.theme?.brightness, Brightness.light);
      expect(materialApp.darkTheme?.brightness, Brightness.dark);
    });

    testWidgets('applies M3 component themes and motion', (tester) async {
      await pumpApp(tester);

      final theme = tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!;
      final cardShape = theme.cardTheme.shape! as RoundedRectangleBorder;

      expect((cardShape.borderRadius as BorderRadius).topLeft.x, 16);
      expect(theme.snackBarTheme.behavior, SnackBarBehavior.floating);
      expect(
        theme.pageTransitionsTheme.builders[TargetPlatform.android],
        isA<FadeForwardsPageTransitionsBuilder>(),
      );
      expect(theme.inputDecorationTheme.filled, true);
    });
  });
}
