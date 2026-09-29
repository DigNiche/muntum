import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/api/api_response.dart';
import 'package:muntum/components/filter_chip.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/mypage/manager/program_manage_screen.dart';
import 'package:muntum/screens/mypage/manager/program_edit_screen.dart';
import 'package:muntum/services/program_service.dart';

void main() {
  test('program curator field distinguishes curation programs', () {
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
      isTrue,
    );
  });

  testWidgets('program origin filter uses the curator field', (tester) async {
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
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('마틴 파: We Are Martin Parr'), findsOneWidget);
    expect(find.text('큐레이터 프로그램'), findsOneWidget);

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
        builder: (_, _) =>
            MaterialApp(home: ProgramManageScreen(service: service)),
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
        builder: (_, _) =>
            MaterialApp(home: ProgramManageScreen(service: service)),
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
        }),
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
        ),
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
