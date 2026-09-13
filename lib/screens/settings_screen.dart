import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_settings.dart';
import '../models/github_credentials.dart';
import '../services/app_settings_controller.dart';
import '../services/notification_service.dart';
import '../services/startup_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/strings.dart';
import '../widgets/chips.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storage = StorageService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();

  bool _tokenObscured = true;
  bool _hasCredentials = false;
  bool _isSaving = false;
  bool _isTestingNotification = false;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _loadCredentials() async {
    final credentials = await _storage.getCredentials();
    if (!mounted) return;

    setState(() {
      _hasCredentials = credentials.isNotEmpty;
      if (credentials.isNotEmpty) {
        _usernameController.text = credentials.username;
        _tokenController.text = credentials.token;
      }
    });
  }

  Future<void> _saveCredentials(AppStrings strings) async {
    final username = _usernameController.text.trim();
    final token = _tokenController.text.trim();

    if (username.isEmpty || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.usernameTokenRequired)),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _storage.saveCredentials(
        GitHubCredentials(username: username, token: token),
      );
      if (!mounted) return;
      setState(() => _hasCredentials = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.credentialsSaved)),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _clearCredentials(AppStrings strings) async {
    await _storage.clearCredentials();
    if (!mounted) return;

    setState(() {
      _hasCredentials = false;
      _usernameController.clear();
      _tokenController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.credentialsCleared)),
    );
  }

  Future<void> _update(AppSettings settings) {
    return appSettingsController.update(settings);
  }

  Future<void> _changeInterval(AppSettings settings, int? value) async {
    if (value == null || value == settings.syncIntervalMinutes) {
      return;
    }

    await _update(settings.copyWith(syncIntervalMinutes: value));
    await StartupService.applySyncInterval();
  }

  Future<void> _sendTestNotification(AppStrings strings) async {
    setState(() => _isTestingNotification = true);
    try {
      final granted = await NotificationService.ensurePermission();
      if (!mounted) return;

      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.notificationsBlocked)),
        );
        return;
      }

      await NotificationService.testNotification(strings);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.notificationsBlocked)),
        );
      }
    } finally {
      if (mounted) setState(() => _isTestingNotification = false);
    }
  }

  Future<void> _showAboutApp(AppStrings strings) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.aboutApp),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.appDescription),
            const SizedBox(height: 16),
            _AboutRow(label: strings.version, value: appVersionName),
            _AboutRow(label: strings.channel, value: appReleaseChannel),
            _AboutLinkRow(
              label: strings.developer,
              value: developerName,
              url: developerUrl,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppSettings>(
      valueListenable: appSettingsController,
      builder: (context, settings, _) {
        final strings = stringsFor(settings.languageCode);
        final colorScheme = Theme.of(context).colorScheme;

        return Scaffold(
          appBar: AppBar(title: Text(strings.settings)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SettingsSection(
                title: strings.appearance,
                icon: Icons.palette_outlined,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: settings.languageCode,
                    decoration: InputDecoration(labelText: strings.language),
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
                        _update(settings.copyWith(languageCode: value));
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
                      _update(settings.copyWith(themeMode: selected.first));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SettingsSection(
                title: strings.privateAccess,
                icon: Icons.lock_outline,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          strings.privateMode,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      InfoChip(
                        label: _hasCredentials
                            ? strings.credentialsActive
                            : strings.credentialsEmpty,
                        accent: _hasCredentials,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.privateModeSubtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: strings.githubUsername,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _tokenController,
                    obscureText: _tokenObscured,
                    decoration: InputDecoration(
                      labelText: strings.githubToken,
                      helperText: strings.githubTokenHelper,
                      prefixIcon: const Icon(Icons.key_outlined),
                      suffixIcon: IconButton(
                        tooltip: _tokenObscured ? strings.show : strings.hide,
                        icon: Icon(
                          _tokenObscured
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _tokenObscured = !_tokenObscured),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isSaving
                              ? null
                              : () => _saveCredentials(strings),
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(strings.saveCredentials),
                        ),
                      ),
                      if (_hasCredentials) ...[
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () => _clearCredentials(strings),
                          icon: const Icon(Icons.delete_outline),
                          label: Text(strings.clearCredentials),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.error,
                            side: BorderSide(color: colorScheme.error),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SettingsSection(
                title: strings.syncSettings,
                icon: Icons.sync_outlined,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: settings.syncIntervalMinutes,
                    decoration: InputDecoration(
                      labelText: strings.syncInterval,
                      helperText: strings.syncIntervalHelper,
                      prefixIcon: const Icon(Icons.timer_outlined),
                    ),
                    items: [
                      for (final minutes in syncIntervalOptions)
                        DropdownMenuItem(
                          value: minutes,
                          child: Text(strings.minutes(minutes)),
                        ),
                    ],
                    onChanged: (value) => _changeInterval(settings, value),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: Text(strings.enableNotifications),
                    subtitle: Text(strings.enableNotificationsDesc),
                    value: settings.notificationsEnabled,
                    onChanged: (value) {
                      _update(settings.copyWith(notificationsEnabled: value));
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isTestingNotification
                          ? null
                          : () => _sendTestNotification(strings),
                      icon: _isTestingNotification
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.notifications_active_outlined),
                      label: Text(strings.testNotification),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: Text(strings.extremePrecision),
                    subtitle: Text(strings.extremePrecisionDesc),
                    value: settings.preciseSync,
                    onChanged: (value) async {
                      await _update(settings.copyWith(preciseSync: value));
                      await StartupService.applySyncInterval();
                    },
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: () =>
                          StartupService.requestBatteryOptimizationExemption(),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: Text(strings.allowBatteryExemption),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: Text(strings.wifiOnly),
                    subtitle: Text(strings.wifiOnlyDesc),
                    value: settings.wifiOnly,
                    onChanged: (value) {
                      _update(settings.copyWith(wifiOnly: value));
                    },
                  ),
                  SwitchListTile(
                    title: Text(strings.quietHours),
                    subtitle: Text(strings.quietHoursDesc),
                    value: settings.quietHoursEnabled,
                    onChanged: (value) {
                      _update(settings.copyWith(quietHoursEnabled: value));
                    },
                  ),
                  if (settings.quietHoursEnabled) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: settings.quietStartHour,
                            decoration: InputDecoration(
                              labelText: strings.quietStart,
                            ),
                            items: [
                              for (var hour = 0; hour < 24; hour++)
                                DropdownMenuItem(
                                  value: hour,
                                  child: Text(strings.hourLabel(hour)),
                                ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                _update(
                                  settings.copyWith(quietStartHour: value),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: settings.quietEndHour,
                            decoration: InputDecoration(
                              labelText: strings.quietEnd,
                            ),
                            items: [
                              for (var hour = 0; hour < 24; hour++)
                                DropdownMenuItem(
                                  value: hour,
                                  child: Text(strings.hourLabel(hour)),
                                ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                _update(settings.copyWith(quietEndHour: value));
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              _SettingsSection(
                title: strings.aboutApp,
                icon: Icons.info_outline,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.star_outline),
                    title: Text(strings.rateApp),
                    subtitle: Text(strings.rateAppDesc),
                    onTap: () => _openUrl(
                      context,
                      'https://play.google.com/store/apps/details?id=$appId',
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(strings.appDescription),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${strings.version} $appVersionName ($appBuildNumber) - $appReleaseChannel\n'
                        '${strings.developer}: $developerName',
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showAboutApp(strings),
                  ),
                ],
              ),
              const SizedBox(height: 24),
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

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _AboutLinkRow extends StatelessWidget {
  const _AboutLinkRow({
    required this.label,
    required this.value,
    required this.url,
  });

  final String label;
  final String value;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => _openUrl(context, url),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '$value ($url)',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
