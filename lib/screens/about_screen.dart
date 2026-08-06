import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/constants.dart';
import '../services/app_settings_controller.dart';
import '../utils/strings.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = stringsFor(appSettingsController.value.languageCode);

    return Scaffold(
      appBar: AppBar(title: Text(strings.aboutApp)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App Icon
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.commit,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              appName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Center(
            child: Text(
              'v$appVersionName ($appBuildNumber)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 32),

          // Description
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                appDescription,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Links
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('GitHub'),
                  subtitle: Text(developerUrl),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => launchUrl(Uri.parse(developerUrl)),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(strings.developer),
                  subtitle: Text(developerName),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.update),
                  title: Text(strings.version),
                  subtitle: Text('$appVersionName - $appReleaseChannel'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Credits
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.credits,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Built with Flutter',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Material Design 3',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
