import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import 'startup_service.dart';
import 'storage_service.dart';

class AppSettingsController extends ValueNotifier<AppSettings> {
  AppSettingsController() : super(const AppSettings.defaults());

  final StorageService _storage = StorageService();

  Future<void> load() async {
    value = await _storage.getAppSettings();
  }

  Future<void> update(AppSettings settings) async {
    final oldInterval = value.syncIntervalMinutes;
    value = settings;
    await _storage.saveAppSettings(settings);

    // Jika interval berubah, segera reset jadwal sync background
    if (oldInterval != settings.syncIntervalMinutes) {
      try {
        await StartupService.resetBackgroundSync(settings.syncIntervalMinutes);
      } catch (_) {}
    }
  }
}

final appSettingsController = AppSettingsController();
