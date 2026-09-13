import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/commit.dart';
import '../models/watched_repo.dart';
import '../services/app_settings_controller.dart';
import '../services/github_service.dart';
import '../utils/constants.dart';
import '../utils/strings.dart';
import 'chips.dart';
import 'commit_card.dart' show shortSha;

class CommitDetailSheet extends StatefulWidget {
  const CommitDetailSheet({
    super.key,
    required this.repo,
    required this.commit,
    required this.github,
  });

  final WatchedRepo repo;
  final Commit commit;
  final GitHubService github;

  @override
  State<CommitDetailSheet> createState() => _CommitDetailSheetState();
}

class _CommitDetailSheetState extends State<CommitDetailSheet> {
  late Future<CommitDetail> _future = _load();

  Future<CommitDetail> _load() {
    return widget.github.fetchCommitDetail(
      widget.repo.owner,
      widget.repo.repo,
      widget.commit.sha,
    );
  }

  void _retry() {
    setState(() => _future = _load());
  }

  Future<void> _openInBrowser() async {
    final strings = stringsFor(appSettingsController.value.languageCode);
    final uri = Uri.https(
      githubWebHost,
      '/${widget.repo.owner}/${widget.repo.repo}/commit/${widget.commit.sha}',
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.openLinkFailed)),
      );
    }
  }

  Future<void> _copySha() async {
    await Clipboard.setData(ClipboardData(text: widget.commit.sha));
    if (!mounted) return;

    final strings = stringsFor(appSettingsController.value.languageCode);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.shaCopied)),
    );
  }

  TextSpan _formatMessage(String message, BuildContext context) {
    final lines = message.split('\n');
    final spans = <TextSpan>[
      TextSpan(
        text: lines.first,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    ];

    if (lines.length > 1) {
      spans.add(
        TextSpan(
          text: '\n${lines.sublist(1).join('\n')}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    final strings = stringsFor(appSettingsController.value.languageCode);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.76,
      minChildSize: 0.4,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return FutureBuilder<CommitDetail>(
          future: _future,
          builder: (context, snapshot) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        shortSha(widget.commit.sha),
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    IconButton(
                      tooltip: strings.shaCopied,
                      icon: const Icon(Icons.copy_all_outlined),
                      onPressed: _copySha,
                    ),
                    IconButton(
                      tooltip: strings.close,
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText.rich(
                  _formatMessage(widget.commit.message, context),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _openInBrowser,
                  icon: const Icon(Icons.open_in_browser_outlined),
                  label: Text(strings.seeDetail),
                ),
                const SizedBox(height: 18),
                if (snapshot.connectionState != ConnectionState.done)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (snapshot.hasError)
                  _CommitDetailError(onRetry: _retry)
                else
                  _CommitFileSummary(detail: snapshot.requireData),
              ],
            );
          },
        );
      },
    );
  }
}

class _CommitFileSummary extends StatelessWidget {
  const _CommitFileSummary({required this.detail});

  final CommitDetail detail;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final strings = stringsFor(appSettingsController.value.languageCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                strings.changedFiles(detail.files.length),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            InfoChip(label: '+${detail.additions}', color: Colors.green),
            const SizedBox(width: 8),
            InfoChip(label: '-${detail.deletions}', color: colorScheme.error),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            InfoChip(
              icon: Icons.add,
              label: '+${detail.additions}',
              color: Colors.green,
            ),
            const SizedBox(width: 8),
            InfoChip(
              icon: Icons.remove,
              label: '-${detail.deletions}',
              color: colorScheme.error,
            ),
            const SizedBox(width: 8),
            InfoChip(
              icon: Icons.folder,
              label: '${detail.files.length} files',
              color: colorScheme.primary,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (detail.files.isEmpty)
          Text(
            strings.noFileDetail,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          )
        else
          ...detail.files.map((file) => _CommitFileTile(file: file)),
      ],
    );
  }
}

class _CommitFileTile extends StatelessWidget {
  const _CommitFileTile({required this.file});

  final CommitFile file;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              _statusIcon(file.status),
              color: _statusColor(file.status, colorScheme),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.filename,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    file.status,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            InfoChip(label: '+${file.additions}', color: Colors.green),
            const SizedBox(width: 6),
            InfoChip(label: '-${file.deletions}', color: colorScheme.error),
          ],
        ),
      ),
    );
  }
}

class _CommitDetailError extends StatelessWidget {
  const _CommitDetailError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = stringsFor(appSettingsController.value.languageCode);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 36),
          const SizedBox(height: 10),
          Text(strings.fetchCommitDetailFailed),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(strings.tryAgain),
          ),
        ],
      ),
    );
  }
}

IconData _statusIcon(String status) {
  return switch (status) {
    'added' => Icons.add_circle_outline,
    'removed' => Icons.remove_circle_outline,
    'renamed' => Icons.drive_file_rename_outline,
    _ => Icons.edit_outlined,
  };
}

Color _statusColor(String status, ColorScheme colorScheme) {
  return switch (status) {
    'added' => Colors.green,
    'removed' => colorScheme.error,
    'renamed' => colorScheme.tertiary,
    _ => colorScheme.primary,
  };
}
