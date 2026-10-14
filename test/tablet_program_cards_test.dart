import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/components/cards/vertical_card.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/home/components/vertical_card_carousel.dart';
import 'package:muntum/screens/home/components/two_row_horizontal_card_carousel.dart';
import 'package:muntum/utils/program_card_layout.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('SUIT');
    for (final font in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      loader.addFont(rootBundle.load('assets/fonts/SUIT-$font.ttf'));
    }
    await loader.load();
  });
  final programs = List.generate(
    4,
    (index) => ProgramModel.fromJson({
      'id': '$index',
      'title': '연극 [사막에도 가끔 비가 내립니다(근데 이제 춤을 곁들인)] 긴 프로그램 제목',
      'venueName': '국립현대미술관 서울',
      'startDate': '2026-10-01',
      'endDate': '2026-12-31',
    }),
  );

  Future<void> pump(
    WidgetTester tester,
    Size size, {
    double textScale = 1,
    bool original = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, _) => MaterialApp(
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: Builder(
                builder: (context) => Scaffold(
                  body: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(
                          key: const Key('collection-height'),
                          height: original
                              ? 370.h
                              : ProgramCardLayout.collectionHeight(
                                  context,
                                  programs,
                                ),
                          child: VerticalCardCarousel(programs: programs),
                        ),
                        TwoRowHorizontalCardCarousel(
                          programs: programs,
                          entrySource: 'test',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final size in [
    const Size(360, 800),
    const Size(390, 844),
    const Size(430, 932),
  ]) {
    testWidgets('phone $size keeps original card dimensions', (tester) async {
      await pump(tester, size, original: true);
      final originalCard = tester.getRect(find.byType(VerticalCard).first);
      final originalRows = tester.getRect(find.byType(GridView));
      await pump(tester, size);
      expect(tester.getRect(find.byType(VerticalCard).first), originalCard);
      expect(tester.getRect(find.byType(GridView)), originalRows);
      expect(
        tester.getSize(find.byKey(const Key('collection-height'))).height,
        370.h,
      );
      expect(tester.getSize(find.byType(GridView)).height, 230.h);
      expect(tester.getSize(find.byType(VerticalCard).first).width, 160.w);
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in [
    const Size(768, 1024),
    const Size(1024, 1366),
    const Size(1032, 1376),
    const Size(1366, 1024),
  ]) {
    testWidgets('tablet $size has no vertical or popular card overflow', (
      tester,
    ) async {
      await pump(tester, size);
      expect(
        tester.getSize(find.byKey(const Key('collection-height'))).height,
        greaterThanOrEqualTo(370.h),
      );
      expect(
        tester.getSize(find.byType(GridView)).height,
        greaterThanOrEqualTo(230.h),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('tablet enlarged system text is included in height calculation', (
    tester,
  ) async {
    await pump(tester, const Size(1024, 1366), textScale: 1.5);
    expect(tester.takeException(), isNull);
  });
}
