import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/watched_repo.dart';
import '../services/app_settings_controller.dart';
import '../services/startup_service.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';
import '../utils/constants.dart';
import '../utils/strings.dart';
import '../widgets/repo_tile.dart';
import 'add_repo_screen.dart';
import 'detail_screen.dart';
import 'settings_screen.dart';
import 'update_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final StorageService _storage = StorageService();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  List<WatchedRepo> _repos = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  String _languageCode = languageIndonesian;
  DateTime? _lastSyncAt;
  bool _hasUnreadUpdates = false;
  bool _showSyncOverlay = false;
  Timer? _autoSyncTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _languageCode = appSettingsController.value.languageCode;
    appSettingsController.addListener(_onSettingsChanged);
    _loadRepos();
    _startAutoSyncChecker();
    // Show battery optimization prompt after first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBatteryOptimizationPrompt();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoSyncTimer?.cancel();
    appSettingsController.removeListener(_onSettingsChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndSyncOnOpen();
    }
  }

  Future<void> _checkAndSyncOnOpen() async {
    if (_isLoading || _isSyncing || !mounted || _repos.isEmpty) return;
    
    final nextSync = await _storage.getNextSyncAt();
    final now = DateTime.now();
    
    // Sync on open/resume if:
    // 1. Next sync time has already passed
    // 2. We have never synced before
    // 3. Next sync is "close enough" (proactive sync)
    //    Kita sync lebih awal jika sisa waktu < 10% dari interval (maks 10 menit)
    //    agar user langsung melihat data fresh saat membuka apps.
    final settings = appSettingsController.value;
    final bufferMinutes = (settings.syncIntervalMinutes * 0.1).round().clamp(1, 10);
    final proactiveThreshold = nextSync?.subtract(Duration(minutes: bufferMinutes));

    if (nextSync == null || now.isAfter(proactiveThreshold!)) {
      setState(() => _showSyncOverlay = true);
      _syncNow();
    }
  }

  void _startAutoSyncChecker() {
    _autoSyncTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_isLoading || _isSyncing || !mounted) return;

      // Update UI if background worker changed the last sync time
      final lastSync = await _storage.getLastSyncAt();
      if (lastSync != null && _lastSyncAt != null && lastSync.isAfter(_lastSyncAt!)) {
        final repos = await _storage.getRepos();
        if (mounted) {
          setState(() {
            _lastSyncAt = lastSync;
            _repos = repos;
          });
        }
      }

      final nextSync = await _storage.getNextSyncAt();
      if (nextSync != null && DateTime.now().isAfter(nextSync)) {
        _syncNow();
      }
    });
  }

  void _onSettingsChanged() {
    if (mounted) {
      setState(() {
        _languageCode = appSettingsController.value.languageCode;
      });
    }
  }

  /// Shows a one-time dialog prompting the user to exempt the app from
  /// battery optimization — critical for background sync reliability.
  Future<void> _checkBatteryOptimizationPrompt() async {
    if (!Platform.isAndroid || !mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final alreadyPrompted = prefs.getBool('battery_opt_prompted') ?? false;
    if (alreadyPrompted || !mounted) return;

    await prefs.setBool('battery_opt_prompted', true);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.battery_charging_full_outlined, size: 36),
        title: const Text('Aktifkan Background Sync'),
        content: const Text(
          'Agar notifikasi Git update berjalan saat layar mati, aplikasi ini perlu dikecualikan dari penghemat baterai Android.\n\nPilih "Izinkan" pada halaman berikutnya.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Nanti'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await StartupService.requestBatteryOptimizationExemption();
            },
            child: const Text('Izinkan Sekarang'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadRepos() async {
    setState(() => _isLoading = true);
    final repos = await _storage.getRepos();
    final lastSync = await _storage.getLastSyncAt();
    if (!mounted) return;
    setState(() {
      _repos = repos;
      _isLoading = false;
      _lastSyncAt = lastSync;
    });

    // Cek sync otomatis setelah data repo dimuat
    _checkAndSyncOnOpen();
  }

  Future<void> _openAddRepo() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddRepoScreen()),
    );
    if (added == true) {
      await _loadRepos();
      _syncNow();
    }
  }

  Future<void> _deleteRepo(WatchedRepo repo) async {
    final updated = _repos.where((item) {
      return item.owner != repo.owner ||
          item.repo != repo.repo ||
          item.branch != repo.branch;
    }).toList();
    await _storage.saveRepos(updated);
    if (!mounted) return;
    setState(() => _repos = updated);
    final strings = stringsFor(_languageCode);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.repoDeleted(repo.fullName))),
    );
  }

  Future<void> _syncNow() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    final strings = stringsFor(_languageCode);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final updates = await SyncService.checkUpdates();

      await _loadRepos();
      final message = updates.isEmpty
          ? strings.noUpdates
          : strings.reposHaveUpdates(updates.length);

      messenger.showSnackBar(
        SnackBar(content: Text(message)),
      );

      // Reset timer sinkronisasi background agar dihitung ulang dari sekarang
      await StartupService.resetBackgroundSync(
        appSettingsController.value.syncIntervalMinutes,
      );

      if (updates.isNotEmpty) {
        setState(() {
          _hasUnreadUpdates = true;
        });
      }
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(strings.syncFailed)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _showSyncOverlay = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = stringsFor(_languageCode);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.appTitle),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: strings.history,
            icon: Badge(
              isLabelVisible: _hasUnreadUpdates,
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () {
              setState(() => _hasUnreadUpdates = false);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const UpdateScreen()),
              );
            },
          ),
          IconButton(
            tooltip: strings.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: _isLoading
                ? const Center(key: ValueKey('loading'), child: CircularProgressIndicator())
                : Padding(
                    key: const ValueKey('content'),
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
                    child: _buildContent(strings),
                  ),
          ),
          if (_showSyncOverlay) _buildSyncOverlay(),
        ],
      ),
      floatingActionButton: _repos.length >= maxWatchedRepos
          ? null
          : FloatingActionButton(
              onPressed: _openAddRepo,
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildContent(AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_repos.isNotEmpty)
          _buildSyncCard(strings),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                strings.watchedRepos,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            Text(
              strings.repoCount(_repos.length),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _repos.isEmpty ? _buildEmptyState(strings) : _buildRepoList(),
        ),
      ],
    );
  }

  Widget _buildSyncCard(AppStrings strings) {
    final colorScheme = Theme.of(context).colorScheme;
    final lastSyncText = _lastSyncAt != null
        ? _dateFormat.format(_lastSyncAt!.toLocal())
        : strings.never;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            _isSyncing ? Icons.sync : Icons.sync_outlined,
            size: 20,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.lastSync,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  lastSyncText,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (_isSyncing)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppStrings strings) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.folder_open_outlined,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              strings.noReposTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              strings.noReposSubtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepoList() {
    return ListView.separated(
      padding: EdgeInsets.only(bottom: _repos.length >= maxWatchedRepos ? 24 : 96),
      itemCount: _repos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final repo = _repos[index];
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 400 + (index * 100).clamp(0, 400)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Dismissible(
            key: ValueKey('${repo.fullName}-${repo.branch}'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.delete_outline),
            ),
            onDismissed: (_) => _deleteRepo(repo),
            child: RepoTile(
              repo: repo,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DetailScreen(repo: repo),
                ),
              ),
              onDelete: () => _deleteRepo(repo),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSyncOverlay() {
    final colorScheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 8.0 * value,
            sigmaY: 8.0 * value,
          ),
          child: Container(
            color: colorScheme.surface.withValues(alpha: 0.4 * value),
            child: Center(
              child: Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Opacity(
                  opacity: value,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.9 * value),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15 * value),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: CircularProgressIndicator(
                            strokeWidth: 5,
                            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _languageCode == languageIndonesian ? 'Sinkronisasi...' : 'Syncing...',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

}
