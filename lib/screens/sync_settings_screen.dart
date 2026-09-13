import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../services/app_settings_controller.dart';
import '../services/notification_service.dart';
import '../services/startup_service.dart';
import '../utils/constants.dart';
import '../utils/strings.dart';
import '../widgets/settings_section.dart';

class SyncSettingsScreen extends StatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  State<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends State<SyncSettingsScreen> {
  bool _isTestingNotification = false;

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

  Future<void> _pickTime(AppSettings settings, {required bool wake}) async {
    final current = wake ? settings.wakeMinutes : settings.sleepMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (picked == null) return;

    final minutes = picked.hour * 60 + picked.minute;
    await _update(
      wake
          ? settings.copyWith(wakeMinutes: minutes)
          : settings.copyWith(sleepMinutes: minutes),
    );
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppSettings>(
      valueListenable: appSettingsController,
      builder: (context, settings, _) {
        final strings = stringsFor(settings.languageCode);

        return Scaffold(
          appBar: AppBar(title: Text(strings.syncSettings)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SettingsSection(
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
                    contentPadding: EdgeInsets.zero,
                    title: Text(strings.enableNotifications),
                    subtitle: Text(strings.enableNotificationsDesc),
                    value: settings.notificationsEnabled,
                    onChanged: (value) {
                      _update(settings.copyWith(notificationsEnabled: value));
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(strings.hideNotificationContent),
                    subtitle: Text(strings.hideNotificationContentDesc),
                    value: settings.hideNotificationContent,
                    onChanged: (value) {
                      _update(
                        settings.copyWith(hideNotificationContent: value),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
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
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(strings.extremePrecision),
                    subtitle: Text(strings.extremePrecisionDesc),
                    value: settings.preciseSync,
                    onChanged: (value) async {
                      await _update(settings.copyWith(preciseSync: value));
                      await StartupService.applySyncInterval();
                    },
                  ),
                  const SizedBox(height: 4),
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
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(strings.wifiOnly),
                    subtitle: Text(strings.wifiOnlyDesc),
                    value: settings.wifiOnly,
                    onChanged: (value) {
                      _update(settings.copyWith(wifiOnly: value));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SettingsSection(
                title: strings.quietHours,
                icon: Icons.bedtime_outlined,
                children: [
                  Text(
                    strings.quietHoursDesc,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(strings.quietHours),
                    value: settings.quietHoursEnabled,
                    onChanged: (value) {
                      _update(settings.copyWith(quietHoursEnabled: value));
                    },
                  ),
                  if (settings.quietHoursEnabled)
                    Row(
                      children: [
                        Expanded(
                          child: _TimeField(
                            label: strings.wakeUpTime,
                            value: settings.wakeMinutes,
                            icon: Icons.wb_twilight_outlined,
                            onPick: () => _pickTime(settings, wake: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TimeField(
                            label: strings.sleepTime,
                            value: settings.sleepMinutes,
                            icon: Icons.bedtime_outlined,
                            onPick: () => _pickTime(settings, wake: false),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(strings.alertOnUnread),
                    subtitle: Text(strings.alertOnUnreadDesc),
                    value: settings.alertOnUnread,
                    onChanged: (value) {
                      _update(settings.copyWith(alertOnUnread: value));
                    },
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: StartupService.openNotificationSettings,
                      icon: const Icon(Icons.tune_outlined),
                      label: Text(strings.openNotificationSettings),
                    ),
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

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onPick,
  });

  final String label;
  final int value;
  final IconData icon;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final strings = stringsFor(appSettingsController.value.languageCode);

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        child: Text(strings.timeLabel(value)),
      ),
    );
  }
}
