import 'package:flutter/material.dart';

import '../models/commit.dart';
import '../models/watched_repo.dart';
import '../services/app_settings_controller.dart';
import '../services/github_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/strings.dart';

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
  List<String> _branches = [];
  String? _selectedBranch;
  String _syncMode = syncModeMinimal;
  bool _isChecking = false;
  bool _isAdding = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkRepo() async {
    final input = _controller.text.trim();
    setState(() {
      _foundRepo = null;
      _branches = [];
      _selectedBranch = null;
    });
    final strings = stringsFor(appSettingsController.value.languageCode);

    if (input.isEmpty) {
      _showError(strings.emptyRepositoryInput);
      return;
    }

    if (!input.contains('/')) {
      _showError(strings.invalidRepositoryFormat);
      return;
    }

    final parts = input.split('/');
    if (parts.length != 2 || parts.any((part) => part.trim().isEmpty)) {
      _showError(strings.invalidRepositoryFormat);
      return;
    }

    final owner = parts[0].trim();
    final repo = parts[1].trim();
    final existing = await _storage.getRepos();

    if (existing.length >= maxWatchedRepos) {
      _showError(strings.maxRepos);
      return;
    }

    setState(() => _isChecking = true);
    try {
      final result = await _github.getRepo(owner, repo);
      if (!mounted) return;

      if (result == null) {
        _showError(strings.repositoryNotFound);
        return;
      }

      final branches = await _github.fetchBranches(owner, repo);
      if (!mounted) return;
      final defaultBranch = result['default_branch'] as String? ?? 'main';
      setState(() {
        _foundRepo = result;
        _owner = owner;
        _repo = repo;
        _branches = branches;
        _selectedBranch = branches.contains(defaultBranch)
            ? defaultBranch
            : branches.isEmpty
                ? defaultBranch
                : branches.first;
      });
    } catch (_) {
      if (!mounted) return;
      _showError(strings.connectionFailed);
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
    final strings = stringsFor(appSettingsController.value.languageCode);
    final branch = _selectedBranch;
    if (owner == null || repo == null || foundRepo == null || branch == null) {
      return;
    }

    setState(() => _isAdding = true);
    try {
      final existing = await _storage.getRepos();
      final duplicate = existing.any(
        (item) =>
            item.owner.toLowerCase() == owner.toLowerCase() &&
            item.repo.toLowerCase() == repo.toLowerCase() &&
            item.branch.toLowerCase() == branch.toLowerCase(),
      );
      if (duplicate) {
        _showError(strings.duplicateRepository);
        return;
      }

      final commits = await _fetchInitialCommits(owner, repo, branch);
      final newRepo = WatchedRepo(
        owner: owner,
        repo: repo,
        branch: branch,
        syncMode: _syncMode,
        lastSha: commits.isEmpty ? '' : commits.first.sha,
      );

      await _storage.saveRepos([...existing, newRepo]);
      await _storage.saveCachedCommits(newRepo, commits);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      _showError(strings.addRepositoryFailed);
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

    return ValueListenableBuilder(
      valueListenable: appSettingsController,
      builder: (context, settings, _) {
        final strings = stringsFor(settings.languageCode);

        return Scaffold(
          appBar: AppBar(title: Text(strings.addRepo)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _controller,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: strings.repository,
                  helperText: strings.repositoryInputHelper,
                  border: const OutlineInputBorder(),
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
                label: Text(strings.check),
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
                        Text(
                          strings.repositoryFound,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          foundRepo['full_name'] as String? ??
                              '${_owner ?? ''}/${_repo ?? ''}',
                        ),
                        Text(
                          '${strings.defaultBranch}: ${foundRepo['default_branch'] ?? 'main'}',
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedBranch,
                          decoration: InputDecoration(
                            labelText: strings.watchedBranch,
                            border: const OutlineInputBorder(),
                          ),
                          items: _branches.isEmpty && _selectedBranch != null
                              ? [
                                  DropdownMenuItem(
                                    value: _selectedBranch,
                                    child: Text(_selectedBranch!),
                                  ),
                                ]
                              : _branches
                                  .map(
                                    (branch) => DropdownMenuItem(
                                      value: branch,
                                      child: Text(branch),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedBranch = value);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          strings.syncMode,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: syncModeMinimal,
                              label: Text('Minimal'),
                            ),
                            ButtonSegment(
                              value: syncModeLatest,
                              label: Text('500'),
                            ),
                            ButtonSegment(
                              value: syncModeExtended,
                              label: Text('5000'),
                            ),
                          ],
                          selected: {_syncMode},
                          onSelectionChanged: (selected) {
                            setState(() => _syncMode = selected.first);
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _syncModeDescription,
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (_syncMode != syncModeMinimal)
                          Text(
                            strings.largeSyncWarning,
                            style: const TextStyle(fontSize: 12),
                          ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _isAdding ? null : _addRepo,
                          icon: _isAdding
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.add),
                          label: Text(strings.add),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<List<Commit>> _fetchInitialCommits(
    String owner,
    String repo,
    String branch,
  ) {
    if (_syncMode == syncModeLatest) {
      return _github.fetchCommitsWithLimit(
        owner,
        repo,
        branch,
        latestSyncCommitLimit,
      );
    }

    if (_syncMode == syncModeExtended) {
      return _github.fetchCommitsWithLimit(
        owner,
        repo,
        branch,
        extendedSyncCommitLimit,
      );
    }

    return _github.fetchLatestDayCommits(owner, repo, branch);
  }

  String get _syncModeDescription {
    final strings = stringsFor(appSettingsController.value.languageCode);

    if (_syncMode == syncModeLatest) {
      return strings.latestSyncDescription;
    }

    if (_syncMode == syncModeExtended) {
      return strings.extendedSyncDescription;
    }

    return strings.minimalSyncDescription;
  }
}
