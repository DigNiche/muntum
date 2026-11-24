import 'package:muntum/api/api_client.dart';
import 'package:muntum/api/api_endpoints.dart';
import 'package:muntum/api/api_response.dart';
import 'package:muntum/api/token_store.dart';
import 'package:muntum/models/auth_models.dart';
import 'package:muntum/models/terms_model.dart';
import 'package:muntum/api/api_exception.dart';

class AuthService {
  AuthService({ApiClient? client, TokenStore? tokenStore})
    : _client = client ?? ApiClient(),
      _tokenStore = tokenStore ?? TokenStore.instance;

  final ApiClient _client;
  final TokenStore _tokenStore;

  Future<SignupResult> signup({
    required String email,
    required String password,
    required String signupToken,
    required SignupConsent signupConsent,
  }) async {
    final response = await _client.post(
      ApiEndpoints.signup,
      body: {
        'email': email,
        'password': password,
        'signupToken': signupToken,
        'signupConsent': signupConsent.toJson(),
      },
    );
    final result = ApiResponse.fromJson(
      response,
      (data) =>
          SignupResult.fromJson(data as Map<String, dynamic>? ?? const {}),
    ).data;
    final session = result.authentication;
    if (session == null) {
      throw const ApiException(
        code: 'SIGNUP_SESSION_MISSING',
        message: '회원가입 인증 결과를 확인하지 못했어요. 가입을 반복하지 말고 로그인해주세요.',
      );
    }
    await _saveSession(session, authProvider: 'EMAIL');
    return result;
  }

  Future<SignupEmailCodeResult> requestSignupEmailCode(String email) async {
    final response = await _client.post(
      ApiEndpoints.signupEmailSendCode,
      body: {'email': email},
    );
    return ApiResponse.fromJson(
      response,
      (data) => SignupEmailCodeResult.fromJson(
        data as Map<String, dynamic>? ?? const {},
      ),
    ).data;
  }

  Future<SignupEmailVerificationResult> verifySignupEmailCode({
    required String email,
    required String code,
  }) async {
    final response = await _client.post(
      ApiEndpoints.signupEmailVerifyCode,
      body: {'email': email, 'code': code},
    );
    return ApiResponse.fromJson(
      response,
      (data) => SignupEmailVerificationResult.fromJson(
        data as Map<String, dynamic>? ?? const {},
      ),
    ).data;
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      ApiEndpoints.login,
      body: {'email': email, 'password': password},
    );
    final session = ApiResponse.fromJson(
      response,
      (data) => AuthSession.fromJson(data as Map<String, dynamic>? ?? const {}),
    ).data;
    await _saveSession(session, authProvider: 'EMAIL');
    return session;
  }

  /// Prepares social authentication without creating an unconsented account.
  Future<SocialPrepareResult> prepareSocial(SocialLoginRequest request) async {
    final response = await _client.post(
      ApiEndpoints.socialPrepare,
      body: request.toJson(),
    );
    final result = ApiResponse.fromJson(
      response,
      (data) =>
          SocialPrepareResult.fromJson(Map<String, dynamic>.from(data as Map)),
    ).data;
    final session = result.authentication;
    if (session != null) {
      await _saveSession(session, authProvider: request.provider.apiValue);
    }
    return result;
  }

  /// Consumes a prepared ticket after explicit agreement to published terms.
  Future<AuthSession> signupSocial({
    required String signupTicket,
    required SocialAuthProvider provider,
    required SignupConsent signupConsent,
  }) async {
    final response = await _client.post(
      ApiEndpoints.socialSignup,
      body: {
        'signupTicket': signupTicket,
        'signupConsent': signupConsent.toJson(),
      },
    );
    final session = AuthSession.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
    await _saveSession(session, authProvider: provider.apiValue);
    return session;
  }

  Future<AuthSession?> refresh() async {
    final refreshToken = await _tokenStore.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    final Map<String, dynamic> response;
    try {
      response = await _client.post(
        ApiEndpoints.refresh,
        body: {'refreshToken': refreshToken},
      );
    } on ApiException catch (error) {
      if (error.statusCode == 401 ||
          (error.statusCode == 404 && error.code == 'A002')) {
        await _tokenStore.clear();
      }
      rethrow;
    }
    final session = ApiResponse.fromJson(
      response,
      (data) => AuthSession.fromJson(data as Map<String, dynamic>? ?? const {}),
    ).data;
    await _saveSession(session);
    return session;
  }

  Future<void> _saveSession(AuthSession session, {String? authProvider}) {
    if (session.accessToken.isEmpty || session.refreshToken.isEmpty) {
      throw const FormatException('로그인 인증 정보를 확인할 수 없습니다.');
    }
    return _tokenStore.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      userId: session.userId,
      email: session.email,
      nickname: session.nickname,
      role: session.role,
      authProvider: authProvider,
    );
  }

  Future<void> logout() async {
    try {
      await _client.post(ApiEndpoints.logout, authorized: true);
    } on ApiException catch (error) {
      if (error.statusCode == 401) await _tokenStore.clear();
      rethrow;
    }
    await _tokenStore.clear();
  }

  Future<PasswordFindResult> requestPasswordCode(String email) async {
    final response = await _client.post(
      ApiEndpoints.passwordFind,
      body: {'email': email},
    );
    return ApiResponse.fromJson(
      response,
      (data) => PasswordFindResult.fromJson(
        data as Map<String, dynamic>? ?? const {},
      ),
    ).data;
  }

  Future<PasswordVerifyResult> verifyPasswordCode({
    required String email,
    required String code,
  }) async {
    final response = await _client.post(
      ApiEndpoints.passwordVerifyCode,
      body: {'email': email, 'code': code},
    );
    return ApiResponse.fromJson(
      response,
      (data) => PasswordVerifyResult.fromJson(
        data as Map<String, dynamic>? ?? const {},
      ),
    ).data;
  }

  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    await _client.post(
      ApiEndpoints.passwordReset,
      body: {'resetToken': resetToken, 'newPassword': newPassword},
    );
  }
}
