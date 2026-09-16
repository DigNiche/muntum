import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/screens/mypage/curator/written_program_list_page.dart';
import 'package:muntum/screens/mypage/manager/program_edit_screen.dart';

void main() {
  Widget buildSubject() {
    return ScreenUtilPlusInit(
      designSize: const Size(390, 844),
      builder: (context, child) =>
          const MaterialApp(home: WrittenProgramList()),
    );
  }

  testWidgets('written program tabs filter the static UI list', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(buildSubject());

    expect(find.byKey(const ValueKey('written-program-1')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('written-program-tab-진행중')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('written-program-1')), findsNothing);
    expect(find.byKey(const ValueKey('written-program-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('written-program-3')), findsOneWidget);
    expect(find.byKey(const ValueKey('written-program-4')), findsNothing);
  });

  testWidgets('add button opens the program writer', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(buildSubject());

    await tester.tap(find.byKey(const ValueKey('written-program-add')));
    await tester.pumpAndSettle();

    expect(find.byType(ProgramEditScreen), findsOneWidget);
  });
}
