import 'package:flutter/material.dart';

import '../models/watched_repo.dart';
import '../services/app_settings_controller.dart';
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

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();
  List<WatchedRepo> _repos = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  String _languageCode = languageIndonesian;
  bool _hasUnreadUpdates = false;

  @override
  void initState() {
    super.initState();
    _languageCode = appSettingsController.value.languageCode;
    appSettingsController.addListener(_onSettingsChanged);
    _loadRepos();
  }

  @override
  void dispose() {
    appSettingsController.removeListener(_onSettingsChanged);
    super.dispose();
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
    try {
      final repos = await _storage.getRepos();
      if (!mounted) return;
      setState(() {
        _repos = repos;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load repos: $e')),
      );
    }
  }

  Future<void> _openAddRepo() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddRepoScreen()),
    );
    if (added == true) {
      await _loadRepos();
      _syncNow(); // sync langsung setelah repo baru ditambahkan
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

      // Reload repos
      final repos = await _storage.getRepos();
      if (!mounted) return;
      setState(() {
        _repos = repos;
      });

      if (updates.isNotEmpty) {
        setState(() => _hasUnreadUpdates = true);
        messenger.showSnackBar(
          SnackBar(content: Text(strings.reposHaveUpdates(updates.length))),
        );
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(strings.syncFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = stringsFor(_languageCode);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.appTitle),
            Text(
              'v$appVersionName',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
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
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadRepos();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Repos refreshed'),
                duration: Duration(seconds: 1),
              ),
            );
          }
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _repos.isEmpty
                ? _buildEmptyState(strings)
                : _buildRepoList(),
      ),
      floatingActionButton: _repos.length >= maxWatchedRepos
          ? null
          : FloatingActionButton(
              onPressed: _openAddRepo,
              child: const Icon(Icons.add),
            ),
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

  Widget _buildRepoList() {
    return ListView.separated(
      padding:
          EdgeInsets.only(bottom: _repos.length >= maxWatchedRepos ? 24 : 96),
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
            confirmDismiss: (_) async {
              return await showDialog<bool>(
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
              );
            },
            onDismissed: (_) async {
              await _deleteRepo(repo);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(strings.repoRemoved(repo.fullName))),
                );
              }
            },
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
}
