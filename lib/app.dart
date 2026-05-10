import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/app_settings_controller.dart';
import 'services/notification_service.dart';
import 'utils/constants.dart';

class GitHubWatcherApp extends StatefulWidget {
  const GitHubWatcherApp({super.key});

  @override
  State<GitHubWatcherApp> createState() => _GitHubWatcherAppState();
}

class _GitHubWatcherAppState extends State<GitHubWatcherApp> {
  @override
  void initState() {
    super.initState();
    _openInitialNotification();
  }

  Future<void> _openInitialNotification() async {
    final shouldOpen =
        await NotificationService.launchedFromUpdateNotification();
    if (!mounted || !shouldOpen) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.openUpdateScreen();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: appSettingsController,
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'GitHub Watcher',
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          themeMode: _themeMode(settings.themeMode),
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.blue,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF7F8FC),
            cardTheme: const CardThemeData(
              elevation: 0,
              margin: EdgeInsets.zero,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.blue,
            brightness: Brightness.dark,
            cardTheme: const CardThemeData(
              elevation: 0,
              margin: EdgeInsets.zero,
            ),
          ),
          home: const HomeScreen(),
        );
      },
    );
  }

  ThemeMode _themeMode(String value) {
    if (value == themeModeLight) {
      return ThemeMode.light;
    }
    if (value == themeModeDark) {
      return ThemeMode.dark;
    }
    return ThemeMode.system;
  }
}
