import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:muntum/models/auth_models.dart';
import 'package:muntum/services/user_service.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleAuthService {
  AppleAuthService({UserService? userService})
    : _userService = userService ?? UserService();

  final UserService _userService;

  Future<SocialLoginRequest> authorize() async {
    final rawNonce = generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );
    final identityToken = credential.identityToken;
    if (identityToken == null || identityToken.isEmpty) {
      throw const AppleCredentialException('Apple identity token이 없습니다.');
    }
    if (credential.authorizationCode.isEmpty) {
      throw const AppleCredentialException('Apple authorization code가 없습니다.');
    }
    return SocialLoginRequest(
      provider: SocialAuthProvider.apple,
      token: identityToken,
      authorizationCode: credential.authorizationCode,
      // The backend currently compares this value directly with the nonce
      // claim issued for the value sent to Apple.
      nonce: hashedNonce,
    );
  }

  Future<void> withdraw({SocialLoginRequest? authorization}) async {
    final request = authorization ?? await authorize();
    await _userService.withdrawWithApple(
      token: request.token,
      authorizationCode: request.authorizationCode,
      nonce: request.nonce,
    );
  }
}

class AppleCredentialException implements Exception {
  final String message;

  const AppleCredentialException(this.message);

  @override
  String toString() => message;
}
