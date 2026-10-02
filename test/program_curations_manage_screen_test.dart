import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/api/api_response.dart';
import 'package:muntum/models/admin_curation_model.dart';
import 'package:muntum/models/curation_model.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/mypage/manager/program_curations_manage_screen.dart';
import 'package:muntum/services/admin_curation_service.dart';
import 'package:muntum/services/curation_service.dart';

void main() {
  testWidgets('manager sees posts and requests a public typo correction', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final adminService = _FakeAdminCurationService();

    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (_, _) => MaterialApp(
          home: ProgramCurationsManageScreen(
            program: ProgramModel.fromJson({
              'id': 'cloud-9',
              'title': '성률 개인전 [Cloud 9]',
            }),
            curationService: _FakeCurationService(),
            adminService: adminService,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('첫 번째 글'), findsOneWidget);
    expect(find.text('두 번째 글'), findsOneWidget);

    await tester.tap(find.byKey(const Key('program-curation-request-second')));
    await tester.pumpAndSettle();
    expect(find.text('수정 요청 사유 선택'), findsOneWidget);
    await tester.tap(find.text('글 내 오탈자 및 맞춤법, 띄어쓰기를 확인해주세요.'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('수정 요청'));
    await tester.pumpAndSettle();
    expect(adminService.requestedId, 'second');
    expect(adminService.publicationStatus, 'PUBLISHED');
    expect(find.text('수정요청 1 ›'), findsOneWidget);
    expect(find.text('해당 글은 수정 요청으로 비공개 처리되었습니다.'), findsNothing);

    await tester.tap(find.byKey(const Key('program-curation-request-second')));
    await tester.pumpAndSettle();
    expect(find.text('큐레이터 글 확인'), findsOneWidget);
  });

  testWidgets(
    'mismatched curation remains in manager list with private banner',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final adminService = _FakeAdminCurationService();
      await tester.pumpWidget(
        ScreenUtilPlusInit(
          designSize: const Size(390, 844),
          builder: (_, _) => MaterialApp(
            home: ProgramCurationsManageScreen(
              program: ProgramModel.fromJson({
                'id': 'cloud-9',
                'title': '성률 개인전 [Cloud 9]',
              }),
              curationService: _FakeCurationService(),
              adminService: adminService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('program-curation-request-first')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('프로그램 정보와 작성하신 내용이 일치하지 않습니다. 확인 후 수정해 주세요.'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('수정 요청'));
      await tester.pumpAndSettle();
      expect(adminService.publicationStatus, 'UNPUBLISHED');
      expect(find.text('해당 글은 수정 요청으로 비공개 처리되었습니다.'), findsOneWidget);
      expect(find.text('첫 번째 글'), findsOneWidget);
    },
  );

  testWidgets(
    'linked private note is listed even when submitted title differs',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ScreenUtilPlusInit(
          designSize: const Size(390, 844),
          builder: (_, _) => MaterialApp(
            home: ProgramCurationsManageScreen(
              program: ProgramModel.fromJson({
                'id': 'cloud-9',
                'title': '성률 개인전 [Cloud 9]',
              }),
              curationService: _FakeCurationService(count: 0),
              adminService: _FakeAdminCurationService(
                initialRequestedId: 'first',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('첫 번째 글'), findsOneWidget);
      expect(find.text('수정요청 1 ›'), findsOneWidget);
      expect(find.text('해당 글은 수정 요청으로 비공개 처리되었습니다.'), findsOneWidget);
    },
  );

  testWidgets('one public and one private note both appear for the program', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (_, _) => MaterialApp(
          home: ProgramCurationsManageScreen(
            program: ProgramModel.fromJson({
              'id': 'cloud-9',
              'title': '성률 개인전 [Cloud 9]',
            }),
            curationService: _FakeCurationService(count: 1),
            adminService: _FakeAdminCurationService(
              initialRequestedId: 'second',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('첫 번째 글'), findsOneWidget);
    expect(find.text('두 번째 글'), findsOneWidget);
    expect(find.text('해당 글은 수정 요청으로 비공개 처리되었습니다.'), findsOneWidget);
  });
}

class _FakeCurationService extends CurationService {
  _FakeCurationService({this.count = 2});
  final int count;

  @override
  Future<PageResponse<PublicCurationModel>> fetchProgramCurations(
    String programId, {
    int page = 0,
    int size = 20,
  }) async => PageResponse.fromList(
    count == 0
        ? []
        : [
            PublicCurationModel.fromJson({
              'id': 'first',
              'programId': programId,
              'tagline': '첫 번째 글',
              'curator': {'nickname': '큐레이터 A'},
            }),
            if (count > 1)
              PublicCurationModel.fromJson({
                'id': 'second',
                'programId': programId,
                'tagline': '두 번째 글',
                'curator': {'nickname': '큐레이터 B'},
              }),
          ],
  );
}

class _FakeAdminCurationService extends AdminCurationService {
  _FakeAdminCurationService({String? initialRequestedId})
    : requestedId = initialRequestedId,
      publicationStatus = initialRequestedId == null ? null : 'UNPUBLISHED';

  String? requestedId;
  String? publicationStatus;

  @override
  Future<PageResponse<AdminCurationModel>> fetchList({
    required CurationStatus status,
    int page = 0,
    int size = 20,
  }) async => PageResponse.fromList(
    status == CurationStatus.changesRequested && requestedId != null
        ? [await fetchDetail(requestedId!)]
        : [],
  );

  @override
  Future<AdminCurationModel> fetchDetail(
    String id,
  ) async => AdminCurationModel.fromJson({
    'id': id,
    'programId': 'cloud-9',
    'submittedProgramTitle': id == requestedId ? 'test2' : '성률 개인전 [Cloud 9]',
    'submittedPlace': '갤러리조은',
    'tagline': id == 'first' ? '첫 번째 글' : '두 번째 글',
    'content': '큐레이션 본문',
    'status': id == requestedId ? 'CHANGES_REQUESTED' : 'APPROVED',
    'publicationStatus': id == requestedId ? publicationStatus : 'PUBLISHED',
    'curator': {'curatorId': 'curator-id', 'nickname': '큐레이터 B'},
  });

  @override
  Future<void> requestChanges({
    required String curationId,
    required String reason,
    required String publicationStatus,
  }) async {
    requestedId = curationId;
    this.publicationStatus = publicationStatus;
  }
}
