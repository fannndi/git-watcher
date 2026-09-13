import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/watched_repo.dart';
import '../services/app_settings_controller.dart';
import '../utils/constants.dart';
import '../utils/strings.dart';
import 'chips.dart';

class RepoTile extends StatefulWidget {
  const RepoTile({
    super.key,
    required this.repo,
    required this.onTap,
    required this.onDelete,
  });

  final WatchedRepo repo;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  State<RepoTile> createState() => _RepoTileState();
}

class _RepoTileState extends State<RepoTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
  );
  late final Animation<double> _scale = Tween<double>(begin: 1.0, end: 0.97)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final strings = stringsFor(appSettingsController.value.languageCode);

    return ScaleTransition(
      scale: _scale,
      child: Card(
        clipBehavior: Clip.hardEdge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: InkWell(
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) => _controller.reverse(),
          onTapCancel: () => _controller.reverse(),
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
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
                                child: Tooltip(
                                  message: strings.delete,
                                  child: Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: colorScheme.error
                                        .withValues(alpha: 0.7),
                                  ),
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
                            child: InfoChip(
                              icon: Icons.call_split,
                              label: widget.repo.branch,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InfoChip(
                            icon: widget.repo.isPrivate
                                ? Icons.lock_outline
                                : Icons.public,
                            label: widget.repo.isPrivate
                                ? strings.privateRepo
                                : strings.publicRepo,
                            accent: !widget.repo.isPrivate,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.history,
                              size: 14,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.repo.lastCommitAt == null
                                    ? strings.notSynced
                                    : '${strings.timeAgo(widget.repo.lastCommitAt!)} • ${_shortSha(widget.repo.lastSha)}',
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
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.repo.syncMode != syncModeMinimal)
                      InfoChip(
                        label: widget.repo.syncMode == syncModeExtended
                            ? '5000'
                            : '500',
                        color: colorScheme.primary,
                      ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _shortSha(String sha) => sha.length >= 7 ? sha.substring(0, 7) : sha;
}

class _RepoAvatar extends StatelessWidget {
  const _RepoAvatar({required this.repo, required this.colorScheme});

  final WatchedRepo repo;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final url = repo.avatarUrl.isNotEmpty
        ? repo.avatarUrl
        : 'https://$githubWebHost/${repo.owner}.png?size=88';

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: 38,
        height: 38,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
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
        ),
      ),
    );
  }
}
