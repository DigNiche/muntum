import 'dart:convert';

import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:muntum/screens/map/components/map_bottom_sheet.dart';
import 'package:muntum/screens/map/map_sheet_layout.dart';
import 'package:muntum/screens/program_detail/components/program_poster_carousel.dart';

void main() {
  for (final height in [600.0, 844.0, 1366.0]) {
    test('overlay displacement uses map viewport height $height', () {
      for (final extent in [32 / height, .26, .78]) {
        final layout = MapSheetLayout(
          viewportHeight: height,
          extent: extent,
          initialExtent: .26,
          initialLocationBottom: 220,
          initialSearchBottom: 210,
          topPadding: 140,
        );
        expect(
          layout.locationBottom - 220,
          closeTo(height * (extent - .26), .001),
        );
        expect(
          layout.searchBottom - 210,
          closeTo(height * (extent - .26), .001),
        );
        expect(layout.contentPadding.bottom, closeTo(height * extent, .001));
        expect(layout.contentPadding.top, 140);
      }
    });
  }
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (_, _) => MaterialApp(home: Scaffold(body: child)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('map panel collapses to handle and reopens without overflow', (
    tester,
  ) async {
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    late double collapsed;
    late double viewportHeight;
    await pump(
      tester,
      LayoutBuilder(
        builder: (context, constraints) {
          collapsed = 32.h / constraints.maxHeight;
          viewportHeight = constraints.maxHeight;
          final sheet = DraggableScrollableSheet(
            controller: controller,
            initialChildSize: .26,
            minChildSize: collapsed,
            maxChildSize: .78,
            snap: true,
            snapSizes: [collapsed, .26, .78],
            builder: (_, scroll) => MapProgramBottomPanel(
              scrollController: scroll,
              sheetController: controller,
              minChildSize: collapsed,
              maxChildSize: .78,
              snapSizes: const [.26],
              programs: const [],
            ),
          );
          return AnimatedBuilder(
            animation: controller,
            child: sheet,
            builder: (_, child) {
              final layout = MapSheetLayout(
                viewportHeight: viewportHeight,
                extent: controller.isAttached ? controller.size : .26,
                initialExtent: .26,
                initialLocationBottom: 220.h,
                initialSearchBottom: 210.h,
                topPadding: 140.h,
              );
              return Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      key: const ValueKey('sdk-padding'),
                      padding: layout.contentPadding,
                      child: const SizedBox.expand(),
                    ),
                  ),
                  Positioned(
                    bottom: layout.locationBottom,
                    right: 0,
                    child: const SizedBox(
                      key: ValueKey('location'),
                      width: 10,
                      height: 10,
                    ),
                  ),
                  Positioned(
                    bottom: layout.searchBottom,
                    left: 0,
                    child: const SizedBox(
                      key: ValueKey('search'),
                      width: 10,
                      height: 10,
                    ),
                  ),
                  child!,
                ],
              );
            },
          );
        },
      ),
    );
    final handle = find
        .descendant(
          of: find.byType(MapProgramBottomPanel),
          matching: find.byType(GestureDetector),
        )
        .first;
    final initialLocationTop = tester
        .getTopLeft(find.byKey(const ValueKey('location')))
        .dy;
    final initialSearchTop = tester
        .getTopLeft(find.byKey(const ValueKey('search')))
        .dy;
    void expectOverlayPositions() {
      final shift = viewportHeight * (.26 - controller.size);
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('location'))).dy,
        closeTo(initialLocationTop + shift, .01),
      );
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('search'))).dy,
        closeTo(initialSearchTop + shift, .01),
      );
      final sdkPadding = tester.widget<Padding>(
        find.byKey(const ValueKey('sdk-padding')),
      );
      expect(
        (sdkPadding.padding as EdgeInsets).bottom,
        closeTo(viewportHeight * controller.size, .01),
      );
    }

    await tester.drag(handle, const Offset(0, 200));
    await tester.pumpAndSettle();
    expect(controller.size, closeTo(collapsed, .001));
    expectOverlayPositions();
    expect(tester.takeException(), isNull);
    await tester.tap(handle);
    await tester.pumpAndSettle();
    expect(controller.size, closeTo(.26, .001));
    expectOverlayPositions();
    await tester.drag(handle, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(controller.size, closeTo(.78, .001));
    expectOverlayPositions();
    expect(tester.takeException(), isNull);
    final animation = controller.animateTo(
      collapsed,
      duration: const Duration(milliseconds: 220),
      curve: Curves.linear,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.size, greaterThan(collapsed));
    expect(controller.size, lessThan(.78));
    expectOverlayPositions();
    await tester.pumpAndSettle();
    await animation;
    expect(controller.size, closeTo(collapsed, .001));
    expectOverlayPositions();
  });

  for (final count in [0, 1, 2]) {
    testWidgets('poster with $count images only shows dots for multiple images', (
      tester,
    ) async {
      final bytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aZ1kAAAAASUVORK5CYII=',
      );
      await pump(
        tester,
        ProgramPosterCarousel(
          images: List.generate(count, (_) => Image.memory(bytes)),
        ),
      );
      expect(
        find.byType(AnimatedContainer),
        count > 1 ? findsNWidgets(count) : findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
