import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/api/api_exception.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/models/auth_models.dart';
import 'package:muntum/models/terms_model.dart';
import 'package:muntum/screens/onboarding/initial_screen.dart';
import 'package:muntum/screens/onboarding/sign_up_screens/nickname_screen.dart';
import 'package:muntum/services/apple_auth_service.dart';
import 'package:muntum/services/auth_service.dart';
import 'support/terms_fixtures.dart';

void main() {
  Future<void> pump(WidgetTester tester, _SocialAuth auth) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (_, _) => MaterialApp(
          home: InitialScreen(
            appleAuthService: _AppleAuth(),
            authService: auth,
            termsService: TestTermsService(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apple로 시작하기'));
    await tester.pumpAndSettle();
  }

  testWidgets('existing member goes to onboarding without another consent', (
    tester,
  ) async {
    final auth = _SocialAuth(existing: true);
    await pump(tester, auth);
    expect(find.byType(NicknameScreen), findsOneWidget);
    expect(find.text('회원가입 시작하기'), findsNothing);
    expect(auth.signupCalls, 0);
  }, variant: TargetPlatformVariant({TargetPlatform.iOS}));

  testWidgets('dismissing a new social signup ticket creates no account', (
    tester,
  ) async {
    final auth = _SocialAuth();
    await pump(tester, auth);
    expect(find.text('회원가입 시작하기'), findsOneWidget);
    await tester.tapAt(const Offset(30, 150));
    await tester.pumpAndSettle();
    expect(auth.signupCalls, 0);
    expect(find.byType(NicknameScreen), findsNothing);
    expect(find.text('Apple로 시작하기'), findsOneWidget);
  }, variant: TargetPlatformVariant({TargetPlatform.iOS}));

  testWidgets('new social signup uses one ticket after explicit agreement', (
    tester,
  ) async {
    final auth = _SocialAuth();
    await pump(tester, auth);
    await tester.tap(find.text('서비스 이용약관 (필수)'));
    await tester.pump();
    expect(
      tester
          .widget<ButtonSolid>(
            find.ancestor(
              of: find.text('회원가입 시작하기'),
              matching: find.byType(ButtonSolid),
            ),
          )
          .onTap,
      isNull,
    );
    expect(auth.signupCalls, 0);
    await tester.tap(find.text('개인정보 처리방침 (필수)'));
    await tester.pump();
    await tester.tap(find.text('회원가입 시작하기'));
    await tester.pumpAndSettle();
    expect(auth.signupCalls, 1);
    expect(auth.ticket, 'prepared-ticket');
    expect(auth.consent!.toJson(), testSignupConsent().toJson());
    expect(find.byType(NicknameScreen), findsOneWidget);
  }, variant: TargetPlatformVariant({TargetPlatform.iOS}));

  for (final code in ['A026', 'A027', 'A028', 'A029']) {
    testWidgets(
      '$code never automatically repeats social signup or Apple authentication',
      (tester) async {
        final auth = _SocialAuth()..failureCode = code;
        await pump(tester, auth);
        await tester.tap(find.text('필수 항목 모두 동의하기'));
        await tester.pump();
        await tester.tap(find.text('회원가입 시작하기'));
        await tester.pumpAndSettle();
        expect(auth.prepareCalls, 1);
        expect(auth.signupCalls, 1);
        expect(find.byType(NicknameScreen), findsNothing);
        expect(find.textContaining('[$code]'), findsOneWidget);
      },
      variant: TargetPlatformVariant({TargetPlatform.iOS}),
    );
  }
}

const _session = AuthSession(
  tokenType: 'Bearer',
  accessToken: 'access',
  accessExpiresIn: 3600000,
  refreshToken: 'refresh',
  refreshExpiresIn: 1209600000,
  userId: 'social-user',
  email: 'user@example.com',
);

class _AppleAuth extends AppleAuthService {
  @override
  Future<SocialLoginRequest> authorize() async => const SocialLoginRequest(
    provider: SocialAuthProvider.apple,
    token: 'identity',
    authorizationCode: 'one-use-code',
    nonce: 'nonce',
  );
}

class _SocialAuth extends AuthService {
  _SocialAuth({this.existing = false});
  final bool existing;
  int prepareCalls = 0;
  int signupCalls = 0;
  String? ticket;
  String? failureCode;
  SignupConsent? consent;

  @override
  Future<SocialPrepareResult> prepareSocial(SocialLoginRequest request) async {
    prepareCalls++;
    return existing
        ? const SocialPrepareResult.login(_session)
        : const SocialPrepareResult.signup(
            signupTicket: 'prepared-ticket',
            expiresIn: 600,
          );
  }

  @override
  Future<AuthSession> signupSocial({
    required String signupTicket,
    required SocialAuthProvider provider,
    required SignupConsent signupConsent,
  }) async {
    signupCalls++;
    ticket = signupTicket;
    consent = signupConsent;
    if (failureCode != null) {
      throw ApiException(code: failureCode, message: '재인증 후 상태를 확인해주세요.');
    }
    return _session;
  }
}
