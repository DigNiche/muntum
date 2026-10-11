import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/screens/home/components/section_header.dart';
import 'package:muntum/utils/tablet_text_layout.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('SUIT');
    for (final font in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      loader.addFont(rootBundle.load('assets/fonts/SUIT-$font.ttf'));
    }
    await loader.load();
  });
  Future<void> pump(
    WidgetTester tester,
    Size size, {
    double scale = 1,
    bool keywords = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = TextEditingController(text: '검색어');
    addTearDown(controller.dispose);
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
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                body: Column(
                  children: [
                    AppBarWidget(
                      centerType: AppBarCenterType.searchbar,
                      leadingIcon: 'arrow_left.svg',
                      searchController: controller,
                      selectedKeywords: keywords ? ['감성 낭만 충전'] : [],
                    ),
                    const SectionHeader2(
                      text: '인기키워드',
                      buttonName: '여러 키워드로 검색',
                    ),
                    const SectionHeader2(text: '최근 검색어', buttonName: '전체 삭제'),
                  ],
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
    testWidgets('phone $size keeps header and searchbar dimensions', (
      tester,
    ) async {
      await pump(tester, size);
      expect(tester.getSize(find.byType(AppBarWidget)).height, 64.h);
      for (final header in find.byType(SectionHeader2).evaluate()) {
        expect(tester.getSize(find.byWidget(header.widget)).height, 30.h);
      }
      expect(
        tester.widget<TextField>(find.byType(TextField)).style?.fontSize,
        AppTypography.body2.fontSize,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in [
    const Size(768, 1024),
    const Size(1024, 1366),
    const Size(1032, 1376),
    const Size(1366, 1024),
  ]) {
    testWidgets('tablet $size headings and input text have enough height', (
      tester,
    ) async {
      await pump(tester, size);
      for (final title in ['인기키워드', '최근 검색어']) {
        final text = find.text(title);
        final expected = TabletTextLayout.lineHeight(
          tester.element(text),
          title,
          AppTypography.headline1,
        );
        expect(tester.getSize(text).height, greaterThanOrEqualTo(expected));
        final header = find.ancestor(
          of: text,
          matching: find.byType(SectionHeader2),
        );
        expect(
          tester.getSize(header).height,
          greaterThanOrEqualTo(expected + 8.h),
        );
      }
      final editable = tester
          .state<EditableTextState>(find.byType(EditableText))
          .renderEditable;
      final expected = TabletTextLayout.lineHeight(
        tester.element(find.byType(TextField)),
        '검색어',
        AppTypography.body2,
      );
      expect(editable.size.height, greaterThanOrEqualTo(expected));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('tablet enlarged text and keyword search fit', (tester) async {
    await pump(tester, const Size(1024, 1366), scale: 1.5);
    expect(tester.takeException(), isNull);
    await pump(tester, const Size(1024, 1366), scale: 1.5, keywords: true);
    expect(tester.takeException(), isNull);
  });
}
