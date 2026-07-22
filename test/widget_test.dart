import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/api/api_config.dart';
import 'package:muntum/data/report_place_search_repository.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/models/report_model.dart';
import 'package:muntum/screens/map/map_clustering.dart';
import 'package:muntum/screens/mypage/components/report_form_field.dart';
import 'package:muntum/screens/mypage/report_submit_screen.dart';
import 'package:muntum/services/program_service.dart';
import 'package:muntum/stores/program_scrap_store.dart';
import 'package:muntum/stores/user_preference_store.dart';
import 'package:muntum/utils/program_keyword_match.dart';
import 'package:muntum/utils/program_query.dart';

void main() {
  group('api config', () {
    test('uses the production API by default', () {
      expect(ApiConfig.baseUrl, 'https://api.muntum.work');
    });
  });

  group('map API chip mapping', () {
    test('maps every map filter to the documented chip value', () {
      expect(Filter.nowHot.mapApiChip, 'HOT');
      expect(Filter.free.mapApiChip, 'FREE');
      expect(Filter.thisWeek.mapApiChip, 'THIS_WEEK');
      expect(Filter.noReservation.mapApiChip, 'NO_RESERVATION');
      expect(Filter.exhibition.mapApiChip, 'EXHIBITION');
      expect(Filter.show.mapApiChip, 'PERFORMANCE');
      expect(Filter.experience.mapApiChip, 'CLASS_EXPERIENCE');
      expect(Filter.festival.mapApiChip, 'FAIR');
    });
  });

  group('map clustering', () {
    test('spiderfies programs sharing the same coordinates', () {
      final controller = MapClusteringController();
      final programs = [
        _program(id: 'same-place-1', title: '같은 장소 프로그램 1'),
        _program(id: 'same-place-2', title: '같은 장소 프로그램 2'),
      ];
      String keyFor(ProgramModel program) => program.id;

      final clustered = controller.clusterPrograms(
        programs,
        18,
        keyFor: keyFor,
      );
      expect(clustered, hasLength(1));
      expect(clustered.single.programs, hasLength(2));
      expect(controller.shouldSpiderfy(programs), isTrue);

      controller.spiderfyPrograms(programs, keyFor: keyFor);
      final spiderfied = controller.clusterPrograms(
        programs,
        18.05,
        keyFor: keyFor,
      );
      final positions = controller.spiderfiedMarkerPositions(
        spiderfied,
        18.05,
        keyFor: keyFor,
      );

      expect(spiderfied, hasLength(2));
      expect(positions, hasLength(2));
      expect(positions['same-place-1'], isNot(positions['same-place-2']));
    });
  });

  group('program keyword match', () {
    test('calculates capped three-bar match level', () {
      final program = _program(
        id: '1',
        title: '용산 전시 클래스',
        keywords: ['그 순간에 몰입', '생생한 감각', '사진맛집'],
      );

      expect(
        programKeywordMatchCount(program, [
          '그 순간에 몰입',
          '생생한 감각',
          '사진맛집',
          '없는 키워드',
        ]),
        3,
      );
      expect(
        programKeywordMatchLevel(program, [
          '그 순간에 몰입',
          '생생한 감각',
          '사진맛집',
          '없는 키워드',
        ]),
        3,
      );
      expect(programKeywordMatchLevel(program, ['없는 키워드']), 0);
    });

    test('sorts programs with stronger keyword matches first', () {
      final programs = [
        _program(id: '1', title: '일반 공연', keywords: ['여운이 남는']),
        _program(
          id: '2',
          title: '추천 체험',
          keywords: ['내 손으로 만드는', '새로운 것 배우기', '여운이 남는'],
        ),
      ];

      final sorted = sortProgramsByKeywordMatch(programs, [
        '내 손으로 만드는',
        '새로운 것 배우기',
        '여운이 남는',
      ]);

      expect(sorted.first.title, '추천 체험');
    });
  });

  group('program query', () {
    final programs = [
      _program(
        id: '1',
        title: '용산 문화공간 체험',
        detail: '작가의 표현법을 배워요.',
        address: '서울 용산구 한강대로14길 35-29',
        keywords: ['직접 참여하기', '새로운 것 배우기'],
        filters: [Filter.free, Filter.thisWeek],
        phoneNumber: '02-123-1004',
        link: 'https://muntum.work/programs/1',
      ),
      _program(
        id: '2',
        title: '남산 공연',
        detail: '야외에서 즐기는 공연입니다.',
        address: '서울 중구 남산공원길',
        keywords: ['여운이 남는'],
        filters: [Filter.show],
      ),
    ];

    test('searches address and detail fields', () {
      expect(
        queryPrograms(programs, query: '한강대로14길').single.title,
        '용산 문화공간 체험',
      );
      expect(
        queryPrograms(programs, query: '작가의 표현법').single.title,
        '용산 문화공간 체험',
      );
    });

    test('requires every selected keyword', () {
      final result = queryPrograms(
        programs,
        keywords: ['직접 참여하기', '새로운 것 배우기'],
      );

      expect(result.map((program) => program.title), ['용산 문화공간 체험']);
    });

    test('requires every selected filter', () {
      final result = queryPrograms(
        programs,
        filters: {Filter.free, Filter.thisWeek},
      );

      expect(result.map((program) => program.title), ['용산 문화공간 체험']);
    });

    test('searches reservation, phone, and link parameters', () {
      expect(
        queryPrograms(programs, query: '예약없이 02-123-1004').single.title,
        '용산 문화공간 체험',
      );
      expect(
        queryPrograms(programs, query: 'programs/1').single.title,
        '용산 문화공간 체험',
      );
    });
  });

  group('real-data local stores', () {
    tearDown(() {
      ProgramScrapStore.instance.clear(notify: false);
      UserPreferenceStore.instance.clear();
    });

    test('keeps scrapped programs from real API models', () {
      final program = _program(id: 'program-1', title: '스크랩 프로그램');

      ProgramScrapStore.instance.setScrapped(program, true, notify: false);
      expect(ProgramScrapStore.instance.isScrapped(program), isTrue);
      expect(ProgramScrapStore.instance.scrappedPrograms, contains(program));

      ProgramScrapStore.instance.setScrapped(program, false, notify: false);
      expect(ProgramScrapStore.instance.scrappedPrograms, isEmpty);
    });

    test('keeps selected keywords from real API models', () {
      UserPreferenceStore.instance.updateKeywords(['전시', '체험', '공연']);
      expect(UserPreferenceStore.instance.selectedKeywords, contains('전시'));
      expect(UserPreferenceStore.instance.selectedKeywords.length, 3);
    });
  });

  group('report place search', () {
    const repository = _FakeReportPlaceSearchRepository();

    test('searches place names and addresses', () async {
      final stationResults = await repository.search('용산역');
      expect(stationResults.map((place) => place.name), contains('용산역사박물관'));

      final addressResults = await repository.search('한강대로14길');
      expect(addressResults.single.name, '용산역사박물관');

      final spacedAddressResults = await repository.search('원주시 중앙로');
      expect(
        spacedAddressResults.map((place) => place.name),
        contains('문틈박물관'),
      );
    });
  });

  testWidgets('report place field opens place search screen', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(home: child),
        child: const ReportSubmitScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ReportFormField).last);
    await tester.pumpAndSettle();

    expect(find.text('장소 검색'), findsOneWidget);
  });
}

