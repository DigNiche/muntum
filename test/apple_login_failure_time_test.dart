import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/api/api_exception.dart';
import 'package:muntum/models/auth_models.dart';
import 'package:muntum/screens/onboarding/initial_screen.dart';
import 'package:muntum/services/apple_auth_service.dart';
import 'package:muntum/services/auth_service.dart';

void main() {
  testWidgets(
    'Apple failure keeps diagnostics in debug console, not the toast',
    (tester) async {
      final logs = <String>[];
      final previousDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logs.add(message);
      };
      addTearDown(() => debugPrint = previousDebugPrint);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ScreenUtilPlusInit(
          designSize: const Size(390, 844),
          builder: (_, _) => MaterialApp(
            home: InitialScreen(
              appleAuthService: _AppleAuthorization(),
              authService: _FailingAuthService(),
            ),
          ),
        ),
      );
      final before = DateTime.now().toUtc();
      await tester.tap(find.text('Apple로 시작하기'));
      await tester.pumpAndSettle();
      debugPrint = previousDebugPrint;
      final errorText = find.textContaining('[A001]');
      expect(errorText, findsOneWidget);
      final message = tester.widget<Text>(errorText).data!;
      expect(message, '[A001] 이미 사용 중인 이메일입니다.');
      final log = logs.singleWhere(
        (value) => value.startsWith('[muntum.apple_login]'),
      );
      expect(log, contains('stage=social_login code=A001 http=409'));
      final date = RegExp(r'occurredAt=(\S+)').firstMatch(log)!.group(1)!;
      final occurredAt = DateTime.parse(date);
      expect(occurredAt.isBefore(before), isFalse);
      expect(occurredAt.isAfter(DateTime.now().toUtc()), isFalse);
      expect(
        tester.renderObject<RenderParagraph>(errorText).didExceedMaxLines,
        isFalse,
      );
      expect(
        tester.widget<SnackBar>(find.byType(SnackBar)).duration,
        const Duration(seconds: 2),
      );
      expect(message, isNot(contains('test-identity-token')));
      expect(log, contains('sub=001234.abcdefghijklmnopqrstuvwx.1234'));
      expect(message, isNot(contains('sub')));
      expect(message, isNot(contains('발생 시각')));
      expect(message, isNot(contains('private@example.com')));
      expect(message, isNot(contains('test-signature')));
      expect(log, isNot(contains('private@example.com')));
      expect(log, isNot(contains('test-signature')));
    },
    variant: TargetPlatformVariant({TargetPlatform.iOS}),
  );
}

class _AppleAuthorization extends AppleAuthService {
  @override
  Future<SocialLoginRequest> authorize() async => SocialLoginRequest(
    provider: SocialAuthProvider.apple,
    token:
        'test-header.${base64Url.encode(utf8.encode(jsonEncode({'sub': '001234.abcdefghijklmnopqrstuvwx.1234', 'email': 'private@example.com'}))).replaceAll('=', '')}.test-signature',
    authorizationCode: 'test-code',
    nonce: 'test-nonce',
  );
}

class _FailingAuthService extends AuthService {
  @override
  Future<AuthSession> socialLogin(SocialLoginRequest request) async {
    throw const ApiException(
      statusCode: 409,
      code: 'A001',
      message: '이미 사용 중인 이메일입니다.',
    );
  }
}
