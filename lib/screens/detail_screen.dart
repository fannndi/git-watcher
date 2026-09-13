import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_settings.dart';
import '../models/commit.dart';
import '../models/watched_repo.dart';
import '../services/app_settings_controller.dart';
import '../services/github_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/strings.dart';
import '../widgets/chips.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.repo});

  final WatchedRepo repo;

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
  bool _hasError = false;

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
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      var commits = await _storage.getCachedCommits(widget.repo);
      if (commits.isEmpty) {
        commits = await _fetchByMode();
        await _storage.saveCachedCommits(widget.repo, commits);
      }

      if (!mounted) return;
      setState(() {
        _commits = commits;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _refreshCommits() async {
    try {
      final commits = await _fetchByMode();
      await _storage.saveCachedCommits(widget.repo, commits);
      if (!mounted) return;
      setState(() {
        _commits = commits;
        _hasError = false;
      });
    } catch (_) {
      if (!mounted) return;
      final strings = stringsFor(appSettingsController.value.languageCode);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.fetchCommitsFailed)),
      );
    }
  }

  Future<List<Commit>> _fetchByMode() {
    return _github.fetchCommitsForMode(
      widget.repo.owner,
      widget.repo.repo,
      widget.repo.branch,
      widget.repo.syncMode,
    );
  }

  Future<void> _openUrl(Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      final strings = stringsFor(appSettingsController.value.languageCode);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.openLinkFailed)),
      );
    }
  }

  List<Commit> get _filteredCommits {
    if (_query.isEmpty) {
      return _commits;
    }

    final query = _query.toLowerCase();
    return _commits
        .where(
          (commit) =>
              commit.message.toLowerCase().contains(query) ||
              commit.sha.toLowerCase().contains(query),
        )
        .toList();
  }

  Map<String, List<Commit>> _groupCommitsByDate(List<Commit> commits) {
    final grouped = <String, List<Commit>>{};
    for (final commit in commits) {
      final key = _dayFormat.format(commit.date.toLocal());
      grouped.putIfAbsent(key, () => []).add(commit);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppSettings>(
      valueListenable: appSettingsController,
      builder: (context, settings, _) {
        final strings = stringsFor(settings.languageCode);
        final groupedCommits = _groupCommitsByDate(_filteredCommits);

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
            actions: [
              IconButton(
                tooltip: strings.shareRepo,
                icon: const Icon(Icons.open_in_new),
                onPressed: () => _openUrl(
                  Uri.https(
                    githubWebHost,
                    '/${widget.repo.fullName}/tree/${widget.repo.branch}',
                  ),
                ),
              ),
            ],
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _isLoading
                ? const Center(
                    key: ValueKey('loading'),
                    child: CircularProgressIndicator(),
                  )
                : _hasError
                    ? _buildErrorState(strings)
                    : _buildContent(strings, groupedCommits),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(AppStrings strings) {
    return Center(
      key: const ValueKey('error'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              strings.fetchCommitsFailed,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadCommits,
              icon: const Icon(Icons.refresh),
              label: Text(strings.tryAgain),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    AppStrings strings,
    Map<String, List<Commit>> groupedCommits,
  ) {
    return Padding(
      key: const ValueKey('content'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: strings.clearSearch,
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
              labelText: strings.searchCommit,
              helperText: strings.searchCommitHelper,
            ),
            onChanged: (value) => setState(() => _query = value.trim()),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshCommits,
              child: groupedCommits.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 220),
                        Center(child: Text(strings.commitNotFound)),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: groupedCommits.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final group =
                            groupedCommits.entries.elementAt(index);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(4, 16, 4, 8),
                              child: Text(
                                group.key,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            for (var i = 0; i < group.value.length; i++)
                              _buildCommitCard(group.value[i], i),
                          ],
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommitCard(Commit commit, int index) {
    final colorScheme = Theme.of(context).colorScheme;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 80).clamp(0, 400)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Card(
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
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          InfoChip(
                            icon: Icons.tag_outlined,
                            label: _shortSha(commit.sha),
                          ),
                          InfoChip(
                            icon: Icons.schedule_outlined,
                            label: _timeFormat.format(commit.date.toLocal()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCommitDetail(Commit commit) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CommitDetailSheet(
        repo: widget.repo,
        commit: commit,
        github: _github,
      ),
    );
  }

  String _shortSha(String sha) => sha.length >= 7 ? sha.substring(0, 7) : sha;
}

class _CommitDetailSheet extends StatefulWidget {
  const _CommitDetailSheet({
    required this.repo,
    required this.commit,
    required this.github,
  });

  final WatchedRepo repo;
  final Commit commit;
  final GitHubService github;

  @override
  State<_CommitDetailSheet> createState() => _CommitDetailSheetState();
}

class _CommitDetailSheetState extends State<_CommitDetailSheet> {
  late Future<CommitDetail> _future = _load();

  Future<CommitDetail> _load() {
    return widget.github.fetchCommitDetail(
      widget.repo.owner,
      widget.repo.repo,
      widget.commit.sha,
    );
  }

  void _retry() {
    setState(() => _future = _load());
  }

  Future<void> _openCommitInBrowser() async {
    final strings = stringsFor(appSettingsController.value.languageCode);
    final uri = Uri.https(
      githubWebHost,
      '/${widget.repo.owner}/${widget.repo.repo}/commit/${widget.commit.sha}',
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.openLinkFailed)),
      );
    }
  }

  TextSpan _formatMessage(String message, BuildContext context) {
    final lines = message.split('\n');
    final spans = <TextSpan>[
      TextSpan(
        text: lines.first,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    ];

    if (lines.length > 1) {
      spans.add(
        TextSpan(
          text: '\n${lines.sublist(1).join('\n')}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    final strings = stringsFor(appSettingsController.value.languageCode);
    final shortSha = widget.commit.sha.length >= 7
        ? widget.commit.sha.substring(0, 7)
        : widget.commit.sha;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.76,
      minChildSize: 0.4,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return FutureBuilder<CommitDetail>(
          future: _future,
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
                      tooltip: strings.close,
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText.rich(
                  _formatMessage(widget.commit.message, context),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _openCommitInBrowser,
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
                  _CommitDetailError(onRetry: _retry)
                else
                  _CommitFileSummary(detail: snapshot.requireData),
              ],
            );
          },
        );
      },
    );
  }
}

class _CommitFileSummary extends StatelessWidget {
  const _CommitFileSummary({required this.detail});

  final CommitDetail detail;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final strings = stringsFor(appSettingsController.value.languageCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                strings.changedFiles(detail.files.length),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            InfoChip(label: '+${detail.additions}', color: Colors.green),
            const SizedBox(width: 8),
            InfoChip(label: '-${detail.deletions}', color: colorScheme.error),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            InfoChip(
              icon: Icons.add,
              label: '+${detail.additions}',
              color: Colors.green,
            ),
            const SizedBox(width: 8),
            InfoChip(
              icon: Icons.remove,
              label: '-${detail.deletions}',
              color: colorScheme.error,
            ),
            const SizedBox(width: 8),
            InfoChip(
              icon: Icons.folder,
              label: '${detail.files.length} files',
              color: colorScheme.primary,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (detail.files.isEmpty)
          Text(
            strings.noFileDetail,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          )
        else
          ...detail.files.map((file) => _CommitFileTile(file: file)),
      ],
    );
  }
}

class _CommitFileTile extends StatelessWidget {
  const _CommitFileTile({required this.file});

  final CommitFile file;

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
            InfoChip(label: '+${file.additions}', color: Colors.green),
            const SizedBox(width: 6),
            InfoChip(label: '-${file.deletions}', color: colorScheme.error),
          ],
        ),
      ),
    );
  }
}

class _CommitDetailError extends StatelessWidget {
  const _CommitDetailError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = stringsFor(appSettingsController.value.languageCode);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 36),
          const SizedBox(height: 10),
          Text(strings.fetchCommitDetailFailed),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(strings.tryAgain),
          ),
        ],
      ),
    );
  }
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
