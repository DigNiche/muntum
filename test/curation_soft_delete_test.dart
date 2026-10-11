import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/api/api_exception.dart';
import 'package:muntum/api/api_response.dart';
import 'package:muntum/models/curation_model.dart';
import 'package:muntum/screens/mypage/curator/curation_detail_screen.dart';
import 'package:muntum/screens/mypage/curator/written_program_list_page.dart';
import 'package:muntum/screens/program_detail/components/program_curations_section.dart';
import 'package:muntum/services/curation_service.dart';
import 'package:muntum/stores/auth_state.dart';

void main() {
  Widget app(Widget home) => ScreenUtilPlusInit(
    designSize: const Size(390, 844),
    builder: (_, _) => MaterialApp(home: home),
  );

  void size(WidgetTester tester) {
    AuthState.instance.replace(userId: 'author', role: 'CURATOR');
    addTearDown(AuthState.instance.clear);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> confirm(WidgetTester tester, Finder menu) async {
    await tester.tap(menu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제하기'));
    await tester.pumpAndSettle();
    expect(find.text('작성한 글을 삭제할까요?'), findsOneWidget);
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
  }

  for (final status in ['PENDING', 'CHANGES_REQUESTED', 'APPROVED']) {
    testWidgets(
      'owner can delete $status detail after confirmation',
      (tester) async {
        size(tester);
        final service = _DeletionService(status);
        String? result;
        await tester.pumpWidget(
          app(
            Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    result = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CurationDetailScreen(
                          curation: service.note,
                          service: service,
                        ),
                      ),
                    );
                  },
                  child: const Text('열기'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('열기'));
        await tester.pumpAndSettle();
        await confirm(tester, find.byIcon(Icons.more_vert));
        expect(service.deleted, isTrue);
        expect(result, 'deleted');
        expect(find.byType(CurationDetailScreen), findsNothing);
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant({
        TargetPlatform.android,
        TargetPlatform.iOS,
      }),
    );
  }

  testWidgets('approved post disappears and count refreshes after deletion', (
    tester,
  ) async {
    size(tester);
    final service = _DeletionService('APPROVED');
    await tester.pumpWidget(app(WrittenProgramList(service: service)));
    await tester.pumpAndSettle();
    expect(find.text('삭제 테스트 글'), findsOneWidget);
    await confirm(
      tester,
      find.byKey(const ValueKey('curation-post-actions-note')),
    );
    expect(service.deleted, isTrue);
    expect(find.text('삭제 테스트 글'), findsNothing);
    expect(find.text('작성글 0'), findsOneWidget);
  });

  testWidgets('failed delete preserves the post and reports the error', (
    tester,
  ) async {
    size(tester);
    final service = _DeletionService('APPROVED', failDelete: true);
    await tester.pumpWidget(app(WrittenProgramList(service: service)));
    await tester.pumpAndSettle();
    await confirm(
      tester,
      find.byKey(const ValueKey('curation-post-actions-note')),
    );
    expect(service.deleted, isFalse);
    expect(find.text('삭제 테스트 글'), findsOneWidget);
    expect(find.text('삭제 실패 테스트'), findsOneWidget);
  });

  testWidgets('approved public author delete refreshes the note carousel', (
    tester,
  ) async {
    size(tester);
    AuthState.instance.replace(userId: 'author', role: 'CURATOR');
    addTearDown(AuthState.instance.clear);
    final service = _DeletionService('APPROVED');
    await tester.pumpWidget(
      app(
        Scaffold(
          body: ProgramCurationsSection(
            programId: 'program',
            programTitle: '프로그램',
            service: service,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('curation-note-note')));
    await tester.pumpAndSettle();
    await confirm(
      tester,
      find.byKey(const ValueKey('public-curation-actions')),
    );
    expect(service.deleted, isTrue);
    expect(find.byType(PublicCurationDetailScreen), findsNothing);
    expect(find.byKey(const ValueKey('curation-note-note')), findsNothing);
  });

  testWidgets('cancelled delete does not send a deletion request', (
    tester,
  ) async {
    size(tester);
    final service = _DeletionService('APPROVED');
    await tester.pumpWidget(app(WrittenProgramList(service: service)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('curation-post-actions-note')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(service.deleted, isFalse);
    expect(find.text('삭제 테스트 글'), findsOneWidget);
  });

  testWidgets('deleted public detail never falls back to its cached summary', (
    tester,
  ) async {
    size(tester);
    final service = _MissingPublicService('APPROVED');
    await tester.pumpWidget(
      app(
        PublicCurationDetailScreen(
          programId: 'program',
          programTitle: '프로그램',
          summary: service.publicNote,
          service: service,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('삭제 테스트 글'), findsNothing);
    expect(find.text('삭제되었거나 조회할 수 없는 큐레이션입니다.'), findsOneWidget);
    expect(find.byKey(const ValueKey('public-curation-actions')), findsNothing);
  });

  testWidgets('public note carousel loads later API pages', (tester) async {
    size(tester);
    final service = _PagedPublicService('APPROVED');
    await tester.pumpWidget(
      app(
        Scaffold(
          body: ProgramCurationsSection(
            programId: 'program',
            programTitle: '프로그램',
            service: service,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(service.pages, [0, 1]);
    expect(find.byKey(const ValueKey('curation-note-note')), findsOneWidget);
    expect(find.byKey(const ValueKey('curation-note-second')), findsOneWidget);
  });

  test(
    'detail CU001 is excluded but a transient failure retains summary',
    () async {
      final missing = _DetailRaceService(404, 'CU001');
      expect(await missing.fetchAllMineWithDetails(), isEmpty);
      final unavailable = _DetailRaceService(500, 'E001');
      expect((await unavailable.fetchAllMineWithDetails()).single.id, 'note');
    },
  );

  test(
    'resubmission clears review time but keeps connection and prior reason',
    () {
      final previous = CurationModel.fromJson({
        'id': 'note',
        'programId': 'program',
        'reviewedAt': '2026-10-01T12:00:00',
      });
      final current = CurationModel.fromJson({
        'id': 'note',
        'programId': 'program',
        'status': 'PENDING',
        'publicationStatus': 'PUBLISHED',
        'reviewedAt': null,
        'changeRequestReason': '이전 사유',
      });
      final merged = previous.mergeDetails(current);
      expect(merged.reviewedAt, isNull);
      expect(merged.programId, 'program');
      expect(merged.publicationStatus, 'PUBLISHED');
      expect(merged.isRevisedPending, isTrue);
    },
  );
}

class _DeletionService extends CurationService {
  _DeletionService(this.status, {this.failDelete = false});
  final String status;
  final bool failDelete;
  bool deleted = false;
  CurationModel get note => CurationModel.fromJson({
    'id': 'note',
    'submittedProgramTitle': '프로그램',
    'submittedPlace': '장소',
    'tagline': '삭제 테스트 글',
    'content': '본문',
    'status': status,
    'publicationStatus': 'PUBLISHED',
    'createdAt': '2026-10-01T12:00:00',
  });
  PublicCurationModel get publicNote => PublicCurationModel.fromJson({
    'id': 'note',
    'programId': 'program',
    'tagline': '삭제 테스트 글',
    'content': '본문',
    'curator': {'curatorId': 'author', 'nickname': '작성자'},
  });
  @override
  Future<void> delete(String id) async {
    if (failDelete) {
      throw const ApiException(
        statusCode: 500,
        code: 'E001',
        message: '삭제 실패 테스트',
      );
    }
    deleted = true;
  }

  @override
  Future<CurationModel> fetchMyDetail(String id) async => note;
  @override
  Future<List<CurationModel>> fetchAllMineWithDetails() async =>
      deleted ? [] : [note];
  @override
  Future<CuratorProfileModel> fetchMyProfile() async => CuratorProfileModel(
    curatorId: 'author',
    nickname: '작성자',
    profileImageUrl: null,
    approvedCount: deleted ? 0 : 1,
    pendingCount: 0,
    changesRequestedCount: 0,
  );
  @override
  Future<PageResponse<PublicCurationModel>> fetchProgramCurations(
    String id, {
    int page = 0,
    int size = 20,
  }) async => PageResponse.fromList(deleted ? [] : [publicNote]);
  @override
  Future<PublicCurationModel> fetchProgramCurationDetail(
    String id,
    String noteId,
  ) async => publicNote;
}

class _MissingPublicService extends _DeletionService {
  _MissingPublicService(super.status);
  @override
  Future<PublicCurationModel> fetchProgramCurationDetail(
    String id,
    String noteId,
  ) async =>
      throw const ApiException(statusCode: 404, code: 'CU001', message: '삭제됨');
}

class _PagedPublicService extends _DeletionService {
  _PagedPublicService(super.status);
  final pages = <int>[];
  @override
  Future<PageResponse<PublicCurationModel>> fetchProgramCurations(
    String id, {
    int page = 0,
    int size = 20,
  }) async {
    pages.add(page);
    return PageResponse.fromJson({
      'content': [
        {
          'id': page == 0 ? 'note' : 'second',
          'tagline': '글',
          'curator': {'nickname': '작성자'},
        },
      ],
      'page': page,
      'size': 1,
      'totalElements': 2,
      'totalPages': 2,
      'last': page == 1,
      'hasNext': page == 0,
    }, PublicCurationModel.fromJson);
  }
}

class _DetailRaceService extends CurationService {
  _DetailRaceService(this.statusCode, this.code);
  final int statusCode;
  final String code;
  @override
  Future<PageResponse<CurationModel>> fetchMine({
    CurationStatus? status,
    int page = 0,
    int size = 20,
  }) async => PageResponse.fromList([
    CurationModel.fromJson({'id': 'note'}),
  ]);
  @override
  Future<CurationModel> fetchMyDetail(String id) async =>
      throw ApiException(statusCode: statusCode, code: code, message: 'test');
}
