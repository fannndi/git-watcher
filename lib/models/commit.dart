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
