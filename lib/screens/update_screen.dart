import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/sync_log.dart';
import '../services/app_settings_controller.dart';
import '../services/storage_service.dart';
import '../utils/strings.dart';

class UpdateScreen extends StatefulWidget {
  const UpdateScreen({super.key});

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  final StorageService _storage = StorageService();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');
  List<SyncLog> _history = [];
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

  @override
  Widget build(BuildContext context) {
    final strings = stringsFor(appSettingsController.value.languageCode);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.history),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? Center(child: Text(strings.noSyncHistory))
              : RefreshIndicator(
                  onRefresh: _loadUpdates,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: _history.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final log = _history[index];
                      return TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 400 + (index * 100).clamp(0, 400)),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
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
                                        color: (log.hasUpdates
                                                ? Theme.of(context).colorScheme.primaryContainer
                                                : Theme.of(context).colorScheme.surfaceContainerHighest)
                                            .withValues(alpha: 0.7),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        log.hasUpdates
                                            ? Icons.notifications_active_outlined
                                            : Icons.notifications_none_outlined,
                                        size: 18,
                                        color: log.hasUpdates
                                            ? Theme.of(context).colorScheme.primary
                                            : Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _dateFormat.format(log.syncedAt.toLocal()),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            log.hasUpdates ? strings.reposHaveUpdates(log.updates.length) : strings.noNewCommits,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (log.hasUpdates)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '+${log.totalCommits}',
                                          style: const TextStyle(
                                            color: Colors.white,
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
                                  ...log.updates.entries.map(
                                    (entry) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.commit,
                                            size: 14,
                                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
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
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
