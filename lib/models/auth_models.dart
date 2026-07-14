import 'dart:convert';

class AuthSession {
  final String tokenType;
  final String accessToken;
  final int accessExpiresIn;
  final String refreshToken;
  final int refreshExpiresIn;
  final String userId;
  final String email;
  final String? nickname;
  final String? role;

  const AuthSession({
    required this.tokenType,
    required this.accessToken,
    required this.accessExpiresIn,
    required this.refreshToken,
    required this.refreshExpiresIn,
    required this.userId,
    required this.email,
    this.nickname,
    this.role,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final accessToken = json['accessToken'] as String? ?? '';
    return AuthSession(
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      accessToken: accessToken,
      accessExpiresIn: (json['accessExpiresIn'] as num? ?? 0).toInt(),
      refreshToken: json['refreshToken'] as String? ?? '',
      refreshExpiresIn: (json['refreshExpiresIn'] as num? ?? 0).toInt(),
      userId: json['userId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      nickname: json['nickname'] as String?,
      role: json['role'] as String? ?? _roleFromAccessToken(accessToken),
    );
  }

  static String? _roleFromAccessToken(String token) {
    final parts = token.split('.');
    if (parts.length < 2) return null;
    try {
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(decoded);
      if (payload is! Map<String, dynamic>) return null;
      return payload['role'] as String?;
    } catch (_) {
      return null;
    }
  }
}

class SignupResult {
  final String userId;
  final String email;
  final DateTime? createdAt;

  const SignupResult({
    required this.userId,
    required this.email,
    this.createdAt,
  });

  factory SignupResult.fromJson(Map<String, dynamic> json) {
    return SignupResult(
      userId: json['userId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}

class PasswordFindResult {
  final int expiresIn;

  const PasswordFindResult({required this.expiresIn});

  factory PasswordFindResult.fromJson(Map<String, dynamic> json) {
    return PasswordFindResult(
      expiresIn: (json['expiresIn'] as num? ?? 300).toInt(),
    );
  }
}

class PasswordVerifyResult {
  final String resetToken;

  const PasswordVerifyResult({required this.resetToken});

  factory PasswordVerifyResult.fromJson(Map<String, dynamic> json) {
    return PasswordVerifyResult(
      resetToken: json['resetToken'] as String? ?? '',
    );
  }
}
