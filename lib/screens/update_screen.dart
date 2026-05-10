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
      appBar: AppBar(title: Text(strings.history)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _history.isEmpty
                ? Center(child: Text(strings.noSyncHistory))
                : RefreshIndicator(
                    onRefresh: _loadUpdates,
                    child: ListView.builder(
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        final log = _history[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      log.hasUpdates
                                          ? Icons.notifications_active_outlined
                                          : Icons.notifications_none_outlined,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _dateFormat
                                            .format(log.syncedAt.toLocal()),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      log.hasUpdates
                                          ? '+${log.totalCommits}'
                                          : '0',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (!log.hasUpdates)
                                  Text(strings.noNewCommits)
                                else
                                  ...log.updates.entries.map(
                                    (entry) => Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Text(
                                        '${entry.key} -> +${entry.value} commit',
                                      ),
                                    ),
                                  ),
                              ],
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
