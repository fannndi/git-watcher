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
              // ── Demo Mode ───────────────────────────────────────────────
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

              // ── Sync Interval ────────────────────────────────────────────
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
                  DropdownMenuItem(
                      value: 10, child: Text(strings.minutes(10))),
                  DropdownMenuItem(value: 60, child: Text(strings.oneHour)),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _update(settings.copyWith(syncIntervalMinutes: value));
                  }
                },
              ),
              const SizedBox(height: 16),

              // ── Language ─────────────────────────────────────────────────
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

              // ── Theme ─────────────────────────────────────────────────────
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
              const Divider(height: 32),

              // ── Private Mode ─────────────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.lock_outline, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    strings.privateMode,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _hasCredentials
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _hasCredentials
                          ? strings.credentialsActive
                          : strings.credentialsEmpty,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _hasCredentials
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
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
                              child: CircularProgressIndicator(strokeWidth: 2),
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
}