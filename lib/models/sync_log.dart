import 'commit.dart';

class SyncLog {
  const SyncLog({
    required this.syncedAt,
    required this.updates,
  });

  final DateTime syncedAt;
  final Map<String, int> updates;

  bool get hasUpdates => updates.isNotEmpty;

  int get totalCommits => updates.values.fold(0, (total, count) => total + count);

  Map<String, dynamic> toJson() => {
        'synced_at': syncedAt.toIso8601String(),
        'updates': updates,
      };

  factory SyncLog.fromJson(Map<String, dynamic> json) {
    final rawUpdates = json['updates'] as Map<String, dynamic>? ?? const {};
    return SyncLog(
      syncedAt: parseDate(json['synced_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      updates: rawUpdates.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      ),
    );
  }
}
