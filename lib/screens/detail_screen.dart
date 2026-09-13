import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../widgets/commit_card.dart';
import '../widgets/commit_detail_sheet.dart';

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
      final fresh = await _github.fetchCommits(
        widget.repo.owner,
        widget.repo.repo,
        widget.repo.branch,
      );
      await _storage.mergeCachedCommits(widget.repo, fresh);
      final commits = await _storage.getCachedCommits(widget.repo);
      if (!mounted) return;
      setState(() {
        _commits = commits;
        _hasError = false;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            stringsFor(appSettingsController.value.languageCode)
                .fetchCommitsFailed,
          ),
        ),
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

  Future<void> _copySha(String sha) async {
    await Clipboard.setData(ClipboardData(text: sha));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          stringsFor(appSettingsController.value.languageCode).shaCopied,
        ),
      ),
    );
  }

  Future<void> _openRepo() async {
    final opened = await launchUrl(
      Uri.https(
        githubWebHost,
        '/${widget.repo.fullName}/tree/${widget.repo.branch}',
      ),
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            stringsFor(appSettingsController.value.languageCode).openLinkFailed,
          ),
        ),
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

  void _showCommitDetail(Commit commit) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => CommitDetailSheet(
        repo: widget.repo,
        commit: commit,
        github: _github,
      ),
    );
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
                  _isLoading
                      ? widget.repo.branch
                      : '${widget.repo.branch} • '
                          '${strings.commitCount(_commits.length)}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: strings.shareRepo,
                icon: const Icon(Icons.open_in_new),
                onPressed: _openRepo,
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
                        final group = groupedCommits.entries.elementAt(index);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                              child: Text(
                                group.key,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            for (var i = 0; i < group.value.length; i++)
                              CommitCard(
                                commit: group.value[i],
                                index: i,
                                onTap: () => _showCommitDetail(group.value[i]),
                                onCopySha: () => _copySha(group.value[i].sha),
                              ),
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
}
