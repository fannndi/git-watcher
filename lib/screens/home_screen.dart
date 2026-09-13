import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
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
import '../widgets/home_states.dart';
import '../widgets/repo_tile.dart';
import '../widgets/skeleton.dart';
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

  List<WatchedRepo> _repos = [];
  DateTime? _lastSyncAt;
  bool _isLoading = true;
  bool _isSyncing = false;
  bool _loadFailed = false;
  bool _isOffline = false;
  bool _isSearching = false;
  bool _hasUnreadUpdates = false;
  bool _showTour = false;
  int _syncCompleted = 0;
  int _syncTotal = 0;
  String _searchQuery = '';
  WatchedRepo? _selectedRepo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRepos();
    _checkConnectivity();
    _checkTour();
    _checkAppUpdate();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _openFromNotification());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _storage.setUnreadCycles(0);
    }
  }

  Future<void> _openFromNotification() async {
    final payload = await NotificationService.initialPayload();
    if (payload != null && mounted) {
      await NotificationService.handlePayload(payload);
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
      final lastSeenAt = await _storage.getLastSeenAt();
      final history = await _storage.getSyncHistory();
      if (!mounted) return;

      final latestLog = history.isEmpty ? null : history.first.syncedAt;
      setState(() {
        _repos = repos;
        _lastSyncAt = lastSyncAt;
        _isLoading = false;
        _loadFailed = false;
        _hasUnreadUpdates = latestLog != null &&
            (lastSeenAt == null || latestLog.isAfter(lastSeenAt));
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

  Future<void> _deleteRepo(WatchedRepo repo, int index) async {
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

    final strings = stringsFor(appSettingsController.value.languageCode);
    setState(() {
      _repos = updated;
      if (_selectedRepo != null &&
          !updated.any(
            (item) =>
                item.owner == _selectedRepo!.owner &&
                item.repo == _selectedRepo!.repo &&
                item.branch == _selectedRepo!.branch,
          )) {
        _selectedRepo = null;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(strings.repoDeleted(repo.fullName)),
        action: SnackBarAction(
          label: strings.undo,
          onPressed: () => _restoreRepo(repo, index),
        ),
      ),
    );
  }

  Future<void> _restoreRepo(WatchedRepo repo, int index) async {
    final repos = await _storage.getRepos();
    final exists = repos.any(
      (item) =>
          item.owner == repo.owner &&
          item.repo == repo.repo &&
          item.branch == repo.branch,
    );
    if (exists) return;

    final restored = [...repos];
    if (index >= 0 && index <= restored.length) {
      restored.insert(index, repo);
    } else {
      restored.add(repo);
    }

    await _storage.saveRepos(restored);
    if (!mounted) return;
    setState(() => _repos = restored);
  }

  Future<void> _toggleMuted(WatchedRepo repo) async {
    final index = _repos.indexWhere(
      (item) =>
          item.owner == repo.owner &&
          item.repo == repo.repo &&
          item.branch == repo.branch,
    );
    if (index < 0) return;

    final muted = !repo.muted;
    final updated = [..._repos];
    updated[index] = repo.copyWith(muted: muted);
    await _storage.saveRepos(updated);
    if (!mounted) return;

    final strings = stringsFor(appSettingsController.value.languageCode);
    setState(() => _repos = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          muted
              ? strings.repoMuted(repo.fullName)
              : strings.repoUnmuted(repo.fullName),
        ),
      ),
    );
  }

  Future<void> _showRepoActions(WatchedRepo repo) async {
    final strings = stringsFor(appSettingsController.value.languageCode);
    final colorScheme = Theme.of(context).colorScheme;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: Text(strings.openInBrowser),
              onTap: () {
                Navigator.pop(sheetContext);
                _openRepoInBrowser(repo);
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: Text(strings.copyLink),
              onTap: () {
                Navigator.pop(sheetContext);
                _copyRepoLink(repo, strings);
              },
            ),
            ListTile(
              leading: Icon(
                repo.muted
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
              ),
              title: Text(repo.muted ? strings.unmuteRepo : strings.muteRepo),
              onTap: () {
                Navigator.pop(sheetContext);
                _toggleMuted(repo);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: colorScheme.error),
              title: Text(strings.delete),
              onTap: () {
                Navigator.pop(sheetContext);
                _deleteRepo(repo, _repos.indexOf(repo));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openRepoInBrowser(WatchedRepo repo) async {
    await launchUrl(
      Uri.https(githubWebHost, '/${repo.fullName}/tree/${repo.branch}'),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _copyRepoLink(WatchedRepo repo, AppStrings strings) async {
    await Clipboard.setData(
      ClipboardData(
        text: 'https://$githubWebHost/${repo.fullName}/tree/${repo.branch}',
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.linkCopied)),
    );
  }

  Future<void> _syncNow() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
      _syncCompleted = 0;
      _syncTotal = 0;
    });
    final strings = stringsFor(appSettingsController.value.languageCode);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final updates = await SyncService.checkUpdates(
        onProgress: (completed, total) {
          if (mounted) {
            setState(() {
              _syncCompleted = completed;
              _syncTotal = total;
            });
          }
        },
      );
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
        setState(() {
          _isSyncing = false;
          _syncCompleted = 0;
          _syncTotal = 0;
        });
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
        final repos = _filteredRepos;
        final wide = MediaQuery.sizeOf(context).width >= 720;

        return Stack(
          children: [
            if (wide)
              Row(
                children: [
                  SizedBox(
                    width: 420,
                    child: _buildHomeScaffold(strings, repos, wide: true),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: _buildDetailPane(strings)),
                ],
              )
            else
              _buildHomeScaffold(strings, repos, wide: false),
            if (_showTour)
              HomeTourOverlay(strings: strings, onDismiss: _dismissTour),
          ],
        );
      },
    );
  }

  Widget _buildHomeScaffold(
    AppStrings strings,
    List<WatchedRepo> repos, {
    required bool wide,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _syncNow,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (wide)
              SliverAppBar(
                pinned: true,
                title: Text(strings.appTitle),
                actions: [
                  _buildSyncAction(strings),
                  PopupMenuButton<String>(
                    tooltip: strings.settings,
                    onSelected: _handleOverflow,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'search',
                        child: Text(strings.search),
                      ),
                      PopupMenuItem(
                        value: 'history',
                        child: Text(strings.history),
                      ),
                      PopupMenuItem(
                        value: 'settings',
                        child: Text(strings.settings),
                      ),
                    ],
                  ),
                ],
              )
            else
              SliverAppBar.large(
                title: Text(strings.appTitle),
                actions: [
                  if (_isOffline) _buildOfflineBadge(strings, colorScheme),
                  IconButton(
                    tooltip:
                        _isSearching ? strings.closeSearch : strings.search,
                    icon: Icon(_isSearching ? Icons.close : Icons.search),
                    onPressed: _toggleSearch,
                  ),
                  _buildSyncAction(strings),
                  IconButton(
                    tooltip: strings.history,
                    icon: Badge(
                      isLabelVisible: _hasUnreadUpdates,
                      child: const Icon(Icons.notifications_outlined),
                    ),
                    onPressed: _openHistory,
                  ),
                  IconButton(
                    tooltip: strings.settings,
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: _openSettings,
                  ),
                ],
              ),
            if (_isSearching)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: SearchBar(
                    autoFocus: true,
                    hintText: strings.searchRepo,
                    leading: const Icon(Icons.search),
                    elevation: const WidgetStatePropertyAll(0),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
              ),
            if (_lastSyncAt != null || _isSyncing)
              SliverToBoxAdapter(
                child: HomeSyncBar(
                  strings: strings,
                  lastSyncAt: _lastSyncAt,
                  isSyncing: _isSyncing,
                  completed: _syncCompleted,
                  total: _syncTotal,
                  slotLabel: '${_repos.length}/$maxWatchedRepos',
                ),
              ),
            ..._buildContentSlivers(strings, repos, wide),
            SliverToBoxAdapter(
              child: SizedBox(
                height: repos.length >= maxWatchedRepos ? 24 : 96,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _repos.length >= maxWatchedRepos
          ? null
          : _repos.isEmpty
              ? FloatingActionButton.extended(
                  onPressed: _openAddRepo,
                  tooltip: strings.addRepo,
                  icon: const Icon(Icons.add),
                  label: Text(strings.addRepo),
                )
              : FloatingActionButton(
                  onPressed: _openAddRepo,
                  tooltip: strings.addRepo,
                  child: const Icon(Icons.add),
                ),
    );
  }

  Widget _buildSyncAction(AppStrings strings) {
    return IconButton(
      tooltip: strings.syncNow,
      icon: _isSyncing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.sync),
      onPressed: _isSyncing ? null : _syncNow,
    );
  }

  Widget _buildOfflineBadge(AppStrings strings, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        strings.offline,
        style: TextStyle(color: colorScheme.onErrorContainer, fontSize: 12),
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
      }
    });
  }

  Future<void> _openHistory() async {
    setState(() => _hasUnreadUpdates = false);
    await _storage.setLastSeenAt(DateTime.now());
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const UpdateScreen()),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _handleOverflow(String value) {
    switch (value) {
      case 'search':
        _toggleSearch();
      case 'history':
        _openHistory();
      case 'settings':
        _openSettings();
    }
  }

  Widget _buildDetailPane(AppStrings strings) {
    final repo = _selectedRepo;
    final colorScheme = Theme.of(context).colorScheme;

    if (repo == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.touch_app_outlined,
                size: 56,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                strings.selectRepo,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                strings.selectRepoHint,
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

    return DetailScreen(
      key: ValueKey('${repo.fullName}-${repo.branch}'),
      repo: repo,
    );
  }

  List<Widget> _buildContentSlivers(
    AppStrings strings,
    List<WatchedRepo> repos,
    bool wide,
  ) {
    if (_isLoading) {
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          sliver: SliverList.separated(
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, __) => const Skeleton(child: SkeletonRepoTile()),
          ),
        ),
      ];
    }

    if (_loadFailed && _repos.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: HomeErrorState(strings: strings, onRetry: _loadRepos),
        ),
      ];
    }

    if (repos.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _repos.isEmpty
              ? HomeEmptyState(strings: strings, onAddRepo: _openAddRepo)
              : HomeNoResultsState(strings: strings),
        ),
      ];
    }

    return [_buildRepoList(repos, strings, wide: wide)];
  }

  Widget _buildRepoList(
    List<WatchedRepo> repos,
    AppStrings strings, {
    required bool wide,
  }) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      sliver: SliverList.separated(
        itemCount: repos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            _buildRepoItem(repos[index], index, strings, wide: wide),
      ),
    );
  }

  Widget _buildRepoItem(
    WatchedRepo repo,
    int index,
    AppStrings strings, {
    required bool wide,
  }) {
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
        onDismissed: (_) => _deleteRepo(repo, index),
        child: RepoTile(
          repo: repo,
          onTap: () {
            if (wide) {
              setState(() => _selectedRepo = repo);
            } else {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => DetailScreen(repo: repo)),
              );
            }
          },
          onDelete: () => _deleteRepo(repo, index),
          onLongPress: () => _showRepoActions(repo),
        ),
      ),
    );
  }
}
