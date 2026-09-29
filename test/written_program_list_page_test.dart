import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/api/api_response.dart';
import 'package:muntum/models/curation_model.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/mypage/curator/curation_detail_screen.dart';
import 'package:muntum/screens/mypage/curator/curation_write_screen.dart';
import 'package:muntum/screens/mypage/curator/written_program_list_page.dart';
import 'package:muntum/screens/program_detail/components/program_curations_section.dart';
import 'package:muntum/services/curation_service.dart';
import 'package:muntum/services/program_service.dart';
import 'package:muntum/stores/auth_state.dart';

void main() {
  final service = _FakeCurationService();

  Widget buildSubject() {
    return ScreenUtilPlusInit(
      designSize: const Size(390, 844),
      builder: (context, child) =>
          MaterialApp(home: WrittenProgramList(service: service)),
    );
  }

  testWidgets('approved posts and review statuses are split into tabs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('프로그램 작성내역'), findsNothing);
    expect(find.text('승인된 글'), findsOneWidget);
    expect(find.text('검토 중인 글'), findsNothing);

    await tester.tap(find.text('작성현황'));
    await tester.pumpAndSettle();

    expect(find.text('승인된 글'), findsNothing);
    expect(find.text('검토 중인 글'), findsOneWidget);
    expect(find.text('등록대기'), findsOneWidget);
    expect(find.text('수정'), findsOneWidget);
  });

  testWidgets('new post button opens the curation form', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('+  새 글 작성하기'));
    await tester.pumpAndSettle();

    expect(find.byType(CurationWriteScreen), findsOneWidget);
    expect(find.text('새 글 작성'), findsOneWidget);
  });

  testWidgets('pending card opens its details without a layout exception', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();
    await tester.tap(find.text('작성현황'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('curation-status-pending')));
    await tester.pumpAndSettle();

    expect(find.byType(CurationDetailScreen), findsOneWidget);
    expect(find.text('작성 내용 확인'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a published revision is shown in posts, not pending', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('공개 유지 글'), findsOneWidget);
    await tester.tap(find.text('작성현황'));
    await tester.pumpAndSettle();

    expect(find.text('등록대기 1'), findsOneWidget);
    expect(find.text('공개 유지 글'), findsNothing);
  });

  testWidgets('linked card uses actual program title and post menu stays put', (
    tester,
  ) async {
    AuthState.instance.replace(userId: 'curator-id', role: 'CURATOR');
    addTearDown(AuthState.instance.clear);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(
          home: WrittenProgramList(
            service: _LinkedCurationService(),
            programService: _FakeProgramService(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('실제 프로그램 제목'), findsOneWidget);
    expect(find.text('테스트 수정'), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey('curation-post-actions-linked')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CurationDetailScreen), findsNothing);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('수정하기'), findsOneWidget);
    expect(find.text('삭제하기'), findsOneWidget);
  });

  testWidgets('tapping a published post opens its public curator detail', (
    tester,
  ) async {
    AuthState.instance.replace(userId: 'curator-id', role: 'CURATOR');
    addTearDown(AuthState.instance.clear);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(
          home: WrittenProgramList(
            service: _LinkedCurationService(),
            programService: _FakeProgramService(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('테스트 글'));
    await tester.pumpAndSettle();

    expect(find.byType(PublicCurationDetailScreen), findsOneWidget);
    expect(find.byType(CurationDetailScreen), findsNothing);
    expect(find.text('실제 프로그램 제목'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('public-curation-actions')),
      findsOneWidget,
    );
  });

  testWidgets('iOS detail uses linked title and shows delete action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final linked =
        (await _LinkedCurationService().fetchAllMineWithDetails()).first;
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: CurationDetailScreen(
            curation: linked,
            service: _LinkedCurationService(),
            programService: _FakeProgramService(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('실제 프로그램 제목'), findsOneWidget);
    expect(find.text('테스트 수정'), findsNothing);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoActionSheet), findsOneWidget);
    expect(find.text('삭제하기'), findsOneWidget);
  });
}

class _LinkedCurationService extends _FakeCurationService {
  @override
  Future<PublicCurationModel> fetchProgramCurationDetail(
    String programId,
    String curationId,
  ) async => PublicCurationModel.fromJson({
    'id': curationId,
    'programId': programId,
    'curator': {'curatorId': 'curator-id', 'nickname': '이초홍'},
    'tagline': '테스트 글',
    'content': '본문',
  });

  @override
  Future<List<CurationModel>> fetchAllMineWithDetails() async => [
    CurationModel(
      id: 'linked',
      programId: 'program-1',
      programTitle: '테스트 수정',
      place: '제출 장소',
      tagline: '테스트 글',
      content: '본문',
      images: const [],
      status: CurationStatus.approved,
      publicationStatus: 'PUBLISHED',
      changeRequestReason: null,
      reviewedAt: null,
      createdAt: DateTime(2026, 9, 29),
      updatedAt: null,
    ),
  ];
}

class _FakeProgramService extends ProgramService {
  @override
  Future<ProgramModel> fetchProgram(
    String id, {
    bool authorized = false,
  }) async => ProgramModel.fromJson({
    'id': id,
    'title': '실제 프로그램 제목',
    'venueName': '실제 장소',
  });
}

class _FakeCurationService extends CurationService {
  @override
  Future<CuratorProfileModel> fetchMyProfile() async {
    return const CuratorProfileModel(
      curatorId: 'curator-id',
      nickname: '이초홍',
      profileImageUrl: null,
      approvedCount: 2,
      pendingCount: 1,
      changesRequestedCount: 0,
    );
  }

  @override
  Future<List<CurationModel>> fetchAllMineWithDetails() async {
    return [
      _curation(
        id: 'approved',
        tagline: '승인된 글',
        status: CurationStatus.approved,
        publicationStatus: 'PUBLISHED',
      ),
      _curation(
        id: 'pending',
        tagline: '검토 중인 글',
        status: CurationStatus.pending,
        changeRequestReason: '내용을 수정해 주세요.',
      ),
      _curation(
        id: 'published-pending',
        tagline: '공개 유지 글',
        status: CurationStatus.pending,
        publicationStatus: 'PUBLISHED',
      ),
    ];
  }

  @override
  Future<PageResponse<CurationModel>> fetchMine({
    CurationStatus? status,
    int page = 0,
    int size = 20,
  }) async => PageResponse.fromList(await fetchAllMineWithDetails());
}

CurationModel _curation({
  required String id,
  required String tagline,
  required CurationStatus status,
  String publicationStatus = 'UNPUBLISHED',
  String? changeRequestReason,
}) {
  return CurationModel(
    id: id,
    programId: null,
    programTitle: tagline,
    place: '장소',
    tagline: tagline,
    content: '소개글',
    images: const [],
    status: status,
    publicationStatus: publicationStatus,
    changeRequestReason: changeRequestReason,
    reviewedAt: null,
    createdAt: DateTime(2026, 9, 28),
    updatedAt: DateTime(2026, 9, 28),
  );
}
