import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/notification_service.dart';

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
    final shouldOpen = await NotificationService.launchedFromUpdateNotification();
    if (!mounted || !shouldOpen) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.openUpdateScreen();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GitHub Watcher',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}
