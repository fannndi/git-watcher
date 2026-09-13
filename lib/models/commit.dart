class Commit {
  const Commit({
    required this.sha,
    required this.message,
    required this.date,
    this.author = '',
  });

  final String sha;
  final String message;
  final DateTime date;
  final String author;

  String get title => message.split('\n').first.trim();

  factory Commit.fromJson(Map<String, dynamic> json) {
    final commit = json['commit'] as Map<String, dynamic>? ?? const {};
    final gitAuthor = commit['author'] as Map<String, dynamic>? ?? const {};
    final account = json['author'] as Map<String, dynamic>? ?? const {};

    return Commit(
      sha: json['sha'] as String? ?? '',
      message: commit['message'] as String? ?? '',
      date: parseDate(gitAuthor['date']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      author:
          (account['login'] as String?) ?? (gitAuthor['name'] as String?) ?? '',
    );
  }

  factory Commit.fromCacheJson(Map<String, dynamic> json) {
    return Commit(
      sha: json['sha'] as String? ?? '',
      message: json['message'] as String? ?? '',
      date: parseDate(json['date']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      author: json['author'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'sha': sha,
        'message': message,
        'date': date.toIso8601String(),
        'author': author,
      };
}

class CommitDetail {
  const CommitDetail({
    required this.sha,
    required this.additions,
    required this.deletions,
    required this.totalChanges,
    required this.files,
  });

  final String sha;
  final int additions;
  final int deletions;
  final int totalChanges;
  final List<CommitFile> files;

  factory CommitDetail.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? const {};
    final files = json['files'] as List<dynamic>? ?? const [];

    return CommitDetail(
      sha: json['sha'] as String? ?? '',
      additions: (stats['additions'] as num?)?.toInt() ?? 0,
      deletions: (stats['deletions'] as num?)?.toInt() ?? 0,
      totalChanges: (stats['total'] as num?)?.toInt() ?? 0,
      files: files
          .map((item) => CommitFile.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CommitFile {
  const CommitFile({
    required this.filename,
    required this.status,
    required this.additions,
    required this.deletions,
    required this.changes,
  });

  final String filename;
  final String status;
  final int additions;
  final int deletions;
  final int changes;

  factory CommitFile.fromJson(Map<String, dynamic> json) {
    return CommitFile(
      filename: json['filename'] as String? ?? '',
      status: json['status'] as String? ?? 'modified',
      additions: (json['additions'] as num?)?.toInt() ?? 0,
      deletions: (json['deletions'] as num?)?.toInt() ?? 0,
      changes: (json['changes'] as num?)?.toInt() ?? 0,
    );
  }
}

DateTime? parseDate(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}
