class WatchedRepo {
  final String owner;
  final String repo;
  final String branch;
  String lastSha;

  WatchedRepo({
    required this.owner,
    required this.repo,
    required this.branch,
    required this.lastSha,
  });

  String get fullName => '$owner/$repo';

  Map<String, dynamic> toJson() => {
        'owner': owner,
        'repo': repo,
        'branch': branch,
        'last_sha': lastSha,
      };

  factory WatchedRepo.fromJson(Map<String, dynamic> json) {
    return WatchedRepo(
      owner: json['owner'],
      repo: json['repo'],
      branch: json['branch'] ?? 'main',
      lastSha: json['last_sha'] ?? '',
    );
  }
}
