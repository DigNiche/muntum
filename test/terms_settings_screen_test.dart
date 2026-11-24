import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/api/api_exception.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/components/content_skeleton.dart';
import 'package:muntum/models/terms_model.dart';
import 'package:muntum/screens/mypage/common/terms_settings_screen.dart';
import 'package:muntum/screens/mypage/common/terms_detail_screen.dart';
import 'package:muntum/screens/onboarding/initial_screen.dart';
import 'package:muntum/screens/onboarding/sign_up_screens/sign_up.dart';
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

  testWidgets('no published optional terms means no consent switches', (
    tester,
  ) async {
    await pump(tester, TermsSettingsScreen(service: _SettingsService()));
    expect(find.text('현재 동의할 수 있는 선택 약관이 없습니다.'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNothing);
    expect(find.text('서비스 이용약관'), findsOneWidget);
    expect(find.text('개인정보 처리방침'), findsOneWidget);
  });

  testWidgets(
    'existing terms menu reader loads published content instead of hardcoded text',
    (tester) async {
      await pump(
        tester,
        TermsDetailScreen(title: '서비스 이용약관', service: TestTermsService()),
      );
      expect(find.textContaining('서버에서 받은 서비스 이용약관 본문'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('signup cannot continue when required terms cannot be loaded', (
    tester,
  ) async {
    await pump(
      tester,
      InitialScreen(termsService: TestTermsService(documents: [])),
    );
    await tester.tap(find.text('회원가입'));
    await tester.pumpAndSettle();
    expect(find.text('약관을 불러오지 못했어요. 다시 시도해주세요.'), findsOneWidget);
    expect(find.text('회원가입 시작하기'), findsOneWidget);
    await tester.tap(find.text('필수 항목 모두 동의하기'));
    await tester.pump();
    expect(_signupButton(tester).onTap, isNull);
    await tester.tap(find.text('회원가입 시작하기'));
    await tester.pumpAndSettle();
    expect(find.byType(SignUpScreen), findsNothing);
  });

  testWidgets('missing record shows T001, not invented toggles', (
    tester,
  ) async {
    final service = _SettingsService()
      ..readError = const ApiException(
        statusCode: 404,
        code: 'T001',
        message: '약관 동의 정보가 존재하지 않습니다',
      );
    await pump(tester, TermsSettingsScreen(service: service));
    expect(find.text('약관 동의 정보가 존재하지 않습니다'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNothing);
    expect(find.text('다시 시도'), findsOneWidget);
  });

  testWidgets(
    'inactive historical consent may be revoked but not newly granted',
    (tester) async {
      final service = _SettingsService()..consents['LOCATION_TERMS'] = true;
      await pump(tester, TermsSettingsScreen(service: service));
      expect(find.text('현재 게시되지 않은 약관입니다. 기존 동의를 철회할 수 있어요.'), findsOneWidget);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(service.changes.single.toJson(), {
        'termType': 'LOCATION_TERMS',
        'agreed': false,
      });
      expect(find.byType(SwitchListTile), findsNothing);
    },
  );

  testWidgets('published optional consent sends the displayed version', (
    tester,
  ) async {
    final service = _SettingsService()..documents.add(_marketing('2.0'));
    await pump(tester, TermsSettingsScreen(service: service));
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(service.changes.single.toJson(), {
      'termType': 'MARKETING_EMAIL',
      'agreed': true,
      'version': '2.0',
    });
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      true,
    );
  });

  testWidgets(
    'T007 reloads latest terms without silently granting a new version',
    (tester) async {
      final service = _SettingsService()
        ..documents.add(_marketing('2.0'))
        ..rejectNextVersion = true;
      await pump(tester, TermsSettingsScreen(service: service));
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(service.changes, hasLength(1));
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        false,
      );
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(service.changes.last.version, '3.0');
      expect(service.changes, hasLength(2));
    },
  );

  testWidgets(
    'pending terms show the form without skeletons and cannot submit',
    (tester) async {
      final service = _PendingTerms();
      await pump(tester, InitialScreen(termsService: service));
      await tester.tap(find.text('회원가입'));
      await tester.pumpAndSettle();
      expect(find.byType(SkeletonBlock), findsNothing);
      expect(find.text('서비스 이용약관 (필수)'), findsOneWidget);
      expect(find.text('개인정보 처리방침 (필수)'), findsOneWidget);
      expect(find.text('회원가입 시작하기'), findsOneWidget);
      await tester.tap(find.text('필수 항목 모두 동의하기'));
      await tester.pump();
      expect(_signupButton(tester).onTap, isNull);
      service.pending.complete([testServiceTerms, testPrivacyNotice]);
      await tester.pumpAndSettle();
      expect(find.text('회원가입 시작하기'), findsOneWidget);
      expect(_signupButton(tester).onTap, isNotNull);
    },
  );

  testWidgets(
    'optional refusal does not block signup and privacy is never submitted',
    (tester) async {
      await pump(
        tester,
        InitialScreen(
          termsService: TestTermsService(
            documents: [testServiceTerms, testPrivacyNotice, _marketing('2.0')],
          ),
        ),
      );
      await tester.tap(find.text('회원가입'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('필수 항목 모두 동의하기'));
      await tester.pump();
      await tester.tap(find.text('회원가입 시작하기'));
      await tester.pumpAndSettle();
      final signup = tester.widget<SignUpScreen>(find.byType(SignUpScreen));
      expect(signup.signupConsent.toJson(), {
        'agreements': [
          {'termType': 'TERMS_OF_SERVICE', 'agreed': true, 'version': '1.0.1'},
          {'termType': 'MARKETING_EMAIL', 'agreed': false, 'version': '2.0'},
        ],
      });
    },
  );
}

ButtonSolid _signupButton(WidgetTester tester) => tester.widget<ButtonSolid>(
  find.ancestor(of: find.text('회원가입 시작하기'), matching: find.byType(ButtonSolid)),
);

TermDocument _marketing(String version) => TermDocument(
  type: 'MARKETING_EMAIL',
  version: version,
  title: '이메일 마케팅 수신 동의',
  content: '선택 약관 본문',
  required: false,
);

class _PendingTerms extends TermsService {
  final pending = Completer<List<TermDocument>>();
  @override
  Future<List<TermDocument>> fetchActive() => pending.future;
}

class _SettingsService extends TermsService {
  final documents = [testServiceTerms, testPrivacyNotice];
  final consents = {for (final type in optionalTermTypes) type: false};
  final changes = <TermAgreement>[];
  Object? readError;
  bool rejectNextVersion = false;

  @override
  Future<List<TermDocument>> fetchActive() async => documents;
  @override
  Future<UserTermsState> fetchMyConsents() async {
    if (readError != null) throw readError!;
    return UserTermsState(
      optionalConsents: Map.of(consents),
      agreementVersions: {},
    );
  }

  @override
  Future<UserTermsState> updateOptional(List<TermAgreement> values) async {
    changes.addAll(values);
    if (rejectNextVersion) {
      rejectNextVersion = false;
      documents.removeWhere((document) => document.type == 'MARKETING_EMAIL');
      documents.add(_marketing('3.0'));
      throw const ApiException(
        code: 'T007',
        statusCode: 409,
        message: '약관이 변경되었습니다. 최신 약관을 확인해주세요',
      );
    }
    for (final change in values) {
      consents[change.type] = change.agreed;
    }
    return fetchMyConsents();
  }
}
