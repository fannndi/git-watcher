import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_settings.dart';
import '../services/app_info.dart';
import '../services/app_settings_controller.dart';
import '../utils/constants.dart';
import '../utils/strings.dart';
import '../widgets/settings_section.dart';

class AboutSettingsScreen extends StatelessWidget {
  const AboutSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppSettings>(
      valueListenable: appSettingsController,
      builder: (context, settings, _) {
        final strings = stringsFor(settings.languageCode);

        return Scaffold(
          appBar: AppBar(title: Text(strings.aboutApp)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SettingsSection(
                title: strings.aboutApp,
                icon: Icons.info_outline,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.code),
                    title: Text(strings.sourceCode),
                    subtitle: const Text(repositoryUrl),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => _openUrl(context, repositoryUrl),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.description_outlined),
                    title: Text(strings.appDescription),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${strings.version} ${AppInfo.version} '
                        '(${AppInfo.build}) - $appReleaseChannel',
                      ),
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.person_outline),
                    title: Text(strings.developer),
                    subtitle: const Text(developerName),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => _openUrl(context, developerUrl),
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

Future<void> _openUrl(BuildContext context, String url) async {
  final strings = stringsFor(appSettingsController.value.languageCode);
  final opened = await launchUrl(
    Uri.parse(url),
    mode: LaunchMode.externalApplication,
  );
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.openLinkFailed)),
    );
  }
}
