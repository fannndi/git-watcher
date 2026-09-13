import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/strings.dart';

class HomeSyncBar extends StatelessWidget {
  const HomeSyncBar({
    super.key,
    required this.strings,
    required this.lastSyncAt,
    required this.isSyncing,
    required this.completed,
    required this.total,
    this.slotLabel,
  });

  final AppStrings strings;
  final DateTime? lastSyncAt;
  final bool isSyncing;
  final int completed;
  final int total;
  final String? slotLabel;

  static final DateFormat _format = DateFormat('yyyy-MM-dd HH:mm');

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final text = isSyncing && total > 0
        ? '${strings.syncing} $completed/$total'
        : '${strings.lastSync}: '
            '${lastSyncAt == null ? strings.never : _format.format(lastSyncAt!.toLocal())}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          if (isSyncing)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              Icons.cloud_done_outlined,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (slotLabel != null)
            Text(
              slotLabel!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
        ],
      ),
    );
  }
}

class HomeEmptyState extends StatelessWidget {
  const HomeEmptyState({
    super.key,
    required this.strings,
    required this.onAddRepo,
  });

  final AppStrings strings;
  final VoidCallback onAddRepo;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.folder_open_outlined,
                size: 32,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              strings.noReposTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              strings.noReposSubtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAddRepo,
              icon: const Icon(Icons.add, size: 18),
              label: Text(strings.addRepo),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeErrorState extends StatelessWidget {
  const HomeErrorState({
    super.key,
    required this.strings,
    required this.onRetry,
  });

  final AppStrings strings;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(strings.loadReposFailed),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(strings.tryAgain),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeNoResultsState extends StatelessWidget {
  const HomeNoResultsState({super.key, required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 56,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(strings.noSearchResults),
          ],
        ),
      ),
    );
  }
}

class HomeTourOverlay extends StatelessWidget {
  const HomeTourOverlay({
    super.key,
    required this.strings,
    required this.onDismiss,
  });

  final AppStrings strings;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.explore,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                strings.appTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                strings.tourWelcome,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 12),
              _step(Icons.add, strings.tourAddRepo),
              _step(Icons.sync, strings.tourSync),
              _step(Icons.swipe, strings.tourSwipe),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: onDismiss,
                child: Text(strings.tourGotIt),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _step(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
