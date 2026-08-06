import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import 'storage_service.dart';

class AppSettingsController extends ValueNotifier<AppSettings> {
  final StorageService _storage = StorageService();

  AppSettingsController() : super(const AppSettings.defaults()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    value = await _storage.getAppSettings();
  }

  Future<void> update(AppSettings settings) async {
    value = settings;
    await _storage.saveAppSettings(settings);
  }
}

final appSettingsController = AppSettingsController();
