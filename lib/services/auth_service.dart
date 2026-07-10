import 'package:muntum/api/api_client.dart';
import 'package:muntum/api/api_endpoints.dart';
import 'package:muntum/api/api_response.dart';
import 'package:muntum/api/token_store.dart';
import 'package:muntum/models/auth_models.dart';

class AuthService {
  AuthService({ApiClient? client, TokenStore? tokenStore})
    : _client = client ?? ApiClient(),
      _tokenStore = tokenStore ?? TokenStore.instance;

  final ApiClient _client;
  final TokenStore _tokenStore;

  Future<SignupResult> signup({
    required String email,
    required String password,
    String role = 'AUDIENCE',
    String userTermsAgreementVersion = '1.0',
  }) async {
    final response = await _client.post(
      ApiEndpoints.signup,
      body: {
        'email': email,
        'password': password,
        'role': role,
        'userTermsAgreementVersion': userTermsAgreementVersion,
      },
    );
    return ApiResponse.fromJson(
      response,
      (data) =>
          SignupResult.fromJson(data as Map<String, dynamic>? ?? const {}),
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
    await _tokenStore.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      userId: session.userId,
      email: session.email,
      nickname: session.nickname,
    );
    return session;
  }

  Future<AuthSession?> refresh() async {
    final refreshToken = await _tokenStore.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    final response = await _client.post(
      ApiEndpoints.refresh,
      body: {'refreshToken': refreshToken},
    );
    final session = ApiResponse.fromJson(
      response,
      (data) => AuthSession.fromJson(data as Map<String, dynamic>? ?? const {}),
    ).data;
    await _tokenStore.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      userId: session.userId,
      email: session.email,
      nickname: session.nickname,
    );
    return session;
  }

  Future<void> logout() async {
    try {
      await _client.post(ApiEndpoints.logout, authorized: true);
    } catch (_) {
      // Even when the server rejects logout because the token is expired,
      // deleted, or no longer authorized, the local session must be cleared.
    } finally {
      await _tokenStore.clear();
    }
  }

  Future<void> requestPasswordCode(String email) async {
    await _client.post(ApiEndpoints.passwordFind, body: {'email': email});
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
