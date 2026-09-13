import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/commit.dart';
import '../screens/detail_screen.dart';
import '../screens/update_screen.dart';
import '../utils/constants.dart';
import '../utils/strings.dart';
import 'storage_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

const String updatePayload = 'updates';
const String repoPayloadPrefix = 'repo:';
const int _notificationCommitLimit = 3;

String buildUpdateNotificationBody(
  Map<String, int> updates,
  Map<String, List<Commit>> newCommits,
  AppStrings strings,
) {
  final lines = <String>[];

  updates.forEach((repo, count) {
    lines.add(strings.notificationLine(repo, count));

    final commits = newCommits[repo] ?? const <Commit>[];
    for (final commit in commits.take(_notificationCommitLimit)) {
      final title = commit.title.isEmpty ? commit.message : commit.title;
      if (title.isEmpty) continue;
      lines.add(strings.notificationCommitLine(title, commit.author));
    }

    if (count > _notificationCommitLimit) {
      lines.add(strings.notificationMore(count - _notificationCommitLimit));
    }
  });

  return lines.join('\n');
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init({bool isBackground = false}) async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse:
          isBackground ? null : (response) => handlePayload(response.payload),
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

  static Future<bool> hasActiveUpdateNotification() async {
    try {
      final active = await _plugin.getActiveNotifications();
      return active
          .any((notification) => notification.id == updateNotificationId);
    } catch (_) {
      return false;
    }
  }

  static Future<void> showUpdateNotification(
    Map<String, int> updates,
    Map<String, List<Commit>> newCommits,
    AppStrings strings, {
    bool morningDigest = false,
  }) async {
    final title = morningDigest
        ? strings.morningDigestTitle(updates.length)
        : updates.length == 1
            ? strings.notificationTitle(updates.keys.first)
            : strings.notificationTitleMultiple(updates.length);
    final body = buildUpdateNotificationBody(updates, newCommits, strings);
    final payload = updates.length == 1
        ? '$repoPayloadPrefix${updates.keys.first}'
        : updatePayload;

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
      payload: payload,
    );
  }

  static Future<String?> initialPayload() async {
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      final launched = details?.didNotificationLaunchApp ?? false;
      return launched ? details?.notificationResponse?.payload : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> handlePayload(String? payload) async {
    if (payload == null || payload.isEmpty) {
      return;
    }

    await StorageService().setSyncBackoffLevel(0);

    if (payload == updatePayload) {
      openUpdateScreen();
      return;
    }

    if (payload.startsWith(repoPayloadPrefix)) {
      final key = payload.substring(repoPayloadPrefix.length);
      final repos = await StorageService().getRepos();

      for (final repo in repos) {
        if ('${repo.fullName} (${repo.branch})' == key) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => DetailScreen(repo: repo)),
          );
          return;
        }
      }

      openUpdateScreen();
    }
  }

  static void openUpdateScreen() {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const UpdateScreen()),
    );
  }
}
