import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/api/api_exception.dart';
import 'package:muntum/models/auth_models.dart';
import 'package:muntum/screens/onboarding/find_password_screens/verification_code_screen.dart';
import 'package:muntum/services/auth_service.dart';

void main() {
  testWidgets(
    'A013 discards the old password code until a new code is requested',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = _LimitedAuth();
      await tester.pumpWidget(
        ScreenUtilPlusInit(
          designSize: const Size(390, 844),
          builder: (_, _) => MaterialApp(
            home: VerificationCodeScreen(
              email: 'user@example.com',
              expiresIn: 300,
              authService: service,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), '123456');
      await tester.tap(find.text('다음으로'));
      await tester.pumpAndSettle();
      expect(service.verifyCalls, 1);
      expect(find.text('만료'), findsOneWidget);
      expect(find.text('인증 시도 횟수를 초과했습니다. 인증번호를 다시 요청해주세요.'), findsOneWidget);
      await tester.tap(find.text('다음으로'));
      await tester.pump();
      expect(service.verifyCalls, 1);
      await tester.tap(find.text('재발송'));
      await tester.pumpAndSettle();
      expect(service.resendCalls, 1);
      expect(find.text('05:00'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

class _LimitedAuth extends AuthService {
  int verifyCalls = 0;
  int resendCalls = 0;
  @override
  Future<PasswordVerifyResult> verifyPasswordCode({
    required String email,
    required String code,
  }) async {
    verifyCalls++;
    throw const ApiException(
      statusCode: 429,
      code: 'A013',
      message: '인증 시도 횟수를 초과했습니다.',
    );
  }

  @override
  Future<PasswordFindResult> requestPasswordCode(String email) async {
    resendCalls++;
    return const PasswordFindResult(expiresIn: 300, resendAfter: 60);
  }
}
