import '../utils/constants.dart';

class AppSettings {
  final int syncIntervalMinutes;
  final String languageCode;
  final String themeMode;
  final bool notificationsEnabled;

  const AppSettings({
    required this.syncIntervalMinutes,
    required this.languageCode,
    required this.themeMode,
    this.notificationsEnabled = true,
  });

  const AppSettings.defaults()
      : syncIntervalMinutes = defaultSyncIntervalMinutes,
        languageCode = languageIndonesian,
        themeMode = themeModeSystem,
        notificationsEnabled = true;

  AppSettings copyWith({
    int? syncIntervalMinutes,
    String? languageCode,
    String? themeMode,
    bool? notificationsEnabled,
  }) {
    return AppSettings(
      syncIntervalMinutes: syncIntervalMinutes ?? this.syncIntervalMinutes,
      languageCode: languageCode ?? this.languageCode,
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'sync_interval_minutes': syncIntervalMinutes,
        'language_code': languageCode,
        'theme_mode': themeMode,
        'notifications_enabled': notificationsEnabled,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final interval = (json['sync_interval_minutes'] as num?)?.toInt() ??
        defaultSyncIntervalMinutes;
    return AppSettings(
      syncIntervalMinutes: interval,
      languageCode: json['language_code'] == languageEnglish
          ? languageEnglish
          : languageIndonesian,
      themeMode: _parseThemeMode(json['theme_mode'] as String?),
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
    );
  }

  static String _parseThemeMode(String? value) {
    if (value == themeModeLight || value == themeModeDark) {
      return value!;
    }
    return themeModeSystem;
  }
}
