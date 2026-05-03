class SyncLog {
  final DateTime syncedAt;
  final Map<String, int> updates;

  SyncLog({
    required this.syncedAt,
    required this.updates,
  });

  bool get hasUpdates => updates.isNotEmpty;

  int get totalCommits {
    return updates.values.fold(0, (total, count) => total + count);
  }

  Map<String, dynamic> toJson() => {
        'synced_at': syncedAt.toIso8601String(),
        'updates': updates,
      };

  factory SyncLog.fromJson(Map<String, dynamic> json) {
    final rawUpdates = json['updates'] as Map<String, dynamic>? ?? {};
    return SyncLog(
      syncedAt: DateTime.parse(json['synced_at']),
      updates: rawUpdates.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      ),
    );
  }
}
