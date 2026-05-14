import '../utils/constants.dart';

class AppSettings {
  final int syncIntervalMinutes;
  final String languageCode;
  final String themeMode;

  const AppSettings({
    required this.syncIntervalMinutes,
    required this.languageCode,
    required this.themeMode,
  });

  const AppSettings.defaults()
      : syncIntervalMinutes = defaultSyncIntervalMinutes,
        languageCode = languageIndonesian,
        themeMode = themeModeSystem;

  AppSettings copyWith({
    int? syncIntervalMinutes,
    String? languageCode,
    String? themeMode,
  }) {
    return AppSettings(
      syncIntervalMinutes: syncIntervalMinutes ?? this.syncIntervalMinutes,
      languageCode: languageCode ?? this.languageCode,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  Map<String, dynamic> toJson() => {
        'sync_interval_minutes': syncIntervalMinutes,
        'language_code': languageCode,
        'theme_mode': themeMode,
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
    );
  }

  static String _parseThemeMode(String? value) {
    if (value == themeModeLight || value == themeModeDark) {
      return value!;
    }
    return themeModeSystem;
  }
}
