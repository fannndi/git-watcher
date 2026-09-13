import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/app_settings_controller.dart';
import 'services/notification_service.dart';
import 'utils/constants.dart';

class GitHubWatcherApp extends StatelessWidget {
  const GitHubWatcherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: appSettingsController,
      builder: (context, settings, _) {
        return MaterialApp(
          title: appName,
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          themeMode: _themeMode(settings.themeMode),
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          home: const HomeScreen(),
        );
      },
    );
  }

  ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.blue,
      brightness: brightness,
      scaffoldBackgroundColor: dark ? null : const Color(0xFFF8FAFF),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: dark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
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
