import 'dart:io';

import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:muntum/models/terms_model.dart';
import 'package:muntum/screens/mypage/common/terms_detail_screen.dart';
import 'package:muntum/screens/mypage/common/terms_screen.dart';
import 'package:muntum/screens/mypage/common/terms_settings_screen.dart';
import 'package:muntum/screens/onboarding/initial_screen.dart';
import 'package:muntum/services/terms_service.dart';
import 'support/terms_fixtures.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (_, _) => MaterialApp(home: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  void expectSuppliedPolicy(WidgetTester tester) {
    final body = tester.widget<MarkdownBody>(find.byType(MarkdownBody));
    expect(
      body.data.trim(),
      File('assets/documents/privacy_policy.md').readAsStringSync().trim(),
    );
    for (var article = 1; article <= 11; article++) {
      expect(body.data, contains('## 제 $article 조 ('));
    }
    expect(body.data, contains('최대 14개월'));
    expect(body.data, contains('이메일이나 닉네임이 아닌 서비스 내부 회원 식별자'));
    expect(body.data, contains('https://policies.google.com/privacy'));
    expect(body.data, contains('https://firebase.google.com/support/privacy'));
    expect(body.data, contains('mailto:muntum510@gmail.com'));
    expect(body.onTapLink, isNotNull);
    expect(tester.takeException(), isNull);
  }

  testWidgets('terms menu opens the full supplied privacy policy', (
    tester,
  ) async {
    await pump(tester, const TermsScreen());
    await tester.tap(find.text('개인정보 처리 방침'));
    await tester.pumpAndSettle();
    expectSuppliedPolicy(tester);
  });

  testWidgets('privacy content is available without a terms API connection', (
    tester,
  ) async {
    final service = _UnavailableTerms();
    await pump(tester, TermsDetailScreen(title: '개인정보 처리방침', service: service));
    expect(service.calls, 0);
    expectSuppliedPolicy(tester);
  });

  testWidgets(
    'privacy type uses the supplied notice rather than stale content',
    (tester) async {
      await pump(
        tester,
        const TermsDetailScreen(
          title: '개인정보 보호 안내',
          termType: 'PRIVACY_POLICY',
          content: '이전 서버 개인정보 처리방침',
        ),
      );
      expectSuppliedPolicy(tester);
      expect(find.textContaining('이전 서버 개인정보 처리방침'), findsNothing);
    },
  );

  testWidgets('signup reader also shows the supplied notice', (tester) async {
    await pump(tester, InitialScreen(termsService: TestTermsService()));
    await tester.tap(find.text('회원가입'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('개인정보 처리방침 자세히 보기'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TermsDetailScreen>(find.byType(TermsDetailScreen)).termType,
      'PRIVACY_POLICY',
    );
    expectSuppliedPolicy(tester);
  });

  testWidgets('optional terms settings open the same supplied privacy policy', (
    tester,
  ) async {
    await pump(tester, TermsSettingsScreen(service: _SettingsTerms()));
    await tester.tap(find.text('개인정보 처리방침'));
    await tester.pumpAndSettle();
    expectSuppliedPolicy(tester);
  });

  testWidgets('service terms still use the exact versioned content', (
    tester,
  ) async {
    final service = _UnavailableTerms();
    await pump(
      tester,
      TermsDetailScreen(
        title: '서비스 이용약관',
        termType: 'TERMS_OF_SERVICE',
        content: '동의할 버전에 해당하는 서버의 서비스 이용약관',
        service: service,
      ),
    );
    expect(service.calls, 0);
    expect(
      tester.widget<MarkdownBody>(find.byType(MarkdownBody)).data,
      '동의할 버전에 해당하는 서버의 서비스 이용약관',
    );
  });
}

class _UnavailableTerms extends TermsService {
  int calls = 0;

  @override
  Future<List<TermDocument>> fetchActive() async {
    calls++;
    throw const FormatException('offline');
  }
}

class _SettingsTerms extends TestTermsService {
  @override
  Future<UserTermsState> fetchMyConsents() async => UserTermsState(
    optionalConsents: {for (final type in optionalTermTypes) type: false},
    agreementVersions: const {},
  );
}
