import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_settings.dart';
import '../models/watched_repo.dart';
import '../services/app_settings_controller.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';
import '../utils/animations.dart';
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

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();
  final DateFormat _syncDateFormat = DateFormat('yyyy-MM-dd HH:mm');

  List<WatchedRepo> _repos = [];
  DateTime? _lastSyncAt;
  bool _isLoading = true;
  bool _isSyncing = false;
  bool _loadFailed = false;
  bool _isOffline = false;
  bool _isSearching = false;
  bool _hasUnreadUpdates = false;
  bool _showTour = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRepos();
    _checkConnectivity();
    _checkTour();
    _checkAppUpdate();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openFromNotification());
  }

  Future<void> _openFromNotification() async {
    final launched = await NotificationService.launchedFromUpdateNotification();
    if (launched && mounted) {
      NotificationService.openUpdateScreen();
    }
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup(githubApiHost);
      if (mounted) {
        setState(
          () => _isOffline = result.isEmpty || result.first.rawAddress.isEmpty,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isOffline = true);
      }
    }
  }

  Future<void> _checkTour() async {
    if (!await _storage.hasSeenTour() && mounted) {
      setState(() => _showTour = true);
    }
  }

  Future<void> _dismissTour() async {
    await _storage.setHasSeenTour(true);
    if (mounted) {
      setState(() => _showTour = false);
    }
  }

  Future<void> _checkAppUpdate() async {
    try {
      final response = await http.get(
        Uri.https(githubApiHost, '/repos/fannndi/git-watcher/releases/latest'),
      );
      if (response.statusCode != 200) {
        return;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final latest = body['tag_name']?.toString().replaceFirst('v', '');
      if (latest == null || latest == appVersionName || !mounted) {
        return;
      }

      final strings = stringsFor(appSettingsController.value.languageCode);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.updateAvailable(latest)),
          action: SnackBarAction(
            label: strings.updateAction,
            onPressed: _openStoreListing,
          ),
        ),
      );
    } catch (_) {}
  }

  Future<void> _openStoreListing() async {
    await launchUrl(
      Uri.parse('https://play.google.com/store/apps/details?id=$appId'),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _loadRepos() async {
    setState(() => _isLoading = true);
    try {
      final repos = await _storage.getRepos();
      final lastSyncAt = await _storage.getLastSyncAt();
      if (!mounted) return;
      setState(() {
        _repos = repos;
        _lastSyncAt = lastSyncAt;
        _isLoading = false;
        _loadFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _openAddRepo() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddRepoScreen()),
    );
    if (added == true) {
      await _loadRepos();
      await _syncNow();
    }
  }

  Future<void> _deleteRepo(WatchedRepo repo) async {
    final updated = _repos
        .where(
          (item) =>
              item.owner != repo.owner ||
              item.repo != repo.repo ||
              item.branch != repo.branch,
        )
        .toList();

    await _storage.saveRepos(updated);
    if (!mounted) return;

    setState(() => _repos = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          stringsFor(appSettingsController.value.languageCode)
              .repoDeleted(repo.fullName),
        ),
      ),
    );
  }

  Future<void> _syncNow() async {
    if (_isSyncing) return;

    setState(() => _isSyncing = true);
    final strings = stringsFor(appSettingsController.value.languageCode);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final updates = await SyncService.checkUpdates();
      final repos = await _storage.getRepos();
      final lastSyncAt = await _storage.getLastSyncAt();
      if (!mounted) return;

      setState(() {
        _repos = repos;
        _lastSyncAt = lastSyncAt;
        _loadFailed = false;
        if (updates.isNotEmpty) {
          _hasUnreadUpdates = true;
        }
      });

      if (updates.isNotEmpty) {
        messenger.showSnackBar(
          SnackBar(content: Text(strings.reposHaveUpdates(updates.length))),
        );
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(strings.syncFailed)));
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  List<WatchedRepo> get _filteredRepos {
    if (_searchQuery.isEmpty) {
      return _repos;
    }

    final query = _searchQuery.toLowerCase();
    return _repos
        .where((repo) => repo.fullName.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppSettings>(
      valueListenable: appSettingsController,
      builder: (context, settings, _) {
        final strings = stringsFor(settings.languageCode);

        return Stack(
          children: [
            Scaffold(
              appBar: AppBar(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strings.appTitle),
                    Text(
                      'v$appVersionName • ${strings.repoCount(_repos.length)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                actions: [
                  if (_isOffline)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        strings.offline,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  IconButton(
                    tooltip: _isSearching ? strings.closeSearch : strings.search,
                    icon: Icon(_isSearching ? Icons.close : Icons.search),
                    onPressed: () {
                      setState(() {
                        _isSearching = !_isSearching;
                        if (!_isSearching) {
                          _searchQuery = '';
                        }
                      });
                    },
                  ),
                  IconButton(
                    tooltip: strings.syncNow,
                    icon: _isSyncing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync),
                    onPressed: _isSyncing ? null : _syncNow,
                  ),
                  IconButton(
                    tooltip: strings.history,
                    icon: Badge(
                      isLabelVisible: _hasUnreadUpdates,
                      child: const Icon(Icons.notifications_outlined),
                    ),
                    onPressed: () {
                      setState(() => _hasUnreadUpdates = false);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const UpdateScreen(),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    tooltip: strings.settings,
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
              body: Column(
                children: [
                  if (_isSearching)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: strings.searchRepo,
                          prefixIcon: const Icon(Icons.search),
                        ),
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                      ),
                    ),
                  if (_lastSyncAt != null) _buildSyncStatusBar(strings),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _syncNow,
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _loadFailed && _repos.isEmpty
                              ? _buildErrorState(strings)
                              : _filteredRepos.isEmpty
                                  ? _buildEmptyState(strings)
                                  : _buildRepoList(strings),
                    ),
                  ),
                ],
              ),
              floatingActionButton: _repos.length >= maxWatchedRepos
                  ? null
                  : FloatingActionButton(
                      onPressed: _openAddRepo,
                      child: const Icon(Icons.add),
                    ),
            ),
            if (_showTour) _buildTourOverlay(strings),
          ],
        );
      },
    );
  }

  Widget _buildSyncStatusBar(AppStrings strings) {
    final colorScheme = Theme.of(context).colorScheme;
    final lastSyncAt = _lastSyncAt;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          if (_isSyncing)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              Icons.cloud_done_outlined,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${strings.lastSync}: ${lastSyncAt == null ? strings.never : _syncDateFormat.format(lastSyncAt.toLocal())}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppStrings strings) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      children: [
        const SizedBox(height: 160),
        Center(
          child: Icon(Icons.error_outline, size: 56, color: colorScheme.error),
        ),
        const SizedBox(height: 16),
        Center(child: Text(strings.loadReposFailed)),
        const SizedBox(height: 16),
        Center(
          child: FilledButton.icon(
            onPressed: _loadRepos,
            icon: const Icon(Icons.refresh),
            label: Text(strings.tryAgain),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(AppStrings strings) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.only(top: 120),
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
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              strings.noReposSubtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _openAddRepo,
              icon: const Icon(Icons.add, size: 18),
              label: Text(strings.addRepo),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepoList(AppStrings strings) {
    final repos = _filteredRepos;

    return ListView.separated(
      padding: EdgeInsets.only(bottom: repos.length >= maxWatchedRepos ? 24 : 96),
      itemCount: repos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final repo = repos[index];

        return FadeInSlideUp(
          index: index,
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
            confirmDismiss: (_) => showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(strings.confirmDelete),
                content: Text(strings.confirmDeleteRepo(repo.fullName)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(strings.cancel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(strings.delete),
                  ),
                ],
              ),
            ),
            onDismissed: (_) => _deleteRepo(repo),
            child: RepoTile(
              repo: repo,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => DetailScreen(repo: repo)),
              ),
              onDelete: () => _deleteRepo(repo),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTourOverlay(AppStrings strings) {
    return Container(
      color: Colors.black54,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.explore,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                strings.appTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                strings.tourWelcome,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 12),
              _tourStep(Icons.add, strings.tourAddRepo),
              _tourStep(Icons.sync, strings.tourSync),
              _tourStep(Icons.swipe, strings.tourSwipe),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _dismissTour,
                child: Text(strings.tourGotIt),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tourStep(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
