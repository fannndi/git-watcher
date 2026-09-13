import 'commit.dart';

class WatchedRepo {
  const WatchedRepo({
    required this.owner,
    required this.repo,
    required this.branch,
    required this.syncMode,
    this.avatarUrl = '',
    this.isPrivate = false,
    this.muted = false,
    this.lastCommitAt,
    this.lastSha = '',
  });

  final String owner;
  final String repo;
  final String branch;
  final String syncMode;
  final String avatarUrl;
  final bool isPrivate;
  final bool muted;
  final DateTime? lastCommitAt;
  final String lastSha;

  String get fullName => '$owner/$repo';

  WatchedRepo copyWith({
    String? syncMode,
    String? avatarUrl,
    bool? isPrivate,
    bool? muted,
    DateTime? lastCommitAt,
    String? lastSha,
  }) {
    return WatchedRepo(
      owner: owner,
      repo: repo,
      branch: branch,
      syncMode: syncMode ?? this.syncMode,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isPrivate: isPrivate ?? this.isPrivate,
      muted: muted ?? this.muted,
      lastCommitAt: lastCommitAt ?? this.lastCommitAt,
      lastSha: lastSha ?? this.lastSha,
    );
  }

  Map<String, dynamic> toJson() => {
        'owner': owner,
        'repo': repo,
        'branch': branch,
        'sync_mode': syncMode,
        'avatar_url': avatarUrl,
        'is_private': isPrivate,
        'muted': muted,
        'last_commit_at': lastCommitAt?.toIso8601String(),
        'last_sha': lastSha,
      };

  factory WatchedRepo.fromJson(Map<String, dynamic> json) {
    final rawSyncMode = json['sync_mode'] as String? ?? 'minimal';

    return WatchedRepo(
      owner: json['owner'] as String? ?? '',
      repo: json['repo'] as String? ?? '',
      branch: json['branch'] as String? ?? 'main',
      syncMode: rawSyncMode == 'full' ? 'extended_5000' : rawSyncMode,
      avatarUrl: json['avatar_url'] as String? ?? '',
      isPrivate: json['is_private'] == true,
      muted: json['muted'] == true,
      lastCommitAt: parseDate(json['last_commit_at']),
      lastSha: json['last_sha'] as String? ?? '',
    );
  }
}
