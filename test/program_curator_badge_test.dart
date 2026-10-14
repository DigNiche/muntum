import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/components/cards/horizontal.dart';
import 'package:muntum/components/cards/map_horizontal_card.dart';
import 'package:muntum/components/cards/vertical_card.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/components/program_curator_badge.dart';
import 'package:muntum/screens/map/components/program_marker_icon.dart';

void main() {
  final curatedEnded = ProgramModel.fromJson({
    'id': 'curated-ended',
    'title': '종료된 큐레이션 프로그램',
    'ended': true,
  })..hasCurator = true;
  final plain = ProgramModel.fromJson({'id': 'plain', 'title': '일반 프로그램'});

  for (final size in [const Size(390, 844), const Size(1024, 1366)]) {
    for (final selected in [false, true]) {
      testWidgets(
        'map badge stays attached to marker at $size selected=$selected',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            ScreenUtilPlusInit(
              designSize: const Size(390, 844),
              builder: (_, _) => MaterialApp(
                home: Scaffold(
                  body: Center(
                    child: ProgramMarkerIcon(
                      program: curatedEnded,
                      isSelected: selected,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final marker = tester.getRect(find.byType(ProgramMarkerIcon));
          final circle = tester.getRect(
            find.descendant(
              of: find.byType(ProgramMarkerIcon),
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is SizedBox &&
                    widget.width == 44.w &&
                    widget.height == 44.w,
              ),
            ),
          );
          final badge = tester.getRect(find.byType(ProgramCuratorBadge));
          expect(marker.width, closeTo(64.w, .01));
          expect(marker.height, closeTo(64.w, .01));
          expect(circle.center.dx, closeTo(marker.center.dx, .01));
          expect(circle.center.dy, closeTo(marker.center.dy, .01));
          expect(badge.right, closeTo(circle.right, .01));
          expect(badge.top, closeTo(circle.top, .01));
          expect(badge.width, closeTo(18.w, .01));
          expect(badge.height, closeTo(18.w, .01));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final buildCard in <Widget Function(ProgramModel)>[
    (program) => HorizontalCard(program: program, onTap: () {}),
    (program) => VerticalCard(program: program),
    (program) => MapHorizontalCard(program: program, onTap: () {}),
    (program) => ProgramMarkerIcon(program: program),
  ]) {
    testWidgets('curated ended program keeps a badge; plain program does not', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Future<void> pump(ProgramModel program) => tester.pumpWidget(
        ScreenUtilPlusInit(
          designSize: const Size(390, 844),
          builder: (context, child) =>
              MaterialApp(home: Scaffold(body: buildCard(program))),
        ),
      );

      await pump(curatedEnded);
      expect(
        find.byKey(const ValueKey('program-curator-badge')),
        findsOneWidget,
      );
      await pump(plain);
      expect(find.byKey(const ValueKey('program-curator-badge')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
