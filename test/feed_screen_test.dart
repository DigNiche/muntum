import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:muntum/screens/home/feed_screen.dart';

void main() {
  testWidgets('feed reserves design sizes and keeps editor actions unwired', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (_, _) => const MaterialApp(home: FeedScreen(isActive: false)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('피드'), findsOneWidget);
    expect(find.text('전체'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    final firstPick = find.byKey(const ValueKey('editor-pick-placeholder-0'));
    expect(tester.getSize(firstPick), const Size(330, 248));
    final firstNote = find
        .byKey(const ValueKey('editor-note-placeholder'))
        .first;
    expect(tester.getSize(firstNote).height, closeTo(486, 0.1));

    final carousel = find.byWidgetPredicate(
      (widget) =>
          widget is ListView && widget.scrollDirection == Axis.horizontal,
    );
    await tester.drag(carousel, const Offset(-650, 0));
    await tester.pumpAndSettle();
    final seeAll = find.text('에디터픽 전체보기').hitTestable();
    expect(seeAll, findsOneWidget);
    await tester.tap(seeAll);
    await tester.pumpAndSettle();
    expect(find.byType(FeedScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
