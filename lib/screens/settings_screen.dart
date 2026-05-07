import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../services/app_settings_controller.dart';
import '../utils/constants.dart';
import '../utils/strings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppSettings>(
      valueListenable: appSettingsController,
      builder: (context, settings, _) {
        final strings = stringsFor(settings.languageCode);

        return Scaffold(
          appBar: AppBar(title: Text(strings.settings)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                value: settings.isDemoMode,
                title: Text(strings.demoMode),
                subtitle: Text(strings.demoModeSubtitle),
                secondary: const Icon(Icons.bug_report_outlined),
                onChanged: (value) {
                  final interval = value ? 3 : defaultSyncIntervalMinutes;
                  _update(settings.copyWith(
                    isDemoMode: value,
                    syncIntervalMinutes: interval,
                  ));
                },
              ),
              const Divider(height: 24),
              DropdownButtonFormField<int>(
                initialValue: settings.syncIntervalMinutes,
                decoration: InputDecoration(
                  labelText: strings.syncInterval,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 1, child: Text(strings.minutes(1))),
                  DropdownMenuItem(value: 3, child: Text(strings.minutes(3))),
                  DropdownMenuItem(value: 5, child: Text(strings.minutes(5))),
                  DropdownMenuItem(value: 10, child: Text(strings.minutes(10))),
                  DropdownMenuItem(value: 60, child: Text(strings.oneHour)),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _update(settings.copyWith(syncIntervalMinutes: value));
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: settings.languageCode,
                decoration: InputDecoration(
                  labelText: strings.language,
                  border: const OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                      value: languageIndonesian, child: Text('Indonesia')),
                  DropdownMenuItem(
                      value: languageEnglish, child: Text('English')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _update(settings.copyWith(languageCode: value));
                  }
                },
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: themeModeSystem,
                    icon: const Icon(Icons.brightness_auto_outlined),
                    label: Text(strings.systemTheme),
                  ),
                  ButtonSegment(
                    value: themeModeLight,
                    icon: const Icon(Icons.light_mode_outlined),
                    label: Text(strings.lightTheme),
                  ),
                  ButtonSegment(
                    value: themeModeDark,
                    icon: const Icon(Icons.dark_mode_outlined),
                    label: Text(strings.darkTheme),
                  ),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (selected) {
                  _update(settings.copyWith(themeMode: selected.first));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _update(AppSettings settings) {
    return appSettingsController.update(settings);
  }
}
