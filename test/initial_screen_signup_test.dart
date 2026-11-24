import 'dart:async';

import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/components/content_skeleton.dart';
import 'package:muntum/models/terms_model.dart';
import 'package:muntum/screens/mypage/common/terms_detail_screen.dart';
import 'package:muntum/screens/onboarding/initial_screen.dart';
import 'package:muntum/screens/onboarding/sign_up_screens/sign_up.dart';
import 'support/terms_fixtures.dart';

void main() {
  testWidgets(
    'shows the Kakao button without a login action or old terms footer',
    (tester) async {
      await _pumpLogin(tester);

      final kakao = _button(tester, '카카오 로그인');
      expect(kakao.boxColor, const Color(0xFFFEE500));
      expect(
        (kakao.leading as SvgPicture).bytesLoader,
        isA<SvgAssetLoader>().having(
          (loader) => loader.assetName,
          'assetName',
          'assets/icons/kakao_login.svg',
        ),
      );
      expect(kakao.onTap, isNull);
      expect(find.text('회원가입 시 문틈의 정책 및 약관에 동의합니다.'), findsNothing);
      expect(find.text('서비스 이용약관'), findsNothing);
      expect(find.text('개인정보 처리방침'), findsNothing);
      expect(
        find.text('Apple로 시작하기'),
        Theme.of(tester.element(find.byType(InitialScreen))).platform ==
                TargetPlatform.iOS
            ? findsOneWidget
            : findsNothing,
      );
    },
    variant: TargetPlatformVariant({
      TargetPlatform.iOS,
      TargetPlatform.android,
    }),
  );

  testWidgets(
    'requires both checkboxes but submits only the service agreement',
    (tester) async {
      await _pumpLogin(tester);
      await _tapText(tester, '회원가입');
      expect(find.byType(SignUpScreen), findsNothing);
      expect(_button(tester, '회원가입 시작하기').onTap, isNull);
      await _tapText(tester, '회원가입 시작하기');
      expect(find.byType(SignUpScreen), findsNothing);

      await _tapText(tester, '서비스 이용약관 (필수)');
      expect(find.text('개인정보 처리방침 (필수)'), findsOneWidget);
      expect(find.text('개인정보 처리방침 (고지)'), findsNothing);
      expect(_button(tester, '회원가입 시작하기').onTap, isNull);
      await _tapText(tester, '개인정보 처리방침 (필수)');
      expect(_button(tester, '회원가입 시작하기').onTap, isNotNull);
      await _tapText(tester, '개인정보 처리방침 (필수)');
      expect(_button(tester, '회원가입 시작하기').onTap, isNull);
      await _tapText(tester, '개인정보 처리방침 (필수)');
      await _tapText(tester, '서비스 이용약관 (필수)');
      expect(_button(tester, '회원가입 시작하기').onTap, isNull);
      await _tapText(tester, '서비스 이용약관 (필수)');
      await _tapText(tester, '회원가입 시작하기');
      expect(find.byType(SignUpScreen), findsOneWidget);
      final consent = tester
          .widget<SignUpScreen>(find.byType(SignUpScreen))
          .signupConsent;
      expect(consent.toJson(), {
        'agreements': [
          {'termType': 'TERMS_OF_SERVICE', 'version': '1.0.1', 'agreed': true},
        ],
      });
    },
  );

  testWidgets('select all toggles both required rows but not optional terms', (
    tester,
  ) async {
    await _pumpLogin(
      tester,
      termsService: TestTermsService(
        documents: const [
          testServiceTerms,
          testPrivacyNotice,
          TermDocument(
            type: 'MARKETING_EMAIL',
            version: '2.0',
            title: '이메일 마케팅 수신',
            content: '선택 약관 본문',
            required: false,
          ),
        ],
      ),
    );
    await _tapText(tester, '회원가입');
    expect(_isChecked(tester, '서비스 이용약관 (필수)'), isFalse);
    expect(_isChecked(tester, '개인정보 처리방침 (필수)'), isFalse);

    await _tapText(tester, '필수 항목 모두 동의하기');
    expect(_isChecked(tester, '서비스 이용약관 (필수)'), isTrue);
    expect(_isChecked(tester, '개인정보 처리방침 (필수)'), isTrue);
    expect(_isChecked(tester, '이메일 마케팅 수신 (선택)'), isFalse);

    await _tapText(tester, '필수 항목 모두 동의하기');
    expect(_isChecked(tester, '서비스 이용약관 (필수)'), isFalse);
    expect(_isChecked(tester, '개인정보 처리방침 (필수)'), isFalse);
    expect(_button(tester, '회원가입 시작하기').onTap, isNull);

    await _tapText(tester, '필수 항목 모두 동의하기');
    await _tapText(tester, '이메일 마케팅 수신 (선택)');
    await _tapText(tester, '회원가입 시작하기');
    final consent = tester
        .widget<SignUpScreen>(find.byType(SignUpScreen))
        .signupConsent;
    expect(consent.toJson(), {
      'agreements': [
        {'termType': 'TERMS_OF_SERVICE', 'version': '1.0.1', 'agreed': true},
        {'termType': 'MARKETING_EMAIL', 'version': '2.0', 'agreed': true},
      ],
    });
  });

  testWidgets('reading privacy does not automatically check its row', (
    tester,
  ) async {
    await _pumpLogin(tester);
    await _tapText(tester, '회원가입');
    await _tapText(tester, '서비스 이용약관 (필수)');
    await tester.tap(find.byTooltip('개인정보 처리방침 자세히 보기'));
    await tester.pumpAndSettle();
    expect(find.byType(TermsDetailScreen), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AppBarWidget),
        matching: find.byType(GestureDetector),
      ),
    );
    await tester.pumpAndSettle();
    expect(_isChecked(tester, '서비스 이용약관 (필수)'), isTrue);
    expect(_isChecked(tester, '개인정보 처리방침 (필수)'), isFalse);
    expect(_button(tester, '회원가입 시작하기').onTap, isNull);
  });

  testWidgets('opens existing terms details and preserves consent selections', (
    tester,
  ) async {
    await _pumpLogin(tester);
    await _tapText(tester, '회원가입');
    await _tapText(tester, '필수 항목 모두 동의하기');
    expect(_button(tester, '회원가입 시작하기').onTap, isNotNull);

    for (final title in ['서비스 이용약관', '개인정보 처리방침']) {
      await tester.tap(find.byTooltip('$title 자세히 보기'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TermsDetailScreen>(find.byType(TermsDetailScreen)).title,
        title,
      );
      await tester.tap(
        find.descendant(
          of: find.byType(AppBarWidget),
          matching: find.byType(GestureDetector),
        ),
      );
      await tester.pumpAndSettle();
      expect(_button(tester, '회원가입 시작하기').onTap, isNotNull);
    }

    await _tapText(tester, '필수 항목 모두 동의하기');
    expect(_button(tester, '회원가입 시작하기').onTap, isNull);
  });

  testWidgets('dismissing consent returns to login and resets selections', (
    tester,
  ) async {
    await _pumpLogin(tester);
    await _tapText(tester, '회원가입');
    await _tapText(tester, '필수 항목 모두 동의하기');
    await tester.tapAt(const Offset(30, 150));
    await tester.pumpAndSettle();
    expect(find.byType(SignUpScreen), findsNothing);
    expect(find.text('회원가입 시작하기'), findsNothing);

    await _tapText(tester, '회원가입');
    expect(_button(tester, '회원가입 시작하기').onTap, isNull);
  });

  testWidgets(
    'shows terms immediately but waits for real versions to continue',
    (tester) async {
      final service = _ControllableTermsService();
      await _pumpLogin(tester, termsService: service);
      await _tapText(tester, '회원가입');

      expect(find.byType(SkeletonBlock), findsNothing);
      expect(find.text('서비스 이용약관 (필수)'), findsOneWidget);
      expect(find.text('개인정보 처리방침 (필수)'), findsOneWidget);
      expect(find.text('회원가입 시작하기'), findsOneWidget);
      final buttonPosition = tester.getTopLeft(find.text('회원가입 시작하기'));
      expect(_detailsButton(tester, '서비스 이용약관').onPressed, isNull);
      await _tapText(tester, '필수 항목 모두 동의하기');
      expect(_isChecked(tester, '서비스 이용약관 (필수)'), isTrue);
      expect(_isChecked(tester, '개인정보 처리방침 (필수)'), isTrue);
      expect(_button(tester, '회원가입 시작하기').onTap, isNull);
      await _tapText(tester, '회원가입 시작하기');
      expect(find.byType(SignUpScreen), findsNothing);

      service.requests.single.complete(const [
        TermDocument(
          type: 'TERMS_OF_SERVICE',
          version: '2.3.0',
          title: '서비스 이용약관',
          content: '최신 서비스 이용약관 본문',
          required: true,
        ),
        testPrivacyNotice,
      ]);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('회원가입 시작하기')), buttonPosition);
      expect(_button(tester, '회원가입 시작하기').onTap, isNotNull);
      expect(_detailsButton(tester, '서비스 이용약관').onPressed, isNotNull);
      await _tapText(tester, '회원가입 시작하기');
      expect(
        tester
            .widget<SignUpScreen>(find.byType(SignUpScreen))
            .signupConsent
            .toJson(),
        {
          'agreements': [
            {
              'termType': 'TERMS_OF_SERVICE',
              'version': '2.3.0',
              'agreed': true,
            },
          ],
        },
      );
    },
  );

  testWidgets('keeps the form on failure and permits retry without skeletons', (
    tester,
  ) async {
    final service = _ControllableTermsService();
    await _pumpLogin(tester, termsService: service);
    await _tapText(tester, '회원가입');
    await _tapText(tester, '필수 항목 모두 동의하기');
    service.requests.single.completeError(StateError('offline'));
    await tester.pumpAndSettle();

    expect(find.text('서비스 이용약관 (필수)'), findsOneWidget);
    expect(find.text('개인정보 처리방침 (필수)'), findsOneWidget);
    expect(find.text('약관을 불러오지 못했어요. 다시 시도해주세요.'), findsOneWidget);
    expect(_button(tester, '회원가입 시작하기').onTap, isNull);
    await _tapText(tester, '다시 시도');
    expect(service.requests, hasLength(2));
    expect(find.byType(SkeletonBlock), findsNothing);
    expect(find.text('서비스 이용약관 (필수)'), findsOneWidget);
    expect(_button(tester, '회원가입 시작하기').onTap, isNull);

    service.requests.last.complete(const [testServiceTerms, testPrivacyNotice]);
    await tester.pumpAndSettle();
    expect(find.text('약관을 불러오지 못했어요. 다시 시도해주세요.'), findsNothing);
    await _tapText(tester, '필수 항목 모두 동의하기');
    expect(_button(tester, '회원가입 시작하기').onTap, isNotNull);
  });
}

class _ControllableTermsService extends TestTermsService {
  final requests = <Completer<List<TermDocument>>>[];

  @override
  Future<List<TermDocument>> fetchActive() {
    final request = Completer<List<TermDocument>>();
    requests.add(request);
    return request.future;
  }
}

Future<void> _pumpLogin(
  WidgetTester tester, {
  TestTermsService? termsService,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ScreenUtilPlusInit(
      designSize: const Size(390, 844),
      builder: (_, _) => MaterialApp(
        home: InitialScreen(termsService: termsService ?? TestTermsService()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

ButtonSolid _button(WidgetTester tester, String text) {
  return tester.widget<ButtonSolid>(
    find.ancestor(of: find.text(text), matching: find.byType(ButtonSolid)),
  );
}

IconButton _detailsButton(WidgetTester tester, String title) =>
    tester.widget<IconButton>(
      find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == '$title 자세히 보기',
      ),
    );

bool _isChecked(WidgetTester tester, String text) => tester
    .widgetList<Semantics>(
      find.ancestor(of: find.text(text), matching: find.byType(Semantics)),
    )
    .singleWhere((widget) => widget.properties.checked != null)
    .properties
    .checked!;
