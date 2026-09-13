import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_settings.dart';
import '../models/sync_log.dart';
import '../services/app_settings_controller.dart';
import '../services/storage_service.dart';
import '../utils/animations.dart';
import '../utils/strings.dart';
import '../widgets/skeleton.dart';
import '../widgets/sliver_date_header.dart';

class UpdateScreen extends StatefulWidget {
  const UpdateScreen({super.key});

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  final StorageService _storage = StorageService();
  final DateFormat _dayFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _timeFormat = DateFormat('HH:mm');

  List<SyncLog> _history = [];
  String? _repoFilter;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUpdates();
  }

  Future<void> _loadUpdates() async {
    final history = await _storage.getSyncHistory();
    if (!mounted) return;
    setState(() {
      _history = history;
      _isLoading = false;
    });
  }

  List<String> get _repoKeys {
    final keys = <String>{};
    for (final log in _history) {
      keys.addAll(log.updates.keys);
    }
    return keys.toList()..sort();
  }

  List<SyncLog> get _filteredLogs {
    if (_repoFilter == null) {
      return _history;
    }
    return _history
        .where((log) => log.updates.containsKey(_repoFilter))
        .toList();
  }

  Map<String, List<SyncLog>> _groupByDay(List<SyncLog> logs) {
    final grouped = <String, List<SyncLog>>{};
    for (final log in logs) {
      final key = _dayFormat.format(log.syncedAt.toLocal());
      grouped.putIfAbsent(key, () => []).add(log);
    }
    return grouped;
  }

  Future<void> _confirmClearHistory(AppStrings strings) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.clearHistory),
        content: Text(strings.clearHistoryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _storage.clearSyncHistory();
    if (!mounted) return;
    setState(() {
      _history = [];
      _repoFilter = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.historyCleared)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppSettings>(
      valueListenable: appSettingsController,
      builder: (context, settings, _) {
        final strings = stringsFor(settings.languageCode);

        return Scaffold(
          appBar: AppBar(
            title: Text(strings.history),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: strings.refresh,
                onPressed: _loadUpdates,
              ),
              if (_history.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined),
                  tooltip: strings.clearHistory,
                  onPressed: () => _confirmClearHistory(strings),
                ),
            ],
          ),
          body: _isLoading
              ? _buildSkeleton()
              : _history.isEmpty
                  ? Center(child: Text(strings.noSyncHistory))
                  : _buildContent(strings),
        );
      },
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Skeleton(child: SkeletonCommitCard()),
        SizedBox(height: 12),
        Skeleton(child: SkeletonCommitCard()),
        SizedBox(height: 12),
        Skeleton(child: SkeletonCommitCard()),
      ],
    );
  }

  Widget _buildContent(AppStrings strings) {
    final grouped = _groupByDay(_filteredLogs);
    final repoKeys = _repoKeys;

    return RefreshIndicator(
      onRefresh: _loadUpdates,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (repoKeys.isNotEmpty)
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text(strings.allRepos),
                      selected: _repoFilter == null,
                      onSelected: (_) => setState(() => _repoFilter = null),
                    ),
                    for (final key in repoKeys) ...[
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(key),
                        selected: _repoFilter == key,
                        onSelected: (_) => setState(() => _repoFilter = key),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          if (grouped.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  _history.isEmpty
                      ? strings.noSyncHistory
                      : strings.noUpdatesForRepo,
                ),
              ),
            )
          else
            for (final entry in grouped.entries) ...[
              SliverPersistentHeader(
                pinned: true,
                delegate: SliverDateHeaderDelegate(entry.key),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                sliver: SliverList.separated(
                  itemCount: entry.value.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return FadeInSlideUp(
                      index: index,
                      child: _SyncLogCard(
                        log: entry.value[index],
                        timeFormat: _timeFormat,
                        strings: strings,
                      ),
                    );
                  },
                ),
              ),
            ],
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _SyncLogCard extends StatelessWidget {
  const _SyncLogCard({
    required this.log,
    required this.timeFormat,
    required this.strings,
  });

  final SyncLog log;
  final DateFormat timeFormat;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: log.hasUpdates
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    log.hasUpdates
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_none_outlined,
                    size: 18,
                    color: log.hasUpdates
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timeFormat.format(log.syncedAt.toLocal()),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        log.hasUpdates
                            ? strings.reposHaveUpdates(log.updates.length)
                            : strings.noNewCommits,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (log.hasUpdates)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '+${log.totalCommits}',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            if (log.hasUpdates) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              for (final entry in log.updates.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.commit,
                        size: 14,
                        color: colorScheme.primary.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '+${entry.value}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
