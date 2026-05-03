import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/commit.dart';
import '../models/watched_repo.dart';
import '../services/github_service.dart';

class DetailScreen extends StatefulWidget {
  final WatchedRepo repo;

  const DetailScreen({super.key, required this.repo});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final GitHubService _github = GitHubService();
  final DateFormat _dayFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _timeFormat = DateFormat('HH:mm');

  List<Commit> _commits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCommits();
  }

  Future<void> _loadCommits() async {
    setState(() => _isLoading = true);
    try {
      final commits = await _github.fetchCommits(widget.repo.owner, widget.repo.repo);
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

  @override
  Widget build(BuildContext context) {
    final groupedCommits = _groupCommitsByDate();

    return Scaffold(
      appBar: AppBar(title: Text(widget.repo.fullName)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadCommits,
                child: _commits.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 240),
                          Center(child: Text('Belum ada commit')),
                        ],
                      )
                    : ListView.builder(
                        itemCount: groupedCommits.length,
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
                              ...group.value.map((commit) {
                                final shortSha = commit.sha.length >= 7
                                    ? commit.sha.substring(0, 7)
                                    : commit.sha;

                                return Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      commit.message,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        '$shortSha - ${_timeFormat.format(commit.date.toLocal())}',
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          );
                        },
                      ),
              ),
      ),
    );
  }

  Map<String, List<Commit>> _groupCommitsByDate() {
    final grouped = <String, List<Commit>>{};

    for (final commit in _commits) {
      final key = _dayFormat.format(commit.date.toLocal());
      grouped.putIfAbsent(key, () => []).add(commit);
    }

    return grouped;
  }
}
