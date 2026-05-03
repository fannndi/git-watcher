import 'package:flutter/material.dart';

import '../models/watched_repo.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';
import '../utils/constants.dart';
import '../widgets/repo_tile.dart';
import 'add_repo_screen.dart';
import 'detail_screen.dart';
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
  bool _isDemoMode = false;

  @override
  void initState() {
    super.initState();
    _loadRepos();
  }

  Future<void> _loadRepos() async {
    setState(() => _isLoading = true);
    final repos = await _storage.getRepos();
    if (!mounted) return;
    setState(() {
      _repos = repos;
      _isLoading = false;
    });
  }

  Future<void> _openAddRepo() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddRepoScreen()),
    );

    if (added == true) {
      await _loadRepos();
    }
  }

  Future<void> _deleteRepo(WatchedRepo repo) async {
    final updated = _repos.where((item) => item.fullName != repo.fullName).toList();
    await _storage.saveRepos(updated);
    if (!mounted) return;
    setState(() => _repos = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${repo.fullName} dihapus')),
    );
  }

  Future<void> _askDemoPassword() async {
    var password = '';
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Demo Mode'),
        content: TextField(
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => password = value,
          onSubmitted: (_) {
            Navigator.of(context).pop(password == demoPassword);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(password == demoPassword);
            },
            child: const Text('Aktifkan'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (accepted == true) {
      setState(() => _isDemoMode = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demo Mode Aktif')),
      );
    } else if (accepted == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password demo salah')),
      );
    }
  }

  Future<void> _syncNow() async {
    setState(() => _isSyncing = true);
    try {
      final updates = await SyncService.checkUpdates(
        forceNotification: _isDemoMode,
      );
      await _loadRepos();
      if (!mounted) return;

      final message = _isDemoMode
          ? 'Sinkron selesai. Notifikasi dikirim.'
          : updates.isEmpty
              ? 'Tidak ada update baru'
              : '${updates.length} repo memiliki update';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

      if (updates.isNotEmpty && !_isDemoMode) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const UpdateScreen()),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sinkronisasi gagal. Cek koneksi internet.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GitHub Watcher'),
        actions: [
          IconButton(
            tooltip: 'Demo Mode',
            icon: const Icon(Icons.bug_report_outlined),
            onPressed: _isDemoMode ? null : _askDemoPassword,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isDemoMode) ...[
                    Text(
                      'Demo Mode Aktif',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _isSyncing ? null : _syncNow,
                      icon: _isSyncing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync),
                      label: const Text('Sinkronkan Sekarang'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Expanded(
                    child: _repos.isEmpty
                        ? const Center(child: Text('Belum ada repo dipantau'))
                        : ListView.builder(
                            itemCount: _repos.length,
                            itemBuilder: (context, index) {
                              final repo = _repos[index];
                              return Dismissible(
                                key: ValueKey(repo.fullName),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 16),
                                  color: Theme.of(context).colorScheme.errorContainer,
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
                          ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _repos.length >= maxWatchedRepos ? _showRepoLimit : _openAddRepo,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showRepoLimit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Maksimal 3 repo dapat dipantau')),
    );
  }
}
