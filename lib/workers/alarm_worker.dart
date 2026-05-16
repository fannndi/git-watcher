import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/widgets.dart';

import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';

/// ID tetap untuk alarm periodik.
const int _alarmId = 42;

/// Interval exact — 60 menit.
const Duration alarmInterval = Duration(hours: 1);

/// Entry-point yang dipanggil AlarmManager di isolate terpisah.
/// Fungsi ini HARUS top-level (bukan method) dan diberi @pragma.
@pragma('vm:entry-point')
Future<void> alarmCallback() async {
  // Dua baris ini wajib di setiap background isolate Flutter
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('AlarmWorker: exact alarm fired');

  final storage = StorageService();

  // Tulis status awal sebelum apapun
  await storage.setLastBackgroundSyncAt(DateTime.now());
  await storage.setLastBackgroundSyncStatus('Running...');

  try {
    // Init notifikasi di isolate ini
    await NotificationService.init(isBackground: true);

    final updates = await SyncService.checkUpdates(
      isBackground: true,
    ).timeout(const Duration(minutes: 8));

    final status = updates.isEmpty
        ? 'Success — no new updates'
        : 'Success — ${updates.length} repo(s) updated (${updates.keys.take(3).join(', ')})';

    await storage.setLastBackgroundSyncStatus(status);
    debugPrint('AlarmWorker: $status');
  } catch (e) {
    final errMsg =
        'Failed: ${e.runtimeType}: ${e.toString().substring(0, e.toString().length.clamp(0, 120))}';
    debugPrint('AlarmWorker error: $errMsg');
    await storage.setLastBackgroundSyncStatus(errMsg);
  }
}

/// Mendaftarkan exact periodic alarm.
/// Menggunakan logic yang mencegah reset jadwal setiap kali aplikasi dibuka.
Future<void> registerExactAlarm() async {
  final storage = StorageService();
  final prefs = await storage.getPrefsForInternal(); // Helper to check raw prefs
  
  // Jika sudah terdaftar, jangan daftar ulang (menghindari reset timer)
  if (prefs.getBool('alarm_registered') == true) {
    debugPrint('AlarmWorker: alarm already registered, skipping registration');
    return;
  }

  await AndroidAlarmManager.periodic(
    alarmInterval,
    _alarmId,
    alarmCallback,
    // Start 15 menit dari sekarang untuk pertama kali, lalu rutin tiap 60 menit
    startAt: DateTime.now().add(const Duration(minutes: 15)),
    exact: true,
    wakeup: true,
    rescheduleOnReboot: true,
  );
  
  await prefs.setBool('alarm_registered', true);
  debugPrint('AlarmWorker: exact periodic alarm registered (60 min)');
}

/// Batalkan alarm (dipanggil saat uninstall / debugging).
Future<void> cancelExactAlarm() async {
  await AndroidAlarmManager.cancel(_alarmId);
  final storage = StorageService();
  final prefs = await storage.getPrefsForInternal();
  await prefs.remove('alarm_registered');
  debugPrint('AlarmWorker: alarm cancelled and flag cleared');
}
