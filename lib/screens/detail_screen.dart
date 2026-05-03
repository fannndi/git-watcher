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
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

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
                        itemCount: _commits.length,
                        itemBuilder: (context, index) {
                          final commit = _commits[index];
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
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '$shortSha - ${_dateFormat.format(commit.date.toLocal())}',
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
      ),
    );
  }
}
