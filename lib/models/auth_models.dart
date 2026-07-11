class AuthSession {
  final String tokenType;
  final String accessToken;
  final int accessExpiresIn;
  final String refreshToken;
  final int refreshExpiresIn;
  final String userId;
  final String email;
  final String? nickname;

  const AuthSession({
    required this.tokenType,
    required this.accessToken,
    required this.accessExpiresIn,
    required this.refreshToken,
    required this.refreshExpiresIn,
    required this.userId,
    required this.email,
    this.nickname,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      accessToken: json['accessToken'] as String? ?? '',
      accessExpiresIn: (json['accessExpiresIn'] as num? ?? 0).toInt(),
      refreshToken: json['refreshToken'] as String? ?? '',
      refreshExpiresIn: (json['refreshExpiresIn'] as num? ?? 0).toInt(),
      userId: json['userId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      nickname: json['nickname'] as String?,
    );
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
