import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import 'storage_service.dart';

class AppSettingsController extends ValueNotifier<AppSettings> {
  AppSettingsController() : super(const AppSettings.defaults());

  final StorageService _storage = StorageService();

  Future<void> load() async {
    value = await _storage.getAppSettings();
  }

  Future<void> update(AppSettings settings) async {
    value = settings;
    await _storage.saveAppSettings(settings);
  }
}

final appSettingsController = AppSettingsController();
