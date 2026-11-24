import 'dart:convert';

enum SocialAuthProvider {
  apple('APPLE'),
  kakao('KAKAO');

  final String apiValue;

  const SocialAuthProvider(this.apiValue);
}

class SocialLoginRequest {
  final SocialAuthProvider provider;
  final String token;
  final String authorizationCode;
  final String nonce;

  const SocialLoginRequest({
    required this.provider,
    required this.token,
    this.authorizationCode = '',
    this.nonce = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'provider': provider.apiValue,
      'token': token,
      if (provider == SocialAuthProvider.apple)
        'authorizationCode': authorizationCode,
      if (provider == SocialAuthProvider.apple) 'nonce': nonce,
    };
  }
}

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

  /// Authentication returned with the new account; no second login is needed.
  final AuthSession? authentication;

  const SignupResult({
    required this.userId,
    required this.email,
    this.createdAt,
    this.authentication,
  });

  factory SignupResult.fromJson(Map<String, dynamic> json) {
    return SignupResult(
      userId: json['userId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      authentication: json['authentication'] is Map
          ? AuthSession.fromJson({
              ...Map<String, dynamic>.from(json['authentication'] as Map),
              'userId': json['userId'],
              'email': json['email'],
            })
          : null,
    );
  }
}

/// The two distinct outcomes of social preparation, before signup consent.
class SocialPrepareResult {
  /// Creates an existing-member login result.
  const SocialPrepareResult.login(this.authentication)
    : signupTicket = null,
      expiresIn = null;

  /// Creates an expiring signup-ticket result without storing a login session.
  const SocialPrepareResult.signup({
    required this.signupTicket,
    required this.expiresIn,
  }) : authentication = null;

  /// The JWT session, only for an existing member.
  final AuthSession? authentication;

  /// The one-use server ticket, only for a new member.
  final String? signupTicket;

  /// The ticket's lifetime in seconds, not JWT milliseconds.
  final int? expiresIn;

  /// Parses the status discriminator without treating a ticket as a session.
  factory SocialPrepareResult.fromJson(Map<String, dynamic> json) {
    if (json['status'] == 'LOGIN_COMPLETE' && json['authentication'] is Map) {
      return SocialPrepareResult.login(
        AuthSession.fromJson(
          Map<String, dynamic>.from(json['authentication'] as Map),
        ),
      );
    }
    if (json['status'] == 'SIGNUP_REQUIRED' &&
        json['signupTicket'] is String &&
        (json['signupTicket'] as String).isNotEmpty &&
        json['expiresIn'] is num &&
        (json['expiresIn'] as num) > 0) {
      return SocialPrepareResult.signup(
        signupTicket: json['signupTicket'] as String,
        expiresIn: (json['expiresIn'] as num).toInt(),
      );
    }
    throw const FormatException('소셜 인증 결과를 확인할 수 없습니다.');
  }
}

class SignupEmailCodeResult {
  final int expiresIn;
  final int resendAfter;

  const SignupEmailCodeResult({
    required this.expiresIn,
    required this.resendAfter,
  });

  factory SignupEmailCodeResult.fromJson(Map<String, dynamic> json) {
    return SignupEmailCodeResult(
      expiresIn: (json['expiresIn'] as num? ?? 300).toInt(),
      resendAfter: (json['resendAfter'] as num? ?? 60).toInt(),
    );
  }
}

class SignupEmailVerificationResult {
  final String signupToken;

  const SignupEmailVerificationResult({required this.signupToken});

  factory SignupEmailVerificationResult.fromJson(Map<String, dynamic> json) {
    return SignupEmailVerificationResult(
      signupToken: json['signupToken'] as String? ?? '',
    );
  }
}

class PasswordFindResult {
  final int expiresIn;
  final int resendAfter;

  const PasswordFindResult({required this.expiresIn, this.resendAfter = 0});

  factory PasswordFindResult.fromJson(Map<String, dynamic> json) {
    return PasswordFindResult(
      expiresIn: (json['expiresIn'] as num? ?? 300).toInt(),
      resendAfter: (json['resendAfter'] as num? ?? 0).toInt(),
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
