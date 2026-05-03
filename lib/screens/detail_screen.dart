import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/commit.dart';
import '../models/watched_repo.dart';
import '../services/github_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

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
      appBar: AppBar(title: Text(widget.repo.fullName)),
      body: Padding(
        padding: const EdgeInsets.all(16),
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
                          : ListView.builder(
                              itemCount: groupedCommits.length,
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
    final shortSha = commit.sha.length >= 7
        ? commit.sha.substring(0, 7)
        : commit.sha;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          commit.title.isEmpty ? commit.message : commit.title,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text('$shortSha - ${_timeFormat.format(commit.date.toLocal())}'),
        ),
        onTap: () => _showCommitDetail(commit),
      ),
    );
  }

  void _showCommitDetail(Commit commit) {
    final shortSha = commit.sha.length >= 7
        ? commit.sha.substring(0, 7)
        : commit.sha;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(shortSha),
        content: SingleChildScrollView(
          child: SelectableText(commit.message),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
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
        latestSyncCommitLimit,
      );
    }

    if (widget.repo.syncMode == syncModeExtended) {
      return _github.fetchCommitsWithLimit(
        widget.repo.owner,
        widget.repo.repo,
        extendedSyncCommitLimit,
      );
    }

    return _github.fetchLatestDayCommits(widget.repo.owner, widget.repo.repo);
  }
}