ProgramModel _program({
  required String id,
  required String title,
  String detail = '문화 프로그램 상세 설명',
  String address = '서울 용산구 한강대로14길 35-29',
  List<String> keywords = const ['전시'],
  List<Filter> filters = const [Filter.exhibition],
  String phoneNumber = '',
  String link = '',
}) {
  return ProgramModel(
    id: id,
    title: title,
    oneLineDescription: '$title 소개',
    detail: detail,
    images: const [],
    keywords: keywords,
    startEndDates: '26.07.01-상시',
    locationName: '용산역사박물관',
    location: {
      'address': address,
      'latitude': '37.5235',
      'longitude': '126.9804',
    },
    availableTime: '10:00-18:00',
    cost: filters.contains(Filter.free) ? '무료' : '유료',
    isReservationNeeded: false,
    phoneNumber: phoneNumber,
    link: link,
    filters: filters,
    isSpotlight: false,
    isOverThisMonth: false,
    isBookmark: false,
    startDate: '2026-07-01',
    endDate: '',
  );
}

class _FakeReportPlaceSearchRepository implements ReportPlaceSearchRepository {
  const _FakeReportPlaceSearchRepository();

  static const _places = [
    ReportPlace(name: '용산역사박물관', address: '서울 용산구 한강대로14길 35-29'),
    ReportPlace(name: '문틈박물관', address: '강원 원주시 중앙로 42'),
  ];

  @override
  Future<List<ReportPlace>> search(String query) async {
    final normalized = query.replaceAll(RegExp(r'\s+'), '');
    return _places
        .where(
          (place) =>
              place.name.replaceAll(RegExp(r'\s+'), '').contains(normalized) ||
              place.address.replaceAll(RegExp(r'\s+'), '').contains(normalized),
        )
        .toList();
  }
}
