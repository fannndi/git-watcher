import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../screens/update_screen.dart';
import '../utils/constants.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('ic_stat_github');
    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (_) => openUpdateScreen(),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    const channel = AndroidNotificationChannel(
      notificationChannelId,
      'GitHub Updates',
      description: 'Notifications for watched GitHub repository updates.',
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> showUpdateNotification() async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        notificationChannelId,
        'GitHub Updates',
        channelDescription: 'Notifications for watched GitHub repository updates.',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _plugin.show(
      1,
      'Update GitHub tersedia',
      'Klik untuk melihat detail',
      details,
      payload: 'updates',
    );
  }

  static Future<bool> launchedFromUpdateNotification() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    return (details?.didNotificationLaunchApp ?? false) &&
        details?.notificationResponse?.payload == 'updates';
  }

  static void openUpdateScreen() {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const UpdateScreen()),
    );
  }
}
