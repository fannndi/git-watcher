class WatchedRepo {
  final String owner;
  final String repo;
  final String branch;
  final String syncMode;
  final String avatarUrl;
  final bool isPrivate;
  DateTime? lastCommitAt;
  String lastSha;

  WatchedRepo({
    required this.owner,
    required this.repo,
    required this.branch,
    required this.syncMode,
    this.avatarUrl = '',
    this.isPrivate = false,
    this.lastCommitAt,
    required this.lastSha,
  });

  String get fullName => '$owner/$repo';

  Map<String, dynamic> toJson() => {
        'owner': owner,
        'repo': repo,
        'branch': branch,
        'sync_mode': syncMode,
        'avatar_url': avatarUrl,
        'is_private': isPrivate,
        'last_commit_at': lastCommitAt?.toIso8601String(),
        'last_sha': lastSha,
      };

  factory WatchedRepo.fromJson(Map<String, dynamic> json) {
    final rawSyncMode = json['sync_mode'] ?? 'minimal';
    return WatchedRepo(
      owner: json['owner'],
      repo: json['repo'],
      branch: json['branch'] ?? 'main',
      syncMode: rawSyncMode == 'full' ? 'extended_5000' : rawSyncMode,
      avatarUrl: json['avatar_url'] ?? '',
      isPrivate: json['is_private'] == true,
      lastCommitAt: _parseDate(json['last_commit_at']),
      lastSha: json['last_sha'] ?? '',
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}
