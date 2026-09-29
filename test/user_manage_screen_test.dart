import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/api/api_response.dart';
import 'package:muntum/models/admin_user_model.dart';
import 'package:muntum/screens/mypage/manager/user_manage_screen.dart';
import 'package:muntum/services/admin_user_service.dart';

void main() {
  testWidgets('user management reuses filters and opens a role profile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = _FakeAdminUserService();

    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (context, child) =>
            MaterialApp(home: UserManageScreen(service: service)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('사용자 관리'), findsOneWidget);
    expect(find.text('4명'), findsOneWidget);
    expect(find.byKey(const ValueKey('user-card-audience')), findsOneWidget);
    expect(find.byKey(const ValueKey('user-card-curator')), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.byKey(const ValueKey('user-card-audience')));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('스크랩 12'), findsOneWidget);
    expect(find.text('작성글 -'), findsNothing);
    Navigator.of(
      tester.element(find.byKey(const ValueKey('user-profile-sheet'))),
    ).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('전체').first);
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('사용자 유형'), findsOneWidget);
    await tester.tap(find.text('큐레이터').last);
    await tester.pumpAndSettle();

    expect(find.text('2명'), findsOneWidget);
    expect(find.byKey(const ValueKey('user-card-audience')), findsNothing);
    expect(find.byKey(const ValueKey('user-card-curator')), findsOneWidget);
    expect(find.byKey(const ValueKey('user-card-curator-2')), findsOneWidget);
    expect(service.requestedPages, contains(1));

    await tester.tap(find.byKey(const ValueKey('user-card-curator')));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byKey(const ValueKey('user-profile-sheet')), findsOneWidget);
    expect(find.text('가입일: 2026.12.12'), findsOneWidget);
    expect(find.text('스크랩 12'), findsOneWidget);
    expect(find.text('제보 0'), findsOneWidget);
    expect(find.text('작성글 -'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('user-role-badge-curator')),
      findsNWidgets(2),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('oldest sort loads all pages and orders by joined date', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = _FakeAdminUserService();
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (context, child) =>
            MaterialApp(home: UserManageScreen(service: service)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('최신 가입순'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    await tester.tap(find.text('오래된순'));
    await tester.pumpAndSettle();

    expect(service.requestedPages, contains(1));
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('user-card-curator-2'))).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const ValueKey('user-card-manager'))).dy,
      ),
    );
    expect(tester.takeException(), isNull);
  });
}

class _FakeAdminUserService extends AdminUserService {
  final requestedPages = <int>[];

  @override
  Future<PageResponse<AdminUserModel>> fetchUsers({
    String? search,
    int page = 0,
    int size = 20,
  }) async {
    requestedPages.add(page);
    final users = page == 0
        ? [
            _user('audience', 'AUDIENCE', '2026-12-13'),
            _user('curator', 'CURATOR', '2026-12-12'),
          ]
        : [
            _user('manager', 'MANAGER', '2026-12-11'),
            _user('curator-2', 'CURATOR', '2026-12-10'),
          ];
    return PageResponse(
      content: users,
      page: page,
      size: size,
      totalElements: 4,
      totalPages: 2,
      first: page == 0,
      last: page == 1,
      hasPrevious: page > 0,
      hasNext: page == 0,
    );
  }
}

AdminUserModel _user(String id, String role, String joinedAt) =>
    AdminUserModel.fromJson({
      'userId': id,
      'email': '$id@example.com',
      'nickname': id,
      'role': role,
      'scrapCount': 12,
      'suggestionCount': 0,
      'joinedAt': joinedAt,
    });
