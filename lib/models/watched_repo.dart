class WatchedRepo {
  final String owner;
  final String repo;
  final String branch;
  final String syncMode;
  final String avatarUrl;
  String lastSha;

  WatchedRepo({
    required this.owner,
    required this.repo,
    required this.branch,
    required this.syncMode,
    this.avatarUrl = '',
    required this.lastSha,
  });

  String get fullName => '$owner/$repo';

  Map<String, dynamic> toJson() => {
        'owner': owner,
        'repo': repo,
        'branch': branch,
        'sync_mode': syncMode,
        'avatar_url': avatarUrl,
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
      lastSha: json['last_sha'] ?? '',
    );
  }
}
