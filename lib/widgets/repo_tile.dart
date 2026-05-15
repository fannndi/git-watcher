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
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _RepoAvatar(repo: repo, colorScheme: colorScheme),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${repo.owner} / ',
                                    style: textTheme.titleMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15,
                                    ),
                                  ),
                                  TextSpan(
                                    text: repo.repo,
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: colorScheme.error.withValues(alpha: 0.8),
                            ),
                            tooltip: 'Hapus repo',
                            onPressed: onDelete,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Flexible(
                          child: _Chip(
                            icon: Icons.call_split,
                            label: repo.branch,
                            colorScheme: colorScheme,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _Chip(
                          icon: repo.isPrivate ? Icons.lock_outline : Icons.public,
                          label: repo.isPrivate ? 'Private' : 'Public',
                          colorScheme: colorScheme,
                          isAccent: !repo.isPrivate,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(Icons.history, size: 14, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            repo.lastCommitAt != null
                                ? '${_formatDate(repo.lastCommitAt!)} • ${repo.lastSha.length >= 7 ? repo.lastSha.substring(0, 7) : repo.lastSha}'
                                : 'Belum tersinkron',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

class _RepoAvatar extends StatelessWidget {
  final WatchedRepo repo;
  final ColorScheme colorScheme;

  const _RepoAvatar({required this.repo, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final url = repo.avatarUrl.isNotEmpty
        ? repo.avatarUrl
        : 'https://github.com/${repo.owner}.png?size=88';

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: 38,
        height: 38,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.code,
        size: 22,
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colorScheme;
  final bool isAccent;

  const _Chip({
    required this.icon,
    required this.label,
    required this.colorScheme,
    this.isAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isAccent
        ? colorScheme.secondaryContainer.withValues(alpha: 0.5)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);
    final fg = isAccent
        ? colorScheme.onSecondaryContainer
        : colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: fg,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
