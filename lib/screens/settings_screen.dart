import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../services/app_settings_controller.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/strings.dart';
import 'about_settings_screen.dart';
import 'appearance_settings_screen.dart';
import 'private_access_screen.dart';
import 'sync_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storage = StorageService();
  bool _hasCredentials = false;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    final credentials = await _storage.getCredentials();
    if (!mounted) return;
    setState(() => _hasCredentials = credentials.isNotEmpty);
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
    await _loadCredentials();
  }

  String _languageName(AppSettings settings) {
    return settings.languageCode == languageEnglish ? 'English' : 'Indonesia';
  }

  String _themeName(AppSettings settings, AppStrings strings) {
    if (settings.themeMode == themeModeLight) {
      return strings.lightTheme;
    }
    if (settings.themeMode == themeModeDark) {
      return strings.darkTheme;
    }
    return strings.systemTheme;
  }

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
              _SettingsTile(
                icon: Icons.palette_outlined,
                title: strings.appearance,
                subtitle:
                    '${_languageName(settings)} • ${_themeName(settings, strings)}',
                onTap: () => _open(const AppearanceSettingsScreen()),
              ),
              const SizedBox(height: 8),
              _SettingsTile(
                icon: Icons.sync_outlined,
                title: strings.syncSettings,
                subtitle: '${strings.minutes(settings.syncIntervalMinutes)}'
                    ' • ${settings.notificationsEnabled ? strings.on : strings.off}',
                onTap: () => _open(const SyncSettingsScreen()),
              ),
              const SizedBox(height: 8),
              _SettingsTile(
                icon: Icons.lock_outline,
                title: strings.privateAccess,
                subtitle: _hasCredentials
                    ? strings.credentialsActive
                    : strings.credentialsEmpty,
                onTap: () => _open(const PrivateAccessScreen()),
              ),
              const SizedBox(height: 8),
              _SettingsTile(
                icon: Icons.info_outline,
                title: strings.aboutApp,
                subtitle: 'v$appVersionName ($appBuildNumber)',
                onTap: () => _open(const AboutSettingsScreen()),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: colorScheme.onSecondaryContainer),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
