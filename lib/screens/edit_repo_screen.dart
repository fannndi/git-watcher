import 'package:flutter/material.dart';

import '../models/watched_repo.dart';
import '../services/app_settings_controller.dart';
import '../services/github_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/strings.dart';

class EditRepoScreen extends StatefulWidget {
  const EditRepoScreen({super.key, required this.repo});

  final WatchedRepo repo;

  @override
  State<EditRepoScreen> createState() => _EditRepoScreenState();
}

class _EditRepoScreenState extends State<EditRepoScreen> {
  final GitHubService _github = GitHubService();
  final StorageService _storage = StorageService();

  List<String> _branches = [];
  String? _selectedBranch;
  String _syncMode = syncModeMinimal;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  AppStrings get _strings =>
      stringsFor(appSettingsController.value.languageCode);

  @override
  void initState() {
    super.initState();
    _selectedBranch = widget.repo.branch;
    _syncMode = widget.repo.syncMode;
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final branches = await _github.fetchBranches(
        widget.repo.owner,
        widget.repo.repo,
      );
      if (!mounted) return;
      setState(() {
        _branches = branches;
        if (!branches.contains(_selectedBranch)) {
          _selectedBranch =
              branches.isEmpty ? widget.repo.branch : branches.first;
        }
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = _strings.connectionFailed;
      });
    }
  }

  Future<void> _save() async {
    final branch = _selectedBranch;
    if (branch == null) return;

    setState(() => _isSaving = true);
    try {
      final oldRepo = widget.repo;
      final commits = await _github.fetchCommitsForMode(
        oldRepo.owner,
        oldRepo.repo,
        branch,
        _syncMode,
      );
      final updated = WatchedRepo(
        owner: oldRepo.owner,
        repo: oldRepo.repo,
        branch: branch,
        syncMode: _syncMode,
        avatarUrl: oldRepo.avatarUrl,
        isPrivate: oldRepo.isPrivate,
        muted: oldRepo.muted,
        lastCommitAt: commits.isEmpty ? null : commits.first.date,
        lastSha: commits.isEmpty ? '' : commits.first.sha,
      );

      await _storage.saveCachedCommits(updated, commits);
      if (branch != oldRepo.branch || _syncMode != oldRepo.syncMode) {
        await _storage.removeCachedCommits(oldRepo);
      }
      await _storage.replaceRepo(updated);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_strings.addRepositoryFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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

        return Scaffold(
          appBar: AppBar(title: Text(strings.editRepo)),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.repo.fullName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _error!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: _loadBranches,
                                icon: const Icon(Icons.refresh),
                                label: Text(strings.tryAgain),
                              ),
                            ],
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedBranch,
                              decoration: InputDecoration(
                                labelText: strings.watchedBranch,
                              ),
                              items: [
                                for (final branch in {
                                  widget.repo.branch,
                                  ..._branches,
                                })
                                  DropdownMenuItem(
                                    value: branch,
                                    child: Text(branch),
                                  ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedBranch = value);
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            Text(
                              strings.syncMode,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
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
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _isSaving ? null : _save,
                                icon: _isSaving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.save_outlined),
                                label: Text(strings.saveCredentials),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
