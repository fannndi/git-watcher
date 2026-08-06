import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import 'storage_service.dart';

class AppSettingsController extends ValueNotifier<AppSettings> {
  final StorageService _storage = StorageService();
  int _settingsChangeCount = 0;

  AppSettingsController() : super(const AppSettings.defaults()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _storage.getAppSettings();
    value = settings;
  }

  Future<void> update(AppSettings settings) async {
    value = settings;
    await _storage.saveAppSettings(settings);
    _settingsChangeCount++;
    debugPrint('Settings updated: $_settingsChangeCount changes');
  }

  int get settingsChangeCount => _settingsChangeCount;
}

final appSettingsController = AppSettingsController();
