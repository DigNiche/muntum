import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/api/api_response.dart';
import 'package:muntum/components/filter_chip.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/models/admin_curation_model.dart';
import 'package:muntum/models/curation_model.dart';
import 'package:muntum/screens/mypage/manager/program_manage_screen.dart';
import 'package:muntum/screens/mypage/manager/program_edit_screen.dart';
import 'package:muntum/services/program_service.dart';
import 'package:muntum/services/admin_curation_service.dart';

void main() {
  test('program reservation fields follow the four API values', () {
    for (final type in ProgramReservationType.values) {
      final program = ProgramModel.fromJson({
        'id': 'reservation-program',
        'reservationType': type.apiValue,
        'reservationUrl': 'https://example.com/book',
      });
      expect(program.reservationType, type);
      expect(program.reservationUrl, 'https://example.com/book');
    }
    expect(
      ProgramModel.fromJson({'reserved': true}).reservationType,
      ProgramReservationType.preRegistration,
    );
    expect(
      ProgramModel.fromJson({'reserved': false}).reservationType,
      ProgramReservationType.freeEntry,
    );
  });

  test('program curator field does not imply a public curation post', () {
    expect(ProgramModel.fromJson({'title': '일반'}).hasCurator, isFalse);
    expect(
      ProgramModel.fromJson({'title': '일반', 'curator': null}).hasCurator,
      isFalse,
    );
    expect(
      ProgramModel.fromJson({
        'title': '큐레이션',
        'curator': {'curatorId': 'curator-id'},
      }).hasCurator,
      isFalse,
    );
  });

  testWidgets('program origin filter uses the resolved public curation flag', (
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
          home: ProgramManageScreen(
            service: _FakeProgramService(includeCurated: true),
            adminCurationService: _EmptyAdminCurationService(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('마틴 파: We Are Martin Parr'), findsOneWidget);
    expect(find.text('큐레이터 프로그램'), findsOneWidget);
    expect(find.text('큐레이션 2'), findsOneWidget);

    await tester.tap(find.text('일반·큐레이션'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('큐레이션').last);
    await tester.pumpAndSettle();
    expect(find.text('큐레이터 프로그램'), findsOneWidget);
    expect(find.text('마틴 파: We Are Martin Parr'), findsNothing);
    expect(find.text('큐레이션'), findsOneWidget);
  });

  testWidgets('curation filter includes programs on later API pages', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = _PagedProgramService();

    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (_, _) => MaterialApp(
          home: ProgramManageScreen(
            service: service,
            adminCurationService: _EmptyAdminCurationService(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('일반·큐레이션'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('큐레이션').last);
    await tester.pumpAndSettle();

    expect(service.requestedPages, [0, 1]);
    expect(find.text('다음 페이지 큐레이션'), findsOneWidget);
    expect(find.text('1개'), findsOneWidget);
  });

  testWidgets('unpublished change request keeps manager curation link', (
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
          home: ProgramManageScreen(
            service: _FakeProgramService(),
            adminCurationService: _PrivateAdminCurationService(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('큐레이션 1'), findsOneWidget);
  });

  testWidgets('program card curation link opens its own management page', (
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
          home: ProgramManageScreen(
            service: _FakeProgramService(includeCurated: true),
            adminCurationService: _EmptyAdminCurationService(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('program-curations-curated-program-id')),
    );
    await tester.pumpAndSettle();
    expect(find.text('[큐레이션] 큐레이터 프로그램'), findsOneWidget);
    expect(find.text('프로그램 관리'), findsNothing);
  });

  testWidgets('program manager shows new card layout and opens search', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final service = _FakeProgramService();
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (_, _) => MaterialApp(
          home: ProgramManageScreen(
            service: service,
            adminCurationService: _EmptyAdminCurationService(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1개'), findsOneWidget);
    expect(find.text('마틴 파: We Are Martin Parr'), findsOneWidget);
    expect(find.byKey(const Key('program-manage-create')), findsOneWidget);
    expect(find.byType(FilterChipWidget), findsNWidgets(3));

    await tester.tap(find.text('전체'));
    await tester.pumpAndSettle();
    expect(find.text('운영기간'), findsOneWidget);
    expect(find.byType(FilterChipWidget), findsNWidgets(7));
    await tester.tap(find.text('전체').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('최신순'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('종료 임박순'));
    await tester.pumpAndSettle();
    expect(service.lastSort, ProgramSort.endDate);

    await tester.tap(find.byKey(const Key('program-manage-search')));
    await tester.pumpAndSettle();
    expect(find.text('프로그램 검색'), findsOneWidget);
    expect(find.text('마틴 파: We Are Martin Parr'), findsNothing);
  });

  testWidgets('program editor separates summary and basic information', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final program = ProgramModel.fromJson({
      'id': 'program-id',
      'title': '기존 프로그램',
      'tagline': '한줄소개',
      'curation': '기존 소개글',
      'venueName': '국립현대미술관',
      'address': '서울시 종로구 1',
      'startDate': '2026-09-01',
      'endDate': '2026-12-31',
      'operatingHours': '10:00~18:00',
      'price': '10,000원',
      'keywords': [
        {'id': 'keyword', 'name': '전시', 'active': true},
      ],
    });
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (_, _) =>
            MaterialApp(home: ProgramEditScreen(program: program)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('기본정보'), findsOneWidget);
    expect(find.text('운영정보'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '수정').first);
    await tester.pumpAndSettle();
    expect(find.text('프로그램 유형'), findsOneWidget);
    await tester.tap(find.text('작성완료'));
    await tester.pumpAndSettle();
    expect(find.text('기본정보'), findsOneWidget);
  });

  testWidgets('operating editor keeps separate start and optional end dates', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final program = ProgramModel.fromJson({
      'id': 'program-id',
      'title': '기존 프로그램',
      'curation': '소개글',
      'venueName': '전시장',
      'address': '서울시 종로구 1',
      'startDate': '2026-09-01',
      'endDate': '2026-12-31',
      'operatingHours': '10:00~18:00',
      'price': '10,000원',
      'keywords': [
        {'id': 'keyword', 'name': '전시', 'active': true},
      ],
    });
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (_, _) =>
            MaterialApp(home: ProgramEditScreen(program: program)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '수정').last);
    await tester.pumpAndSettle();
    expect(find.text('시작일'), findsOneWidget);
    expect(find.text('마감일 (선택)'), findsOneWidget);
    expect(find.text('운영날짜/기간'), findsNothing);
    final endField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.controller?.text == '2026.12.31',
    );
    await tester.enterText(endField, '');
    await tester.ensureVisible(find.text('작성완료'));
    await tester.tap(find.text('작성완료'));
    await tester.pumpAndSettle();
    expect(find.text('상시'), findsOneWidget);
  });

  testWidgets('operating editor sends reservation method and optional link', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = _CaptureProgramService();
    final program = ProgramModel.fromJson({
      'id': 'reservation-program',
      'title': '예약 테스트',
      'curation': '소개글',
      'venueName': '전시장',
      'address': '서울시 종로구 1',
      'startDate': '2026-09-01',
      'operatingHours': '10:00~18:00',
      'price': '10,000원',
      'reservationType': 'FREE_ENTRY',
      'keywords': [
        {'id': 'keyword', 'name': '전시', 'active': true},
      ],
    });
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (_, _) => MaterialApp(
          home: ProgramEditScreen(program: program, programService: service),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '수정').last);
    await tester.pumpAndSettle();

    for (final type in ProgramReservationType.values) {
      expect(find.text(type.label), findsOneWidget);
    }
    final placeField = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.controller?.text == '전시장',
    );
    await tester.tap(placeField);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.hintText == '장소를 검색해보세요.',
      ),
      '검색결과없는장소',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('직접 입력하기'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.hintText == '문틈박물관',
      ),
      '직접 입력한 전시장',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();
    expect(find.text('직접 입력한 전시장'), findsOneWidget);
    expect(find.text('직접 입력한 장소'), findsNothing);
    final addressField = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.controller?.text == '서울시 종로구 1',
    );
    await tester.enterText(addressField, '서울시 종로구 1 4층');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    final reservationField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.hintText == '링크를 첨부해주세요.',
    );
    expect(tester.widget<TextField>(reservationField).enabled, isFalse);
    await tester.ensureVisible(find.text('현장예매'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('현장예매'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(reservationField).enabled, isFalse);
    await tester.ensureVisible(find.text('사전예약·현장예매'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('사전예약·현장예매'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(reservationField).enabled, isTrue);
    await tester.ensureVisible(reservationField);
    await tester.enterText(reservationField, 'https://example.com/book');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.text('작성완료'));
    await tester.pumpAndSettle();
    expect(find.text('예약 링크'), findsOneWidget);
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();

    expect(service.request?['reserved'], isTrue);
    expect(service.request?['reservationType'], 'PRE_REGISTRATION_AND_ON_SITE');
    expect(service.request?['reservationUrl'], 'https://example.com/book');
    expect(service.request?['address'], '서울시 종로구 1 4층');
    expect(service.request?['venueName'], '직접 입력한 전시장');
    expect(tester.takeException(), isNull);
  });

  testWidgets('on-site reservation does not submit a stale reservation link', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = _CaptureProgramService();
    final program = ProgramModel.fromJson({
      'id': 'on-site-program',
      'title': '현장예매 프로그램',
      'curation': '소개글',
      'venueName': '전시장',
      'address': '서울시 종로구 1',
      'startDate': '2026-09-01',
      'operatingHours': '10:00~18:00',
      'price': '10,000원',
      'reservationType': 'ON_SITE',
      'reservationUrl': 'https://example.com/old-booking',
      'keywords': [
        {'id': 'keyword', 'name': '전시', 'active': true},
      ],
    });
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (_, _) => MaterialApp(
          home: ProgramEditScreen(program: program, programService: service),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();

    expect(service.request?['reserved'], isTrue);
    expect(service.request?['reservationType'], 'ON_SITE');
    expect(service.request?['reservationUrl'], isNull);
  });

  testWidgets('editing another field preserves the program tagline', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = _CaptureProgramService();
    final program = ProgramModel.fromJson({
      'id': 'program-id',
      'title': '기존 프로그램',
      'tagline': '원래 한줄소개',
      'curation': '수정하지 않은 소개글 첫 문장. 두 번째 문장',
      'venueName': '전시장',
      'address': '서울시 종로구 1',
      'startDate': '2026-09-01',
      'endDate': '2026-12-31',
      'operatingHours': '10:00~18:00',
      'price': '10,000원',
      'keywords': [
        {'id': 'keyword', 'name': '전시', 'active': true},
      ],
    });
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (_, _) => MaterialApp(
          home: ProgramEditScreen(program: program, programService: service),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();

    expect(service.request?['tagline'], '원래 한줄소개');
    expect(service.request?['description'], '수정하지 않은 소개글 첫 문장. 두 번째 문장');
    expect(service.request?.containsKey('curation'), isFalse);
  });
}

class _CaptureProgramService extends ProgramService {
  Map<String, dynamic>? request;

  @override
  Future<ProgramModel> updateProgram({
    required String id,
    required Map<String, dynamic> program,
    List<String> imagePaths = const [],
  }) async {
    request = program;
    return ProgramModel.fromJson({'id': id, ...program});
  }
}

class _EmptyAdminCurationService extends AdminCurationService {
  @override
  Future<PageResponse<AdminCurationModel>> fetchList({
    required CurationStatus status,
    int page = 0,
    int size = 20,
  }) async => PageResponse.fromList([]);
}

class _PrivateAdminCurationService extends AdminCurationService {
  final item = AdminCurationModel.fromJson({
    'id': 'private-curation',
    'programId': 'program-id',
    'submittedProgramTitle': '마틴 파: We Are Martin Parr',
    'status': 'CHANGES_REQUESTED',
    'publicationStatus': 'UNPUBLISHED',
    'curator': {'curatorId': 'curator-id', 'nickname': '큐레이터'},
  });

  @override
  Future<PageResponse<AdminCurationModel>> fetchList({
    required CurationStatus status,
    int page = 0,
    int size = 20,
  }) async => PageResponse.fromList([item]);

  @override
  Future<AdminCurationModel> fetchDetail(String id) async => item;
}

class _FakeProgramService extends ProgramService {
  _FakeProgramService({this.includeCurated = false});

  final bool includeCurated;
  ProgramSort? lastSort;

  @override
  Future<PageResponse<ProgramModel>> fetchPrograms({
    String? search,
    List<String> keywordNames = const [],
    Filter? chip,
    ProgramSort sort = ProgramSort.latest,
    SortOrder order = SortOrder.desc,
    int page = 0,
    int size = 20,
    bool authorized = false,
  }) async {
    lastSort = sort;
    return PageResponse.fromList([
      ProgramModel.fromJson({
        'id': 'program-id',
        'title': '마틴 파: We Are Martin Parr',
        'venueName': '국립현대미술관',
        'startDate': '2026-09-01',
        'endDate': '2026-12-31',
      }),
      if (includeCurated)
        ProgramModel.fromJson({
            'id': 'curated-program-id',
            'title': '큐레이터 프로그램',
            'venueName': '전시장',
            'startDate': '2026-09-01',
            'endDate': '2026-12-31',
            'curator': {'curatorId': 'curator-id'},
          })
          ..hasCurator = true
          ..publicCurationCount = 2,
    ]);
  }
}

class _PagedProgramService extends ProgramService {
  final requestedPages = <int>[];

  @override
  Future<PageResponse<ProgramModel>> fetchPrograms({
    String? search,
    List<String> keywordNames = const [],
    Filter? chip,
    ProgramSort sort = ProgramSort.latest,
    SortOrder order = SortOrder.desc,
    int page = 0,
    int size = 20,
    bool authorized = false,
  }) async {
    requestedPages.add(page);
    return PageResponse<ProgramModel>(
      content: [
        ProgramModel.fromJson(
          page == 0
              ? {'id': 'general', 'title': '일반 프로그램'}
              : {
                  'id': 'curated',
                  'title': '다음 페이지 큐레이션',
                  'curator': {'curatorId': 'curator-id'},
                },
        )..hasCurator = page == 1,
      ],
      page: page,
      size: 1,
      totalElements: 2,
      totalPages: 2,
      first: page == 0,
      last: page == 1,
      hasPrevious: page == 1,
      hasNext: page == 0,
    );
  }
}
