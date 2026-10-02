import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/api/api_response.dart';
import 'package:muntum/models/admin_user_model.dart';
import 'package:muntum/models/curator_application_model.dart';
import 'package:muntum/screens/mypage/manager/curator_application_review_screen.dart';
import 'package:muntum/services/admin_user_service.dart';
import 'package:muntum/services/curator_application_service.dart';

void main() {
  final application = CuratorApplicationModel.fromJson({
    'id': 'application-1',
    'applicant': {
      'userId': 'applicant-1',
      'email': 'applicant@example.com',
      'nickname': '지원자',
      'role': 'AUDIENCE',
      'joinedAt': '2026-09-29',
    },
    'portfolio': {'programName': '프로그램', 'tagline': '한줄소개', 'curation': '소개글'},
    'statusInfo': {'status': 'PENDING'},
  });

  Future<void> pumpReview(WidgetTester tester, AdminUserService users) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (_, _) => MaterialApp(
          home: CuratorApplicationReviewScreen(
            applicationId: application.id,
            initialApplication: application,
            service: _FakeApplicationService(application),
            userService: users,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('applicant profile opens shared sheet with matching user stats', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final users = _FakeUserService();
    await pumpReview(tester, users);

    await tester.tap(
      find.byKey(const ValueKey('application-applicant-profile')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byKey(const ValueKey('user-profile-sheet')), findsOneWidget);
    expect(find.text('가입일: 2026.09.29'), findsOneWidget);
    expect(find.text('스크랩 12'), findsOneWidget);
    expect(find.text('제보 3'), findsOneWidget);
    expect(find.text('작성글 -'), findsNothing);
    expect(users.searchedEmail, 'applicant@example.com');
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile keeps known fields and does not invent stats on error', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final users = _FakeUserService(shouldFail: true);
    await pumpReview(tester, users);

    await tester.tap(
      find.byKey(const ValueKey('application-applicant-profile')),
    );
    await tester.pumpAndSettle();

    expect(find.text('가입일: 2026.09.29'), findsOneWidget);
    expect(find.text('스크랩 -'), findsOneWidget);
    expect(find.text('제보 -'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('user lookup only accepts the applicant ID', () async {
    final users = _FakeUserService();
    expect(
      await users.findUserById(
        userId: 'someone-else',
        email: 'applicant@example.com',
      ),
      isNull,
    );
  });
}

class _FakeApplicationService extends CuratorApplicationService {
  _FakeApplicationService(this.application);

  final CuratorApplicationModel application;

  @override
  Future<CuratorApplicationModel> fetchDetail(String id) async => application;
}

class _FakeUserService extends AdminUserService {
  _FakeUserService({this.shouldFail = false});

  final bool shouldFail;
  String? searchedEmail;

  @override
  Future<PageResponse<AdminUserModel>> fetchUsers({
    String? search,
    int page = 0,
    int size = 20,
  }) async {
    searchedEmail = search;
    if (shouldFail) throw Exception('Network unavailable');
    return PageResponse.fromList([
      AdminUserModel.fromJson({
        'userId': 'applicant-1',
        'email': 'applicant@example.com',
        'nickname': '지원자',
        'role': 'AUDIENCE',
        'joinedAt': '2026-09-29',
        'scrapCount': 12,
        'suggestionCount': 3,
      }),
    ]);
  }
}
