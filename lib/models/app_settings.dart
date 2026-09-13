import '../utils/constants.dart';

class AppSettings {
  const AppSettings({
    required this.syncIntervalMinutes,
    required this.languageCode,
    required this.themeMode,
    this.notificationsEnabled = true,
    this.preciseSync = false,
    this.wifiOnly = false,
    this.alertOnUnread = false,
    this.dynamicColor = true,
    this.hideNotificationContent = false,
    this.quietHoursEnabled = true,
    this.wakeMinutes = defaultWakeMinutes,
    this.sleepMinutes = defaultSleepMinutes,
  });

  const AppSettings.defaults()
      : syncIntervalMinutes = defaultSyncIntervalMinutes,
        languageCode = languageIndonesian,
        themeMode = themeModeSystem,
        notificationsEnabled = true,
        preciseSync = false,
        wifiOnly = false,
        alertOnUnread = false,
        dynamicColor = true,
        hideNotificationContent = false,
        quietHoursEnabled = true,
        wakeMinutes = defaultWakeMinutes,
        sleepMinutes = defaultSleepMinutes;

  final int syncIntervalMinutes;
  final String languageCode;
  final String themeMode;
  final bool notificationsEnabled;
  final bool preciseSync;
  final bool wifiOnly;
  final bool alertOnUnread;
  final bool dynamicColor;
  final bool hideNotificationContent;
  final bool quietHoursEnabled;
  final int wakeMinutes;
  final int sleepMinutes;

  AppSettings copyWith({
    int? syncIntervalMinutes,
    String? languageCode,
    String? themeMode,
    bool? notificationsEnabled,
    bool? preciseSync,
    bool? wifiOnly,
    bool? alertOnUnread,
    bool? dynamicColor,
    bool? hideNotificationContent,
    bool? quietHoursEnabled,
    int? wakeMinutes,
    int? sleepMinutes,
  }) {
    return AppSettings(
      syncIntervalMinutes: syncIntervalMinutes ?? this.syncIntervalMinutes,
      languageCode: languageCode ?? this.languageCode,
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      preciseSync: preciseSync ?? this.preciseSync,
      wifiOnly: wifiOnly ?? this.wifiOnly,
      alertOnUnread: alertOnUnread ?? this.alertOnUnread,
      dynamicColor: dynamicColor ?? this.dynamicColor,
      hideNotificationContent:
          hideNotificationContent ?? this.hideNotificationContent,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      wakeMinutes: wakeMinutes ?? this.wakeMinutes,
      sleepMinutes: sleepMinutes ?? this.sleepMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
        'sync_interval_minutes': syncIntervalMinutes,
        'language_code': languageCode,
        'theme_mode': themeMode,
        'notifications_enabled': notificationsEnabled,
        'precise_sync': preciseSync,
        'wifi_only': wifiOnly,
        'alert_on_unread': alertOnUnread,
        'dynamic_color': dynamicColor,
        'hide_notification_content': hideNotificationContent,
        'quiet_hours_enabled': quietHoursEnabled,
        'wake_minutes': wakeMinutes,
        'sleep_minutes': sleepMinutes,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      syncIntervalMinutes: normalizeInterval(
        (json['sync_interval_minutes'] as num?)?.toInt(),
      ),
      languageCode: json['language_code'] == languageEnglish
          ? languageEnglish
          : languageIndonesian,
      themeMode: _parseThemeMode(json['theme_mode'] as String?),
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      preciseSync: json['precise_sync'] as bool? ?? false,
      wifiOnly: json['wifi_only'] as bool? ?? false,
      alertOnUnread: json['alert_on_unread'] as bool? ?? false,
      dynamicColor: json['dynamic_color'] as bool? ?? true,
      hideNotificationContent:
          json['hide_notification_content'] as bool? ?? false,
      quietHoursEnabled: json['quiet_hours_enabled'] as bool? ?? true,
      wakeMinutes: normalizeTime(
        (json['wake_minutes'] as num?)?.toInt(),
        legacyHourOf(json['quiet_end_hour'], defaultWakeMinutes ~/ 60) * 60,
      ),
      sleepMinutes: normalizeTime(
        (json['sleep_minutes'] as num?)?.toInt(),
        legacyHourOf(json['quiet_start_hour'], defaultSleepMinutes ~/ 60) * 60,
      ),
    );
  }

  static int normalizeInterval(int? value) {
    if (value != null && syncIntervalOptions.contains(value)) {
      return value;
    }
    return defaultSyncIntervalMinutes;
  }

  static int normalizeTime(int? value, int fallback) {
    if (value != null && value >= 0 && value < 1440) {
      return value;
    }
    return fallback;
  }

  static int legacyHourOf(Object? value, int fallback) {
    if (value is num && value >= 0 && value <= 23) {
      return value.toInt();
    }
    return fallback;
  }

  bool isSleepTime(DateTime time) {
    if (!quietHoursEnabled || sleepMinutes == wakeMinutes) {
      return false;
    }

    final minutes = time.hour * 60 + time.minute;
    if (sleepMinutes < wakeMinutes) {
      return minutes >= sleepMinutes && minutes < wakeMinutes;
    }
    return minutes >= sleepMinutes || minutes < wakeMinutes;
  }

  bool isMorningWindow(DateTime time) {
    if (!quietHoursEnabled) {
      return false;
    }

    final minutes = time.hour * 60 + time.minute;
    final windowEnd = wakeMinutes + 180;
    return minutes >= wakeMinutes &&
        minutes < (windowEnd > 1440 ? 1440 : windowEnd);
  }

  static String _parseThemeMode(String? value) {
    if (value == themeModeLight || value == themeModeDark) {
      return value!;
    }
    return themeModeSystem;
  }
}
