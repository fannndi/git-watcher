class Commit {
  final String sha;
  final String message;
  final DateTime date;

  Commit({required this.sha, required this.message, required this.date});

  factory Commit.fromJson(Map<String, dynamic> json) {
    return Commit(
      sha: json['sha'],
      message: json['commit']['message'] ?? '',
      date: DateTime.parse(json['commit']['author']['date']),
    );
  }
}
