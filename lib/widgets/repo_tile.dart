import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/watched_repo.dart';
import '../services/app_settings_controller.dart';
import '../utils/strings.dart';

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
    final avatarUrl = repo.avatarUrl.isEmpty
        ? 'https://github.com/${repo.owner}.png?size=96'
        : repo.avatarUrl;
    final strings = stringsFor(appSettingsController.value.languageCode);

    return Card(
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.network(
                  avatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.code,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        repo.fullName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _RepoChip(
                          label: '${strings.branch}: ${repo.branch}',
                          icon: Icons.account_tree_outlined,
                        ),
                        _RepoChip(
                          label: repo.isPrivate
                              ? strings.privateRepo
                              : strings.publicRepo,
                          icon: repo.isPrivate
                              ? Icons.lock_outline
                              : Icons.public_outlined,
                        ),
                        _RepoChip(
                          label:
                              '${strings.lastUpdate}: ${_formatLastUpdate(repo.lastCommitAt, strings)}',
                          icon: Icons.update_outlined,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: strings.deleteRepo,
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatLastUpdate(DateTime? date, AppStrings strings) {
    if (date == null) {
      return strings.neverSynced;
    }

    final localDate = date.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final commitDay = DateTime(localDate.year, localDate.month, localDate.day);

    if (commitDay == today) {
      return strings.today;
    }

    return DateFormat('dd-MM-yyyy').format(localDate);
  }
}

class _RepoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _RepoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
