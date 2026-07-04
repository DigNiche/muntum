import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/data/mock_program_data.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/home/home_screen.dart';
import 'package:muntum/screens/home/see_more_screen.dart';
import 'package:muntum/screens/map/map_radius.dart';
import 'package:muntum/utils/program_query.dart';

void main() {
  group('map search radius', () {
    const centerLatitude = 37.3422;
    const centerLongitude = 127.9202;

    test('includes a program inside 5km', () {
      expect(
        isWithinRadius(
          centerLatitude: centerLatitude,
          centerLongitude: centerLongitude,
          targetLatitude: 37.3494,
          targetLongitude: 127.9490,
          radiusMeters: 5000,
        ),
        isTrue,
      );
    });

    test('excludes a program outside 5km', () {
      expect(
        isWithinRadius(
          centerLatitude: centerLatitude,
          centerLongitude: centerLongitude,
          targetLatitude: 37.3435,
          targetLongitude: 127.9845,
          radiusMeters: 5000,
        ),
        isFalse,
      );
    });
  });

  group('mock program data', () {
    test('provides complete card data', () {
      expect(mockPrograms, isNotEmpty);

      for (final program in mockPrograms) {
        expect(program.title, isNotEmpty);
        expect(program.locationName, isNotEmpty);
        expect(program.startEndDates, isNotEmpty);
        expect(program.images, isNotEmpty);
        expect(program.keywords, isNotEmpty);
      }
    });

    test('provides valid map coordinates', () {
      for (final program in mockPrograms) {
        expect(double.tryParse(program.location['latitude'] ?? ''), isNotNull);
        expect(double.tryParse(program.location['longitude'] ?? ''), isNotNull);
      }
    });

    test('covers every program category', () {
      for (final category in const {
        Filter.exhibition,
        Filter.show,
        Filter.experience,
        Filter.festival,
      }) {
        expect(
          mockPrograms.where((program) => program.filters.contains(category)),
          isNotEmpty,
        );
      }
    });
  });

  group('program query', () {
    test('searches address and detail fields', () {
      expect(
        queryPrograms(mockPrograms, query: '무실로 235').single.title,
        '원주 문화공간 체험',
      );
      expect(
        queryPrograms(mockPrograms, query: '작가의 표현법').single.title,
        '무실동 전시 클래스',
      );
    });

    test('requires every selected keyword', () {
      final result = queryPrograms(
        mockPrograms,
        keywords: ['내 손으로 만드는', '여운이 남는'],
      );

      expect(result.map((program) => program.title), ['무실동 전시 클래스']);
    });

    test('requires every selected filter', () {
      final result = queryPrograms(
        mockPrograms,
        filters: {Filter.free, Filter.thisWeek},
      );

      expect(result.map((program) => program.title), ['원주 문화공간 체험']);
    });

    test('searches reservation, phone, and link parameters', () {
      expect(
        queryPrograms(mockPrograms, query: '예약없이 033-123-1004').single.title,
        '원주 중앙시장 투어',
      );
      expect(
        queryPrograms(mockPrograms, query: 'programs/8').single.title,
        '뮤지엄 나이트',
      );
    });
  });

  testWidgets('my niche scroll-to-top button returns the list to the top', (
    tester,
  ) async {
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(home: child),
        child: const MyNichePage(),
      ),
    );
    await tester.pumpAndSettle();

    const scrollToTopKey = ValueKey('my_niche_scroll_to_top');
    expect(find.byKey(scrollToTopKey), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.byKey(scrollToTopKey), findsOneWidget);
    await tester.tap(find.byKey(scrollToTopKey));
    await tester.pumpAndSettle();

    expect(find.byKey(scrollToTopKey), findsNothing);
  });

  testWidgets('see more uses one filter at a time', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(home: child),
        child: const SeeMoreScreen(type: SeeMoreType.allPrograms),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('프로그램 12개'), findsOneWidget);
    await tester.tap(find.text('무료'));
    await tester.pumpAndSettle();
    expect(find.text('프로그램 5개'), findsOneWidget);

    await tester.tap(find.text('이번주'));
    await tester.pumpAndSettle();
    expect(find.text('프로그램 6개'), findsOneWidget);
  });

  testWidgets('see more supports programs ending this month', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(home: child),
        child: const SeeMoreScreen(type: SeeMoreType.endingThisMonth),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('이번달에 끝나는'), findsOneWidget);
    expect(find.text('프로그램 4개'), findsOneWidget);
  });
}
