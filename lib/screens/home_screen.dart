import 'dart:async';

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
  int _syncIntervalMinutes = defaultSyncIntervalMinutes;
  Duration _timeUntilSync = Duration.zero;
  DateTime? _nextSyncAt;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _loadRepos();
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _tickCountdown(),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRepos() async {
    setState(() => _isLoading = true);
    final repos = await _storage.getRepos();
    final history = await _storage.getSyncHistory();
    if (!mounted) return;
    setState(() {
      _repos = repos;
      _isLoading = false;
    });
    _scheduleNextSync(history.isEmpty ? null : history.first.syncedAt);
  }

  Future<void> _openAddRepo() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddRepoScreen()),
    );

    if (added == true) {
      await _loadRepos();
      if (_repos.length == 1 && _nextSyncAt == null) {
        _scheduleNextSync(DateTime.now());
      }
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
    if (updated.isEmpty) {
      _clearCountdown();
    }
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
      setState(() {
        _isDemoMode = true;
        _syncIntervalMinutes = 3;
      });
      _scheduleNextSync(DateTime.now());
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
      _scheduleNextSync(DateTime.now());

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
            tooltip: 'Riwayat Sinkron',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const UpdateScreen()),
            ),
          ),
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
                  if (_repos.isNotEmpty) ...[
                    _buildCountdownCard(),
                    const SizedBox(height: 12),
                  ],
                  if (_isDemoMode) ...[
                    Text(
                      'Demo Mode Aktif',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: _syncIntervalMinutes,
                      decoration: const InputDecoration(
                        labelText: 'Interval Demo',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('1 menit')),
                        DropdownMenuItem(value: 3, child: Text('3 menit')),
                        DropdownMenuItem(value: 5, child: Text('5 menit')),
                        DropdownMenuItem(value: 10, child: Text('10 menit')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _syncIntervalMinutes = value);
                          _scheduleNextSync(DateTime.now());
                        }
                      },
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
                                key: ValueKey('${repo.fullName}-${repo.branch}'),
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

  Widget _buildCountdownCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.timer_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sync berikutnya',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(_isDemoMode ? 'Interval demo aktif' : 'Interval 1 jam'),
                ],
              ),
            ),
            Text(
              _formatDuration(_timeUntilSync),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _scheduleNextSync(DateTime? lastSyncAt) {
    if (_repos.isEmpty) {
      _clearCountdown();
      return;
    }

    final base = lastSyncAt ?? DateTime.now();
    setState(() {
      _nextSyncAt = base.add(Duration(minutes: _syncIntervalMinutes));
    });
    _tickCountdown();
  }

  void _clearCountdown() {
    setState(() {
      _nextSyncAt = null;
      _timeUntilSync = Duration.zero;
    });
  }

  void _tickCountdown() {
    final nextSyncAt = _nextSyncAt;
    if (!mounted || nextSyncAt == null || _repos.isEmpty) {
      return;
    }

    final remaining = nextSyncAt.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      setState(() => _timeUntilSync = Duration.zero);
      if (!_isSyncing) {
        _syncNow();
      }
      return;
    }

    setState(() => _timeUntilSync = remaining);
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}
