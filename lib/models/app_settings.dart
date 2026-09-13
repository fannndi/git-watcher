import '../utils/constants.dart';

class AppSettings {
  const AppSettings({
    required this.syncIntervalMinutes,
    required this.languageCode,
    required this.themeMode,
    this.notificationsEnabled = true,
    this.preciseSync = false,
    this.wifiOnly = false,
    this.quietHoursEnabled = true,
    this.quietStartHour = 23,
    this.quietEndHour = 7,
  });

  const AppSettings.defaults()
      : syncIntervalMinutes = defaultSyncIntervalMinutes,
        languageCode = languageIndonesian,
        themeMode = themeModeSystem,
        notificationsEnabled = true,
        preciseSync = false,
        wifiOnly = false,
        quietHoursEnabled = true,
        quietStartHour = 23,
        quietEndHour = 7;

  final int syncIntervalMinutes;
  final String languageCode;
  final String themeMode;
  final bool notificationsEnabled;
  final bool preciseSync;
  final bool wifiOnly;
  final bool quietHoursEnabled;
  final int quietStartHour;
  final int quietEndHour;

  AppSettings copyWith({
    int? syncIntervalMinutes,
    String? languageCode,
    String? themeMode,
    bool? notificationsEnabled,
    bool? preciseSync,
    bool? wifiOnly,
    bool? quietHoursEnabled,
    int? quietStartHour,
    int? quietEndHour,
  }) {
    return AppSettings(
      syncIntervalMinutes: syncIntervalMinutes ?? this.syncIntervalMinutes,
      languageCode: languageCode ?? this.languageCode,
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      preciseSync: preciseSync ?? this.preciseSync,
      wifiOnly: wifiOnly ?? this.wifiOnly,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietStartHour: quietStartHour ?? this.quietStartHour,
      quietEndHour: quietEndHour ?? this.quietEndHour,
    );
  }

  Map<String, dynamic> toJson() => {
        'sync_interval_minutes': syncIntervalMinutes,
        'language_code': languageCode,
        'theme_mode': themeMode,
        'notifications_enabled': notificationsEnabled,
        'precise_sync': preciseSync,
        'wifi_only': wifiOnly,
        'quiet_hours_enabled': quietHoursEnabled,
        'quiet_start_hour': quietStartHour,
        'quiet_end_hour': quietEndHour,
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
      quietHoursEnabled: json['quiet_hours_enabled'] as bool? ?? true,
      quietStartHour: normalizeHour(
        (json['quiet_start_hour'] as num?)?.toInt(),
        23,
      ),
      quietEndHour: normalizeHour(
        (json['quiet_end_hour'] as num?)?.toInt(),
        7,
      ),
    );
  }

  static int normalizeInterval(int? value) {
    if (value != null && syncIntervalOptions.contains(value)) {
      return value;
    }
    return defaultSyncIntervalMinutes;
  }

  static int normalizeHour(int? value, int fallback) {
    if (value != null && value >= 0 && value <= 23) {
      return value;
    }
    return fallback;
  }

  bool isQuietHour(DateTime time) {
    if (!quietHoursEnabled) {
      return false;
    }
    if (quietStartHour == quietEndHour) {
      return false;
    }

    final hour = time.hour;
    if (quietStartHour < quietEndHour) {
      return hour >= quietStartHour && hour < quietEndHour;
    }
    return hour >= quietStartHour || hour < quietEndHour;
  }

  int effectiveSyncIntervalMinutes(int backoffLevel) {
    final multiplier = 1 << backoffLevel.clamp(0, maxSyncBackoffLevel);
    return syncIntervalMinutes * multiplier;
  }

  static String _parseThemeMode(String? value) {
    if (value == themeModeLight || value == themeModeDark) {
      return value!;
    }
    return themeModeSystem;
  }
}
