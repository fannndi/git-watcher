import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../screens/update_screen.dart';
import '../utils/constants.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init({bool isBackground = false}) async {
    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: androidSettings);

      await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: isBackground
            ? null
            : (NotificationResponse response) {
                if (response.payload == 'updates') {
                  openUpdateScreen();
                }
              },
      );

      // Create channel for Android 8.0+
      const channel = AndroidNotificationChannel(
        notificationChannelId,
        'GitHub Updates',
        description: 'Notifications for watched GitHub repository updates.',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
        showBadge: true,
      );

      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    } catch (e) {
      debugPrint('NotificationService init error: $e');
      // Non-fatal error
    }
  }

  static Future<bool> isPermissionGranted() async {
    final status = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.areNotificationsEnabled();
    return status ?? false;
  }

  static Future<bool?> requestPermission() async {
    return await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> testNotification() async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        notificationChannelId,
        'GitHub Updates',
        channelDescription: 'Test channel',
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'ticker',
        fullScreenIntent: true,
      ),
    );

    await _plugin.show(
      99,
      'Test Notification',
      'Jika Anda melihat ini, sistem notifikasi berfungsi!',
      details,
    );
  }

  static Future<void> showUpdateNotification(Map<String, int> updates) async {
    final title = updates.length == 1
        ? 'Update di ${updates.keys.first}'
        : '${updates.length} repo ada update baru';

    final body = updates.entries
        .map((e) => '${e.key}: +${e.value} commit')
        .join('\n');

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        notificationChannelId,
        'GitHub Updates',
        channelDescription:
            'Notifications for watched GitHub repository updates.',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        styleInformation: updates.length > 1
            ? BigTextStyleInformation(body)
            : null,
      ),
    );

    await _plugin.show(
      1,
      title,
      body,
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
