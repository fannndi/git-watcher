import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_settings.dart';
import '../models/github_credentials.dart';
import '../services/app_settings_controller.dart';
import '../services/startup_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
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

  DateTime? _nextSyncAt;
  DateTime? _lastBackgroundSyncAt;
  String? _lastBackgroundSyncStatus;
  Timer? _countdownTimer;
  String _countdownText = '--:--';
  bool _isPermissionGranted = true;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
    _loadNextSyncAt();
    _loadBackgroundStatus();
    _checkPermission();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _usernameController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _loadNextSyncAt() async {
    final nextSync = await _storage.getNextSyncAt();
    if (!mounted) return;
    setState(() {
      _nextSyncAt = nextSync;
    });
    _updateCountdownText();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdownText();
    });
  }

  Future<void> _loadBackgroundStatus() async {
    final lastRun = await _storage.getLastBackgroundSyncAt();
    final lastStatus = await _storage.getLastBackgroundSyncStatus();
    if (!mounted) return;
    setState(() {
      _lastBackgroundSyncAt = lastRun;
      _lastBackgroundSyncStatus = lastStatus;
    });
  }

  Future<void> _checkPermission() async {
    final granted = await NotificationService.isPermissionGranted();
    if (!mounted) return;
    setState(() {
      _isPermissionGranted = granted;
    });
  }

  Future<void> _requestPermission() async {
    await NotificationService.requestPermission();
    await _checkPermission();
  }

  void _updateCountdownText() {
    if (!mounted || _nextSyncAt == null) return;
    final now = DateTime.now();
    final diff = _nextSyncAt!.difference(now);
    if (diff.isNegative) {
      setState(() => _countdownText = '00:00 (Syncing...)');
    } else {
      final m = diff.inMinutes.toString().padLeft(2, '0');
      final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
      setState(() => _countdownText = '$m:$s');
    }
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
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
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
                        tooltip: _tokenObscured ? strings.show : strings.hide,
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
                              : () => _saveCredentials(stringsFor(
                                  appSettingsController.value.languageCode)),
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
                title: strings.syncSettings,
                icon: Icons.sync_outlined,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: settings.syncIntervalMinutes,
                    decoration: InputDecoration(
                      labelText: strings.syncInterval,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.timer_outlined),
                    ),
                    items: [15, 30, 60, 120, 240, 720, 1440].map((mins) {
                      String label;
                      if (mins == 60) {
                        label = strings.oneHour;
                      } else if (mins == 120) {
                        label = strings.twoHours;
                      } else if (mins >= 1440) {
                        label = '24 ${strings.isEnglish ? 'hours' : 'jam'}';
                      } else {
                        label = strings.minutes(mins);
                      }
                      return DropdownMenuItem(
                        value: mins,
                        child: Text(label),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _update(settings.copyWith(syncIntervalMinutes: value));
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Estimasi Sync Berikutnya',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _countdownText,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Catatan: Sesuai aturan Android, WorkManager bisa saja tertunda oleh Doze mode atau penghemat baterai.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        await StartupService.requestBatteryOptimizationExemption();
                      },
                      icon: const Icon(Icons.battery_charging_full_outlined),
                      label: const Text('Izinkan Baterai Penuh (Wajib!)'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap tombol di atas lalu pilih "Izinkan" agar background sync berjalan saat layar mati.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildBackgroundDiagnostic(strings),
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
                        '${strings.version} $appVersionName - $appReleaseChannel\n${strings.developer}: $developerName',
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

  Widget _buildBackgroundDiagnostic(AppStrings strings) {
    final colorScheme = Theme.of(context).colorScheme;
    final lastRunText = _lastBackgroundSyncAt != null
        ? '${_lastBackgroundSyncAt!.toLocal().hour.toString().padLeft(2, '0')}:${_lastBackgroundSyncAt!.toLocal().minute.toString().padLeft(2, '0')}'
        : 'Never';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monitor_heart_outlined, size: 16, color: colorScheme.primary),
              const SizedBox(width: 8),
              const Text(
                'Diagnostic: Background Worker',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _DiagnosticRow(label: 'Last Run', value: lastRunText),
          _DiagnosticRow(
            label: 'Last Status',
            value: _lastBackgroundSyncStatus ?? 'Unknown',
            isError: _lastBackgroundSyncStatus?.contains('Failed') ?? false,
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 16),
          _DiagnosticRow(
            label: 'Notification',
            value: _isPermissionGranted ? 'Granted' : 'Denied / Not Requested',
            isError: !_isPermissionGranted,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isPermissionGranted ? null : _requestPermission,
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: const Text('Request Permission'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => NotificationService.testNotification(),
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Test Notification'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                // Re-register with current interval to force a reset
                final interval = appSettingsController.value.syncIntervalMinutes;
                await StartupService.resetBackgroundSync(interval);
                if (!context.mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text('Background sync dijadwalkan ulang setiap $interval menit.')),
                );
              },
              icon: const Icon(Icons.restart_alt_outlined),
              label: const Text('Reset Background Sync'),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(fontSize: 11),
              ),
            ),
          ),
        ],
      ),
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

class _AboutLinkRow extends StatelessWidget {
  final String label;
  final String value;
  final String url;

  const _AboutLinkRow({
    required this.label,
    required this.value,
    required this.url,
  });

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

class _DiagnosticRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isError;

  const _DiagnosticRow({
    required this.label,
    required this.value,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isError ? Theme.of(context).colorScheme.error : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
