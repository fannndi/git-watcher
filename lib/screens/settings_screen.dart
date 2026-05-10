import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/github_credentials.dart';
import '../services/app_settings_controller.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/strings.dart';

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
        const SnackBar(content: Text('Username dan token tidak boleh kosong')),
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
              _SettingsSection(
                title: strings.syncAndDemo,
                icon: Icons.sync_outlined,
                children: [
                  SwitchListTile(
                    value: settings.isDemoMode,
                    contentPadding: EdgeInsets.zero,
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
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: settings.syncIntervalMinutes,
                    decoration: InputDecoration(
                      labelText: strings.syncInterval,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                          value: 1, child: Text(strings.minutes(1))),
                      DropdownMenuItem(
                          value: 3, child: Text(strings.minutes(3))),
                      DropdownMenuItem(
                          value: 5, child: Text(strings.minutes(5))),
                      DropdownMenuItem(
                        value: 10,
                        child: Text(strings.minutes(10)),
                      ),
                      DropdownMenuItem(value: 60, child: Text(strings.oneHour)),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        _update(settings.copyWith(syncIntervalMinutes: value));
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SettingsSection(
                title: strings.appearance,
                icon: Icons.palette_outlined,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: settings.languageCode,
                    decoration: InputDecoration(
                      labelText: strings.language,
                      border: const OutlineInputBorder(),
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
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                      _CredentialStatusPill(hasCredentials: _hasCredentials),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.privateModeSubtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: strings.githubUsername,
                      prefixIcon: const Icon(Icons.person_outline),
                      border: const OutlineInputBorder(),
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
                        tooltip: _tokenObscured ? 'Tampilkan' : 'Sembunyikan',
                        icon: Icon(
                          _tokenObscured
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _tokenObscured = !_tokenObscured),
                      ),
                      border: const OutlineInputBorder(),
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
                            foregroundColor:
                                Theme.of(context).colorScheme.error,
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SettingsSection(
                title: strings.aboutApp,
                icon: Icons.info_outline,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(strings.appDescription),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${strings.version} $appVersionName - ${strings.build} $appBuildNumber\n${strings.androidApiSupport}',
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

  Future<void> _update(AppSettings settings) {
    return appSettingsController.update(settings);
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
            _AboutRow(label: strings.build, value: appBuildNumber),
            _AboutRow(label: 'Android', value: strings.androidApiSupport),
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
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

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

class _CredentialStatusPill extends StatelessWidget {
  final bool hasCredentials;

  const _CredentialStatusPill({required this.hasCredentials});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final strings = stringsFor(appSettingsController.value.languageCode);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: hasCredentials
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        hasCredentials ? strings.credentialsActive : strings.credentialsEmpty,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: hasCredentials
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;

  const _AboutRow({required this.label, required this.value});

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
