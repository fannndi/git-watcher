import 'dart:convert';

class GitHubCredentials {
  const GitHubCredentials({
    required this.username,
    required this.token,
  });

  const GitHubCredentials.empty()
      : username = '',
        token = '';

  final String username;
  final String token;

  bool get isEmpty => username.isEmpty || token.isEmpty;
  bool get isNotEmpty => !isEmpty;

  Map<String, dynamic> toJson() => {
        'username': base64Encode(utf8.encode(username)),
        'token': base64Encode(utf8.encode(token)),
      };

  factory GitHubCredentials.fromJson(Map<String, dynamic> json) {
    String decode(String? value) {
      if (value == null || value.isEmpty) return '';
      try {
        return utf8.decode(base64Decode(value));
      } catch (_) {
        return '';
      }
    }

    return GitHubCredentials(
      username: decode(json['username'] as String?),
      token: decode(json['token'] as String?),
    );
  }

  String get basicAuth =>
      'Basic ${base64Encode(utf8.encode('$username:$token'))}';
}
