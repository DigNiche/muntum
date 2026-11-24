import 'dart:async';

import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:muntum/api/api_exception.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/models/auth_models.dart';
import 'package:muntum/models/terms_model.dart';
import 'package:muntum/screens/onboarding/initial_screen.dart';
import 'package:muntum/screens/onboarding/sign_up_screens/nickname_screen.dart';
import 'package:muntum/services/auth_service.dart';
import 'package:muntum/services/kakao_auth_service.dart';
import 'support/terms_fixtures.dart';

void main() {
  Future<void> pump(WidgetTester tester, _Auth auth, {_Kakao? kakao}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (_, _) => MaterialApp(
          home: InitialScreen(
            kakaoAuthService: kakao ?? _Kakao(),
            authService: auth,
            termsService: TestTermsService(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('카카오 로그인'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'existing Kakao member logs in without another signup',
    (tester) async {
      final auth = _Auth(existing: true);
      await pump(tester, auth);
      expect(auth.prepared.single.toJson(), {
        'provider': 'KAKAO',
        'token': 'kakao-access-token',
      });
      expect(auth.signupCalls, 0);
      expect(find.byType(NicknameScreen), findsOneWidget);
      expect(find.text('회원가입 시작하기'), findsNothing);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.iOS,
      TargetPlatform.android,
    }),
  );

  testWidgets('new Kakao member submits ticket and consent only', (
    tester,
  ) async {
    final auth = _Auth();
    await pump(tester, auth);
    expect(auth.signupCalls, 0);
    await tester.tap(find.text('서비스 이용약관 (필수)'));
    await tester.pump();
    expect(_button(tester, '회원가입 시작하기').onTap, isNull);
    await tester.tap(find.text('개인정보 처리방침 (필수)'));
    await tester.pump();
    await tester.tap(find.text('회원가입 시작하기'));
    await tester.pumpAndSettle();
    expect(auth.prepared, hasLength(1));
    expect(auth.signupCalls, 1);
    expect(auth.signupProvider, SocialAuthProvider.kakao);
    expect(auth.ticket, 'kakao-signup-ticket');
    expect(auth.consent!.toJson(), testSignupConsent().toJson());
    expect(find.byType(NicknameScreen), findsOneWidget);
  });

  testWidgets('dismissing Kakao signup creates no account', (tester) async {
    final auth = _Auth();
    await pump(tester, auth);
    await tester.tapAt(const Offset(30, 150));
    await tester.pumpAndSettle();
    expect(auth.prepared, hasLength(1));
    expect(auth.signupCalls, 0);
    expect(find.byType(NicknameScreen), findsNothing);
    expect(_button(tester, '카카오 로그인').onTap, isNotNull);
  });

  testWidgets('canceling Kakao authorization makes no backend request', (
    tester,
  ) async {
    final auth = _Auth();
    await pump(tester, auth, kakao: _Kakao()..cancel = true);
    expect(auth.prepared, isEmpty);
    expect(auth.signupCalls, 0);
    expect(find.byType(SnackBar), findsNothing);
    expect(_button(tester, '카카오 로그인').onTap, isNotNull);
  });

  testWidgets('only one social authorization may run at a time', (
    tester,
  ) async {
    final kakao = _Kakao()..pending = Completer<SocialLoginRequest>();
    final auth = _Auth(existing: true);
    await pump(tester, auth, kakao: kakao);
    expect(kakao.calls, 1);
    expect(_button(tester, '카카오 로그인 중...').onTap, isNull);
    expect(_button(tester, 'Apple로 시작하기').onTap, isNull);
    expect(auth.prepared, isEmpty);
    kakao.pending!.complete(_request);
    await tester.pumpAndSettle();
    expect(kakao.calls, 1);
    expect(auth.prepared, hasLength(1));
    expect(find.byType(NicknameScreen), findsOneWidget);
  }, variant: TargetPlatformVariant({TargetPlatform.iOS}));

  testWidgets('undeployed server is reported without retrying legacy login', (
    tester,
  ) async {
    final auth = _Auth()
      ..prepareError = const ApiException(
        statusCode: 404,
        message: 'Not Found',
      );
    await pump(tester, auth);
    expect(auth.prepared, hasLength(1));
    expect(auth.signupCalls, 0);
    expect(find.textContaining('카카오 로그인 서버가 아직 준비되지 않았어요.'), findsOneWidget);
    expect(_button(tester, '카카오 로그인').onTap, isNotNull);
  });

  testWidgets('expired signup ticket requires another explicit login', (
    tester,
  ) async {
    final auth = _Auth()
      ..signupError = const ApiException(code: 'A026', message: '인증이 만료되었습니다.');
    await pump(tester, auth);
    await tester.tap(find.text('필수 항목 모두 동의하기'));
    await tester.pump();
    await tester.tap(find.text('회원가입 시작하기'));
    await tester.pumpAndSettle();
    expect(auth.prepared, hasLength(1));
    expect(auth.signupCalls, 1);
    expect(find.textContaining('[A026]'), findsOneWidget);
    expect(find.byType(NicknameScreen), findsNothing);
  });
}

ButtonSolid _button(WidgetTester tester, String label) =>
    tester.widget<ButtonSolid>(
      find.ancestor(of: find.text(label), matching: find.byType(ButtonSolid)),
    );

const _request = SocialLoginRequest(
  provider: SocialAuthProvider.kakao,
  token: 'kakao-access-token',
);

const _session = AuthSession(
  tokenType: 'Bearer',
  accessToken: 'muntum-access-token',
  accessExpiresIn: 3600000,
  refreshToken: 'muntum-refresh-token',
  refreshExpiresIn: 1209600000,
  userId: 'kakao-user',
  email: 'user@example.com',
);

class _Kakao extends KakaoAuthService {
  int calls = 0;
  bool cancel = false;
  Completer<SocialLoginRequest>? pending;

  @override
  Future<SocialLoginRequest> authorize() async {
    calls++;
    if (cancel) throw const KakaoLoginCanceledException();
    return pending == null ? _request : await pending!.future;
  }
}

class _Auth extends AuthService {
  _Auth({this.existing = false});
  final bool existing;
  final prepared = <SocialLoginRequest>[];
  int signupCalls = 0;
  SocialAuthProvider? signupProvider;
  String? ticket;
  SignupConsent? consent;
  ApiException? prepareError;
  ApiException? signupError;

  @override
  Future<SocialPrepareResult> prepareSocial(SocialLoginRequest request) async {
    prepared.add(request);
    if (prepareError != null) throw prepareError!;
    return existing
        ? const SocialPrepareResult.login(_session)
        : const SocialPrepareResult.signup(
            signupTicket: 'kakao-signup-ticket',
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
    signupProvider = provider;
    ticket = signupTicket;
    consent = signupConsent;
    if (signupError != null) throw signupError!;
    return _session;
  }
}
