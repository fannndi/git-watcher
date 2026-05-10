import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/commit.dart';
import '../models/watched_repo.dart';
import '../services/github_service.dart';
import '../services/storage_service.dart';
import '../services/app_settings_controller.dart';
import '../utils/constants.dart';
import '../utils/strings.dart';

class DetailScreen extends StatefulWidget {
  final WatchedRepo repo;

  const DetailScreen({super.key, required this.repo});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final GitHubService _github = GitHubService();
  final StorageService _storage = StorageService();
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dayFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _timeFormat = DateFormat('HH:mm');

  List<Commit> _commits = [];
  String _query = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCommits();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCommits() async {
    setState(() => _isLoading = true);
    try {
      var commits = await _storage.getCachedCommits(widget.repo);
      if (commits.isEmpty) {
        commits = await _fetchCommitsByMode();
        await _storage.saveCachedCommits(widget.repo, commits);
      }

      if (!mounted) return;
      setState(() {
        _commits = commits;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengambil commit terbaru')),
      );
    }
  }

  Future<void> _refreshCommits() async {
    final commits = await _fetchCommitsByMode();
    await _storage.saveCachedCommits(widget.repo, commits);
    if (!mounted) return;
    setState(() => _commits = commits);
  }

  @override
  Widget build(BuildContext context) {
    final filteredCommits = _filteredCommits();
    final groupedCommits = _groupCommitsByDate(filteredCommits);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.repo.fullName),
            Text(
              widget.repo.branch,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Bersihkan pencarian',
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            ),
                      labelText: 'Cari commit',
                      helperText: 'Cari berdasarkan message atau SHA',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() => _query = value.trim()),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _refreshCommits,
                      child: filteredCommits.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 220),
                                Center(child: Text('Commit tidak ditemukan')),
                              ],
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.only(bottom: 24),
                              itemCount: groupedCommits.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 4),
                              itemBuilder: (context, index) {
                                final group =
                                    groupedCommits.entries.elementAt(index);

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          4, 16, 4, 8),
                                      child: Text(
                                        group.key,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ),
                                    ...group.value.map(_buildCommitCard),
                                  ],
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCommitCard(Commit commit) {
    final shortSha =
        commit.sha.length >= 7 ? commit.sha.substring(0, 7) : commit.sha;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showCommitDetail(commit),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.commit_outlined,
                  color: colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      commit.title.isEmpty ? commit.message : commit.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _MetaChip(
                          icon: Icons.tag_outlined,
                          label: shortSha,
                        ),
                        _MetaChip(
                          icon: Icons.schedule_outlined,
                          label: _timeFormat.format(commit.date.toLocal()),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCommitDetail(Commit commit) {
    final shortSha =
        commit.sha.length >= 7 ? commit.sha.substring(0, 7) : commit.sha;
    final strings = stringsFor(appSettingsController.value.languageCode);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.76,
        minChildSize: 0.4,
        maxChildSize: 0.94,
        builder: (context, scrollController) {
          return FutureBuilder<CommitDetail>(
            future: _github.fetchCommitDetail(
              widget.repo.owner,
              widget.repo.repo,
              commit.sha,
            ),
            builder: (context, snapshot) {
              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          shortSha,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Tutup',
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    commit.message,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () => _openCommitUrl(commit),
                    icon: const Icon(Icons.open_in_browser_outlined),
                    label: Text(strings.seeDetail),
                  ),
                  const SizedBox(height: 18),
                  if (snapshot.connectionState != ConnectionState.done)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (snapshot.hasError)
                    _CommitDetailError(onRetry: () => setState(() {}))
                  else
                    _CommitFileSummary(detail: snapshot.requireData),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openCommitUrl(Commit commit) async {
    final strings = stringsFor(appSettingsController.value.languageCode);
    final uri = Uri.https(
      'github.com',
      '/${widget.repo.owner}/${widget.repo.repo}/commit/${commit.sha}',
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.openLinkFailed)),
      );
    }
  }

  List<Commit> _filteredCommits() {
    if (_query.isEmpty) {
      return _commits;
    }

    final query = _query.toLowerCase();
    return _commits.where((commit) {
      return commit.message.toLowerCase().contains(query) ||
          commit.sha.toLowerCase().contains(query);
    }).toList();
  }

  Map<String, List<Commit>> _groupCommitsByDate(List<Commit> commits) {
    final grouped = <String, List<Commit>>{};

    for (final commit in commits) {
      final key = _dayFormat.format(commit.date.toLocal());
      grouped.putIfAbsent(key, () => []).add(commit);
    }

    return grouped;
  }

  Future<List<Commit>> _fetchCommitsByMode() {
    if (widget.repo.syncMode == syncModeLatest) {
      return _github.fetchCommitsWithLimit(
        widget.repo.owner,
        widget.repo.repo,
        widget.repo.branch,
        latestSyncCommitLimit,
      );
    }

    if (widget.repo.syncMode == syncModeExtended) {
      return _github.fetchCommitsWithLimit(
        widget.repo.owner,
        widget.repo.repo,
        widget.repo.branch,
        extendedSyncCommitLimit,
      );
    }

    return _github.fetchLatestDayCommits(
      widget.repo.owner,
      widget.repo.repo,
      widget.repo.branch,
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _CommitFileSummary extends StatelessWidget {
  final CommitDetail detail;

  const _CommitFileSummary({required this.detail});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${detail.files.length} file berubah',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            _ChangePill(
              label: '+${detail.additions}',
              color: Colors.green,
            ),
            const SizedBox(width: 8),
            _ChangePill(
              label: '-${detail.deletions}',
              color: colorScheme.error,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (detail.files.isEmpty)
          Text(
            'Tidak ada detail file dari GitHub API.',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          )
        else
          ...detail.files.map((file) => _CommitFileTile(file: file)),
      ],
    );
  }
}

class _CommitFileTile extends StatelessWidget {
  final CommitFile file;

  const _CommitFileTile({required this.file});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              _statusIcon(file.status),
              color: _statusColor(file.status, colorScheme),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.filename,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    file.status,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _ChangePill(label: '+${file.additions}', color: Colors.green),
            const SizedBox(width: 6),
            _ChangePill(label: '-${file.deletions}', color: colorScheme.error),
          ],
        ),
      ),
    );
  }

  IconData _statusIcon(String status) {
    return switch (status) {
      'added' => Icons.add_circle_outline,
      'removed' => Icons.remove_circle_outline,
      'renamed' => Icons.drive_file_rename_outline,
      _ => Icons.edit_outlined,
    };
  }

  Color _statusColor(String status, ColorScheme colorScheme) {
    return switch (status) {
      'added' => Colors.green,
      'removed' => colorScheme.error,
      'renamed' => colorScheme.tertiary,
      _ => colorScheme.primary,
    };
  }
}

class _ChangePill extends StatelessWidget {
  final String label;
  final Color color;

  const _ChangePill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CommitDetailError extends StatelessWidget {
  final VoidCallback onRetry;

  const _CommitDetailError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 36),
          const SizedBox(height: 10),
          const Text('Gagal mengambil detail file commit.'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}
