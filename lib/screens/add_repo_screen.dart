import 'package:flutter/material.dart';

import '../models/watched_repo.dart';
import '../services/app_settings_controller.dart';
import '../services/github_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/strings.dart';
import '../widgets/chips.dart';

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

  AppStrings get _strings =>
      stringsFor(appSettingsController.value.languageCode);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkRepo() async {
    final input = _controller.text.trim();
    final strings = _strings;

    setState(() {
      _foundRepo = null;
      _branches = [];
      _selectedBranch = null;
    });

    if (input.isEmpty) {
      _showError(strings.emptyRepositoryInput);
      return;
    }

    final parts = input.split('/');
    if (parts.length != 2 || parts.any((part) => part.trim().isEmpty)) {
      _showError(strings.invalidRepositoryFormat);
      return;
    }

    final owner = parts[0].trim();
    final repo = parts[1].trim();

    if ((await _storage.getRepos()).length >= maxWatchedRepos) {
      if (mounted) _showError(strings.maxRepos);
      return;
    }

    setState(() => _isChecking = true);
    try {
      final found = await _github.getRepo(owner, repo);
      if (!mounted) return;
      if (found == null) {
        _showError(strings.repositoryNotFound);
        return;
      }

      final branches = await _github.fetchBranches(owner, repo);
      if (!mounted) return;

      final defaultBranch = found['default_branch'] as String? ?? 'main';
      setState(() {
        _foundRepo = found;
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
      if (mounted) _showError(strings.connectionFailed);
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _addRepo() async {
    final owner = _owner;
    final repo = _repo;
    final branch = _selectedBranch;
    final found = _foundRepo;
    if (owner == null || repo == null || branch == null || found == null) {
      return;
    }

    final strings = _strings;
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
        if (mounted) _showError(strings.duplicateRepository);
        return;
      }

      final commits =
          await _github.fetchCommitsForMode(owner, repo, branch, _syncMode);
      final newRepo = WatchedRepo(
        owner: owner,
        repo: repo,
        branch: branch,
        syncMode: _syncMode,
        avatarUrl: _avatarUrl(found),
        isPrivate: found['private'] == true,
        lastCommitAt: commits.isEmpty ? null : commits.first.date,
        lastSha: commits.isEmpty ? '' : commits.first.sha,
      );

      await _storage.saveRepos([...existing, newRepo]);
      await _storage.saveCachedCommits(newRepo, commits);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) _showError(strings.addRepositoryFailed);
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _avatarUrl(Map<String, dynamic> repo) {
    final owner = repo['owner'];
    if (owner is Map<String, dynamic>) {
      return owner['avatar_url'] as String? ?? '';
    }
    return '';
  }

  String? _description(Map<String, dynamic> repo) {
    final description = repo['description'] as String?;
    return description == null || description.isEmpty ? null : description;
  }

  String? _language(Map<String, dynamic> repo) {
    return repo['language'] as String?;
  }

  int? _stars(Map<String, dynamic> repo) {
    return (repo['stargazers_count'] as num?)?.toInt();
  }

  String get _syncModeDescription {
    final strings = _strings;
    if (_syncMode == syncModeLatest) {
      return strings.latestSyncDescription;
    }
    if (_syncMode == syncModeExtended) {
      return strings.extendedSyncDescription;
    }
    return strings.minimalSyncDescription;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: appSettingsController,
      builder: (context, settings, _) {
        final strings = stringsFor(settings.languageCode);
        final foundRepo = _foundRepo;

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
                          '${strings.defaultBranch}: '
                          '${foundRepo['default_branch'] ?? 'main'}',
                        ),
                        if (_description(foundRepo) != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _description(foundRepo)!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            InfoChip(
                              icon: foundRepo['private'] == true
                                  ? Icons.lock_outline
                                  : Icons.public,
                              label: foundRepo['private'] == true
                                  ? strings.privateRepo
                                  : strings.publicRepo,
                              accent: foundRepo['private'] != true,
                            ),
                            if (_language(foundRepo) != null)
                              InfoChip(
                                icon: Icons.code,
                                label: _language(foundRepo)!,
                              ),
                            if (_stars(foundRepo) != null)
                              InfoChip(
                                icon: Icons.star_outline,
                                label: strings.stars(_stars(foundRepo)!),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedBranch,
                          decoration: InputDecoration(
                            labelText: strings.watchedBranch,
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
}
