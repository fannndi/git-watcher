import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../services/app_settings_controller.dart';
import '../utils/constants.dart';
import '../utils/strings.dart';
import '../widgets/settings_section.dart';

class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppSettings>(
      valueListenable: appSettingsController,
      builder: (context, settings, _) {
        final strings = stringsFor(settings.languageCode);

        return Scaffold(
          appBar: AppBar(title: Text(strings.appearance)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SettingsSection(
                title: strings.appearance,
                icon: Icons.palette_outlined,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: settings.languageCode,
                    decoration: InputDecoration(
                      labelText: strings.language,
                      prefixIcon: const Icon(Icons.translate_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: languageIndonesian,
                        child: Text('Indonesia'),
                      ),
                      DropdownMenuItem(
                        value: languageEnglish,
                        child: Text('English'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        appSettingsController.update(
                          settings.copyWith(languageCode: value),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 14),
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
                      appSettingsController.update(
                        settings.copyWith(themeMode: selected.first),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(strings.dynamicColor),
                    subtitle: Text(strings.dynamicColorDesc),
                    value: settings.dynamicColor,
                    onChanged: (value) {
                      appSettingsController.update(
                        settings.copyWith(dynamicColor: value),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
