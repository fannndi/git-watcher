import 'package:flutter/material.dart';

import '../models/watched_repo.dart';

class RepoTile extends StatefulWidget {
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
  State<RepoTile> createState() => _RepoTileState();
}

class _RepoTileState extends State<RepoTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) => _controller.reverse(),
          onTapCancel: () => _controller.reverse(),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _RepoAvatar(repo: widget.repo, colorScheme: colorScheme),
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
                                      text: '${widget.repo.owner} / ',
                                      style: textTheme.titleMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    TextSpan(
                                      text: widget.repo.repo,
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w900,
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
                          const SizedBox(width: 4),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: widget.onDelete,
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: colorScheme.error.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Flexible(
                            child: _Chip(
                              icon: Icons.call_split,
                              label: widget.repo.branch,
                              colorScheme: colorScheme,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _Chip(
                            icon: widget.repo.isPrivate ? Icons.lock_outline : Icons.public,
                            label: widget.repo.isPrivate ? 'Private' : 'Public',
                            colorScheme: colorScheme,
                            isAccent: !widget.repo.isPrivate,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.history, size: 14, color: colorScheme.primary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.repo.lastCommitAt != null
                                    ? '${_formatDate(widget.repo.lastCommitAt!)} • ${widget.repo.lastSha.length >= 7 ? widget.repo.lastSha.substring(0, 7) : widget.repo.lastSha}'
                                    : 'Belum tersinkron',
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
