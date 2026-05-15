import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:intl/intl.dart';

import '../models/watched_repo.dart';
import '../services/app_settings_controller.dart';
import '../services/storage_service.dart';
import '../services/startup_service.dart';
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
    _autoSyncTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
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
    try {
      final updates = await SyncService.checkUpdates();

      await _loadRepos();
      if (!mounted) return;

      final message = updates.isEmpty
          ? strings.noUpdates
          : strings.reposHaveUpdates(updates.length);

      ScaffoldMessenger.of(context).showSnackBar(
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(strings),
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
        return Dismissible(
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
        );
      },
    );
  }

  Widget _buildSyncOverlay() {
    final colorScheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 5.0 * value,
            sigmaY: 5.0 * value,
          ),
          child: Container(
            color: colorScheme.surface.withValues(alpha: 0.3 * value),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.8 * value),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1 * value),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _languageCode == languageIndonesian ? 'Sinkronisasi...' : 'Syncing...',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

}
