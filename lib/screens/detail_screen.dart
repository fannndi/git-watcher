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
import '../widgets/skeleton.dart';
import '../widgets/sliver_date_header.dart';

enum CommitRange { all, today, week }

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
  CommitRange _range = CommitRange.all;
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
    final now = DateTime.now();
    final query = _query.toLowerCase();

    return _commits.where((commit) {
      if (query.isNotEmpty &&
          !commit.message.toLowerCase().contains(query) &&
          !commit.sha.toLowerCase().contains(query)) {
        return false;
      }

      final local = commit.date.toLocal();
      switch (_range) {
        case CommitRange.all:
          return true;
        case CommitRange.today:
          return local.year == now.year &&
              local.month == now.month &&
              local.day == now.day;
        case CommitRange.week:
          return now.difference(local).inDays < 7;
      }
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
            duration: const Duration(milliseconds: 300),
            child: _isLoading
                ? _buildSkeleton()
                : _hasError
                    ? _buildErrorState(strings)
                    : _buildContent(strings),
          ),
        );
      },
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      key: const ValueKey('loading'),
      padding: const EdgeInsets.all(16),
      children: const [
        Skeleton(child: SkeletonBox(width: double.infinity, height: 52)),
        SizedBox(height: 16),
        Skeleton(child: SkeletonCommitCard()),
        SizedBox(height: 10),
        Skeleton(child: SkeletonCommitCard()),
        SizedBox(height: 10),
        Skeleton(child: SkeletonCommitCard()),
      ],
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
            FilledButton.icon(
              onPressed: _loadCommits,
              icon: const Icon(Icons.refresh),
              label: Text(strings.tryAgain),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AppStrings strings) {
    final groupedCommits = _groupCommitsByDate(_filteredCommits);

    return RefreshIndicator(
      key: const ValueKey('content'),
      onRefresh: _refreshCommits,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: SearchBar(
                controller: _searchController,
                hintText: strings.searchCommit,
                leading: const Icon(Icons.search),
                trailing: _query.isEmpty
                    ? null
                    : [
                        IconButton(
                          tooltip: strings.clearSearch,
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                      ],
                elevation: const WidgetStatePropertyAll(0),
                onChanged: (value) => setState(() => _query = value.trim()),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(strings.filterAll),
                    selected: _range == CommitRange.all,
                    onSelected: (_) => setState(() => _range = CommitRange.all),
                  ),
                  ChoiceChip(
                    label: Text(strings.filterToday),
                    selected: _range == CommitRange.today,
                    onSelected: (_) =>
                        setState(() => _range = CommitRange.today),
                  ),
                  ChoiceChip(
                    label: Text(strings.filterWeek),
                    selected: _range == CommitRange.week,
                    onSelected: (_) =>
                        setState(() => _range = CommitRange.week),
                  ),
                ],
              ),
            ),
          ),
          if (groupedCommits.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text(strings.commitNotFound)),
            )
          else
            for (final entry in groupedCommits.entries) ...[
              SliverPersistentHeader(
                pinned: true,
                delegate: SliverDateHeaderDelegate(entry.key),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                sliver: SliverList.separated(
                  itemCount: entry.value.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final commit = entry.value[index];
                    return CommitCard(
                      commit: commit,
                      index: index,
                      onTap: () => _showCommitDetail(commit),
                      onCopySha: () => _copySha(commit.sha),
                    );
                  },
                ),
              ),
            ],
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
