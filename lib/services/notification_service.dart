import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../screens/update_screen.dart';
import '../utils/constants.dart';
import '../utils/strings.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init({bool isBackground = false}) async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: isBackground
          ? null
          : (response) {
              if (response.payload == notificationChannelId) {
                openUpdateScreen();
              }
            },
    );

    const channel = AndroidNotificationChannel(
      notificationChannelId,
      notificationChannelName,
      description: 'Notifications for watched GitHub repository updates.',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
      showBadge: true,
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await android?.createNotificationChannel(channel);

    if (!isBackground) {
      await android?.requestNotificationsPermission();
    }
  }

  static Future<bool> ensurePermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) {
      return true;
    }

    if (await android.areNotificationsEnabled() ?? false) {
      return true;
    }

    return await android.requestNotificationsPermission() ?? false;
  }

  static Future<void> testNotification(AppStrings strings) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        notificationChannelId,
        notificationChannelName,
        channelDescription:
            'Notifications for watched GitHub repository updates.',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _plugin.show(
      testNotificationId,
      strings.testNotificationTitle,
      strings.testNotificationBody,
      details,
    );
  }

  static Future<void> showUpdateNotification(
    Map<String, int> updates,
    AppStrings strings,
  ) async {
    final title = updates.length == 1
        ? strings.notificationTitle(updates.keys.first)
        : strings.notificationTitleMultiple(updates.length);
    final body = updates.entries
        .map((entry) => strings.notificationLine(entry.key, entry.value))
        .join('\n');

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        notificationChannelId,
        notificationChannelName,
        channelDescription:
            'Notifications for watched GitHub repository updates.',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        styleInformation:
            updates.length > 1 ? BigTextStyleInformation(body) : null,
      ),
    );

    await _plugin.show(
      updateNotificationId,
      title,
      body,
      details,
      payload: notificationChannelId,
    );
  }

  static Future<bool> launchedFromUpdateNotification() async {
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      return (details?.didNotificationLaunchApp ?? false) &&
          details?.notificationResponse?.payload == notificationChannelId;
    } catch (_) {
      return false;
    }
  }

  static void openUpdateScreen() {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const UpdateScreen()),
    );
  }
}
