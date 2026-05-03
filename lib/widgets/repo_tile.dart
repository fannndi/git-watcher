import 'package:flutter/material.dart';

import '../models/watched_repo.dart';

class RepoTile extends StatelessWidget {
  final WatchedRepo repo;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const RepoTile({
    super.key,
    required this.repo,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          repo.fullName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('Branch: ${repo.branch}'),
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          child: const Icon(Icons.code),
        ),
        trailing: IconButton(
          tooltip: 'Hapus repo',
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
        onTap: onTap,
      ),
    );
  }
}
