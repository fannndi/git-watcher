import 'package:flutter/material.dart';

import '../screens/update_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  static Future<void> init({bool isBackground = false}) async {}

  static Future<void> showUpdateNotification(Map<String, int> updates) async {
    openUpdateScreen();
  }

  static Future<bool> launchedFromUpdateNotification() async => false;

  static Future<bool> isPermissionGranted() async => true;

  static Future<bool?> requestPermission() async => true;

  static Future<void> testNotification() async {}

  static void openUpdateScreen() {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const UpdateScreen()),
    );
  }
}
