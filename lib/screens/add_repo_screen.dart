import 'package:flutter/material.dart';

import '../models/watched_repo.dart';
import '../services/github_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class AddRepoScreen extends StatefulWidget {
  const AddRepoScreen({super.key});

  @override
  State<AddRepoScreen> createState() => _AddRepoScreenState();
}

class _AddRepoScreenState extends State<AddRepoScreen> {
  final TextEditingController _controller = TextEditingController();
  final GitHubService _github = GitHubService();
  final StorageService _storage = StorageService();

  Map<String, dynamic>? _foundRepo;
  String? _owner;
  String? _repo;
  bool _isChecking = false;
  bool _isAdding = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkRepo() async {
    final input = _controller.text.trim();
    setState(() => _foundRepo = null);

    if (input.isEmpty) {
      _showError('Input repository tidak boleh kosong');
      return;
    }

    if (!input.contains('/')) {
      _showError('Format harus owner/repo');
      return;
    }

    final parts = input.split('/');
    if (parts.length != 2 || parts.any((part) => part.trim().isEmpty)) {
      _showError('Format harus owner/repo');
      return;
    }

    final owner = parts[0].trim();
    final repo = parts[1].trim();
    final existing = await _storage.getRepos();

    if (existing.length >= maxWatchedRepos) {
      _showError('Maksimal 3 repo dapat dipantau');
      return;
    }

    final duplicate = existing.any(
      (item) =>
          item.owner.toLowerCase() == owner.toLowerCase() &&
          item.repo.toLowerCase() == repo.toLowerCase(),
    );
    if (duplicate) {
      _showError('Repository sudah dipantau');
      return;
    }

    setState(() => _isChecking = true);
    try {
      final result = await _github.getRepo(owner, repo);
      if (!mounted) return;

      if (result == null) {
        _showError('Repository tidak ditemukan');
        return;
      }

      setState(() {
        _foundRepo = result;
        _owner = owner;
        _repo = repo;
      });
    } catch (_) {
      if (!mounted) return;
      _showError('Koneksi gagal. Cek internet lalu coba lagi.');
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _addRepo() async {
    final owner = _owner;
    final repo = _repo;
    final foundRepo = _foundRepo;
    if (owner == null || repo == null || foundRepo == null) {
      return;
    }

    setState(() => _isAdding = true);
    try {
      final existing = await _storage.getRepos();
      final commits = await _github.fetchCommits(owner, repo);
      final newRepo = WatchedRepo(
        owner: owner,
        repo: repo,
        branch: foundRepo['default_branch'] as String? ?? 'main',
        lastSha: commits.isEmpty ? '' : commits.first.sha,
      );

      await _storage.saveRepos([...existing, newRepo]);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      _showError('Gagal menambahkan repo. Cek koneksi internet.');
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final foundRepo = _foundRepo;

    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Repo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _controller,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Repository',
              helperText: 'Masukkan format owner/repo, contoh: flutter/flutter',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _checkRepo(),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _isChecking ? null : _checkRepo,
            icon: _isChecking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search),
            label: const Text('Check'),
          ),
          if (foundRepo != null) ...[
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Repository ditemukan',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      foundRepo['full_name'] as String? ??
                          '${_owner ?? ''}/${_repo ?? ''}',
                    ),
                    Text('Branch default: ${foundRepo['default_branch'] ?? 'main'}'),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _isAdding ? null : _addRepo,
                      icon: _isAdding
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add),
                      label: const Text('Tambahkan'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
