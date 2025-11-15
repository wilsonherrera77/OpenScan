/// Authentication token entity
/// Represents authentication credentials for Paperless API
class AuthToken {
  final String token;
  final String username;
  final String baseUrl;
  final DateTime? expiresAt;

  const AuthToken({
    required this.token,
    required this.username,
    required this.baseUrl,
    this.expiresAt,
  });

  /// Create from JSON response
  factory AuthToken.fromJson(Map<String, dynamic> json, String username, String baseUrl) {
    return AuthToken(
      token: json['token'] as String,
      username: username,
      baseUrl: baseUrl,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'username': username,
      'base_url': baseUrl,
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  /// Check if token is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Get authorization header value
  String get authorizationHeader => 'Token $token';

  @override
  String toString() {
    return 'AuthToken(username: $username, baseUrl: $baseUrl, expired: $isExpired)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AuthToken &&
        other.token == token &&
        other.username == username &&
        other.baseUrl == baseUrl;
  }

  @override
  int get hashCode {
    return token.hashCode ^ username.hashCode ^ baseUrl.hashCode;
  }
}
