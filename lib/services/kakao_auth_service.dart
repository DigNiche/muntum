import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:muntum/constants/kakao_config.dart';
import 'package:muntum/models/auth_models.dart';

class KakaoAuthClient {
  Future<bool> isTalkInstalled() async {
    if (!KakaoConfig.isConfigured) {
      throw const KakaoLoginException(
        code: 'KAKAO_NOT_CONFIGURED',
        message: '카카오 로그인 설정이 준비되지 않았어요.',
      );
    }
    return kakao.isKakaoTalkInstalled();
  }

  Future<String> loginWithTalk() async =>
      (await kakao.UserApi.instance.loginWithKakaoTalk()).accessToken;

  Future<String> loginWithAccount() async =>
      (await kakao.UserApi.instance.loginWithKakaoAccount()).accessToken;
}

class KakaoAuthService {
  KakaoAuthService({KakaoAuthClient? client})
    : _client = client ?? KakaoAuthClient();

  final KakaoAuthClient _client;

  Future<SocialLoginRequest> authorize() async {
    try {
      final token = await _requestAccessToken();
      if (token.trim().isEmpty) {
        throw const KakaoLoginException(
          code: 'KAKAO_TOKEN_MISSING',
          message: '카카오 인증 정보를 확인하지 못했어요. 다시 로그인해주세요.',
        );
      }
      return SocialLoginRequest(
        provider: SocialAuthProvider.kakao,
        token: token,
      );
    } on Exception catch (error) {
      if (_isCancellation(error)) throw const KakaoLoginCanceledException();
      if (error is KakaoLoginException) rethrow;
      // Never surface the SDK's raw error body, which may contain credentials.
      throw KakaoLoginException(
        code: switch (error) {
          kakao.KakaoAuthException(:final error) => error.name,
          kakao.KakaoClientException(:final reason) => reason.name,
          PlatformException(:final code) => code,
          MissingPluginException() => 'KAKAO_PLUGIN_MISSING',
          _ => 'KAKAO_AUTH_FAILED',
        },
        message: '카카오 로그인에 실패했어요. 다시 시도해주세요.',
      );
    }
  }

  Future<String> _requestAccessToken() async {
    if (!await _client.isTalkInstalled()) {
      return _client.loginWithAccount();
    }
    try {
      return await _client.loginWithTalk();
    } on Exception catch (error) {
      // A deliberate cancel must not unexpectedly open another login screen.
      if (_isCancellation(error)) rethrow;
      return _client.loginWithAccount();
    }
  }

  bool _isCancellation(Exception error) =>
      error is PlatformException && error.code == 'CANCELED' ||
      error is kakao.KakaoClientException &&
          error.reason == kakao.ClientErrorCause.cancelled ||
      error is kakao.KakaoAuthException &&
          error.error == kakao.AuthErrorCause.accessDenied;
}

class KakaoLoginCanceledException implements Exception {
  const KakaoLoginCanceledException();
}

class KakaoLoginException implements Exception {
  const KakaoLoginException({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String toString() => message;
}
