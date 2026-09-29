import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/components/cards/horizontal.dart';
import 'package:muntum/components/cards/map_horizontal_card.dart';
import 'package:muntum/components/cards/vertical_card.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/map/components/program_marker_icon.dart';

void main() {
  final curatedEnded = ProgramModel.fromJson({
    'id': 'curated-ended',
    'title': '종료된 큐레이션 프로그램',
    'ended': true,
    'curator': {'nickname': '큐레이터'},
  });
  final plain = ProgramModel.fromJson({'id': 'plain', 'title': '일반 프로그램'});

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
