class WatchedRepo {
  final String owner;
  final String repo;
  final String branch;
  final String syncMode;
  String lastSha;

  WatchedRepo({
    required this.owner,
    required this.repo,
    required this.branch,
    required this.syncMode,
    required this.lastSha,
  });

  String get fullName => '$owner/$repo';

  Map<String, dynamic> toJson() => {
        'owner': owner,
        'repo': repo,
        'branch': branch,
        'sync_mode': syncMode,
        'last_sha': lastSha,
      };

  factory WatchedRepo.fromJson(Map<String, dynamic> json) {
    final rawSyncMode = json['sync_mode'] ?? 'minimal';
    return WatchedRepo(
      owner: json['owner'],
      repo: json['repo'],
      branch: json['branch'] ?? 'main',
      syncMode: rawSyncMode == 'full' ? 'extended_5000' : rawSyncMode,
      lastSha: json['last_sha'] ?? '',
    );
  }
}
