import 'package:flutter/material.dart';

import '../app.dart';
import '../models/app_settings.dart';
import '../models/github_credentials.dart';
import '../services/app_settings_controller.dart';
import '../services/notification_service.dart';
import '../services/startup_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/strings.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  static const int _pageCount = 4;

  final PageController _pageController = PageController();
  final StorageService _storage = StorageService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();

  late AppSettings _draft = appSettingsController.value;
  int _page = 0;
  bool _permissionGranted = false;
  bool _finishing = false;

  @override
  void dispose() {
    _pageController.dispose();
    _usernameController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _apply(AppSettings settings) async {
    setState(() => _draft = settings);
    await appSettingsController.update(settings);
  }

  void _next() {
    if (_page < _pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _finish();
    }
  }

  void _back() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _requestPermission() async {
    final granted = await NotificationService.ensurePermission();
    if (mounted) {
      setState(() => _permissionGranted = granted);
    }
  }

  Future<void> _pickTime({required bool wake}) async {
    final current = wake ? _draft.wakeMinutes : _draft.sleepMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (picked == null) return;

    final minutes = picked.hour * 60 + picked.minute;
    await _apply(
      wake
          ? _draft.copyWith(wakeMinutes: minutes)
          : _draft.copyWith(sleepMinutes: minutes),
    );
  }

  Future<void> _finish() async {
    setState(() => _finishing = true);
    try {
      final username = _usernameController.text.trim();
      final token = _tokenController.text.trim();
      if (username.isNotEmpty && token.isNotEmpty) {
        await _storage.saveCredentials(
          GitHubCredentials(username: username, token: token),
        );
      }

      await appSettingsController.update(_draft);
      await _storage.setCompletedSetup(true);
      await _storage.setHasSeenTour(true);
      await StartupService.applySyncInterval();

      if (mounted) {
        setupCompletedNotifier.value = true;
      }
    } finally {
      if (mounted) {
        setState(() => _finishing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppSettings>(
      valueListenable: appSettingsController,
      builder: (context, settings, _) {
        final strings = stringsFor(settings.languageCode);
        final colorScheme = Theme.of(context).colorScheme;

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _page = index),
                    children: [
                      _buildWelcomePage(strings),
                      _buildSchedulePage(strings),
                      _buildPermissionsPage(strings),
                      _buildAccountPage(strings),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _pageCount; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _page ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _page
                              ? colorScheme.primary
                              : colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Row(
                    children: [
                      if (_page > 0)
                        TextButton(
                          onPressed: _back,
                          child: Text(strings.setupBack),
                        ),
                      const Spacer(),
                      FilledButton(
                        onPressed: _finishing ? null : _next,
                        child: _finishing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                _page == _pageCount - 1
                                    ? strings.setupStart
                                    : strings.setupNext,
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _pageShell({
    required IconData icon,
    required String title,
    required String description,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
      children: [
        Icon(icon, size: 64, color: theme.colorScheme.primary),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          description,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 28),
        ...children,
      ],
    );
  }

  Widget _buildWelcomePage(AppStrings strings) {
    return _pageShell(
      icon: Icons.watch_later_outlined,
      title: strings.setupWelcomeTitle,
      description: strings.setupWelcomeDesc,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _draft.languageCode,
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
              _apply(_draft.copyWith(languageCode: value));
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
          selected: {_draft.themeMode},
          onSelectionChanged: (selected) {
            _apply(_draft.copyWith(themeMode: selected.first));
          },
        ),
      ],
    );
  }

  Widget _buildSchedulePage(AppStrings strings) {
    return _pageShell(
      icon: Icons.schedule_outlined,
      title: strings.setupScheduleTitle,
      description: strings.setupScheduleDesc,
      children: [
        DropdownButtonFormField<int>(
          initialValue: _draft.syncIntervalMinutes,
          decoration: InputDecoration(
            labelText: strings.syncInterval,
            prefixIcon: const Icon(Icons.timer_outlined),
          ),
          items: [
            for (final minutes in syncIntervalOptions)
              DropdownMenuItem(
                value: minutes,
                child: Text(strings.minutes(minutes)),
              ),
          ],
          onChanged: (value) {
            if (value != null) {
              _apply(_draft.copyWith(syncIntervalMinutes: value));
            }
          },
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(strings.enableNotifications),
          value: _draft.notificationsEnabled,
          onChanged: (value) =>
              _apply(_draft.copyWith(notificationsEnabled: value)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(strings.quietHours),
          value: _draft.quietHoursEnabled,
          onChanged: (value) =>
              _apply(_draft.copyWith(quietHoursEnabled: value)),
        ),
        if (_draft.quietHoursEnabled)
          Row(
            children: [
              Expanded(
                child: _SetupTimeField(
                  label: strings.wakeUpTime,
                  icon: Icons.wb_twilight_outlined,
                  value: _draft.wakeMinutes,
                  onTap: () => _pickTime(wake: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SetupTimeField(
                  label: strings.sleepTime,
                  icon: Icons.bedtime_outlined,
                  value: _draft.sleepMinutes,
                  onTap: () => _pickTime(wake: false),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildPermissionsPage(AppStrings strings) {
    return _pageShell(
      icon: Icons.notifications_active_outlined,
      title: strings.setupPermissionsTitle,
      description: strings.setupPermissionsDesc,
      children: [
        FilledButton.icon(
          onPressed: _permissionGranted ? null : _requestPermission,
          icon: Icon(
            _permissionGranted
                ? Icons.check_circle_outline
                : Icons.notifications_outlined,
          ),
          label: Text(
            _permissionGranted
                ? strings.permissionGranted
                : strings.grantPermission,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: StartupService.requestBatteryOptimizationExemption,
          icon: const Icon(Icons.bolt),
          label: Text(strings.allowBatteryExemption),
        ),
      ],
    );
  }

  Widget _buildAccountPage(AppStrings strings) {
    return _pageShell(
      icon: Icons.lock_outline,
      title: strings.setupAccountTitle,
      description: strings.setupAccountDesc,
      children: [
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
          obscureText: true,
          decoration: InputDecoration(
            labelText: strings.githubToken,
            helperText: strings.githubTokenHelper,
            prefixIcon: const Icon(Icons.key_outlined),
          ),
        ),
      ],
    );
  }
}

class _SetupTimeField extends StatelessWidget {
  const _SetupTimeField({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final int value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = stringsFor(appSettingsController.value.languageCode);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
        child: Text(strings.timeLabel(value)),
      ),
    );
  }
}
