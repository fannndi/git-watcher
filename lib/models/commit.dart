class Commit {
  final String sha;
  final String message;
  final DateTime date;

  Commit({required this.sha, required this.message, required this.date});

  String get title => message.split('\n').first.trim();

  factory Commit.fromJson(Map<String, dynamic> json) {
    return Commit(
      sha: json['sha'],
      message: json['commit']['message'] ?? '',
      date: DateTime.parse(json['commit']['author']['date']),
    );
  }

  Map<String, dynamic> toJson() => {
        'sha': sha,
        'message': message,
        'date': date.toIso8601String(),
      };

  factory Commit.fromCacheJson(Map<String, dynamic> json) {
    return Commit(
      sha: json['sha'],
      message: json['message'] ?? '',
      date: DateTime.parse(json['date']),
    );
  }
}

class CommitDetail {
  final String sha;
  final int additions;
  final int deletions;
  final int totalChanges;
  final List<CommitFile> files;

  CommitDetail({
    required this.sha,
    required this.additions,
    required this.deletions,
    required this.totalChanges,
    required this.files,
  });

  factory CommitDetail.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? {};
    final rawFiles = json['files'] as List<dynamic>? ?? [];

    return CommitDetail(
      sha: json['sha'] ?? '',
      additions: (stats['additions'] as num?)?.toInt() ?? 0,
      deletions: (stats['deletions'] as num?)?.toInt() ?? 0,
      totalChanges: (stats['total'] as num?)?.toInt() ?? 0,
      files: rawFiles
          .map((item) => CommitFile.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CommitFile {
  final String filename;
  final String status;
  final int additions;
  final int deletions;
  final int changes;

  CommitFile({
    required this.filename,
    required this.status,
    required this.additions,
    required this.deletions,
    required this.changes,
  });

  factory CommitFile.fromJson(Map<String, dynamic> json) {
    return CommitFile(
      filename: json['filename'] ?? '',
      status: json['status'] ?? 'modified',
      additions: (json['additions'] as num?)?.toInt() ?? 0,
      deletions: (json['deletions'] as num?)?.toInt() ?? 0,
      changes: (json['changes'] as num?)?.toInt() ?? 0,
    );
  }
}
