import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/constants/app_scroll_behavior.dart';

void main() {
  Future<void> showList(
    WidgetTester tester,
    ScrollController controller, {
    ScrollPhysics? physics,
    Axis axis = Axis.vertical,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        scrollBehavior: const AppScrollBehavior(),
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            child: ListView.builder(
              key: const ValueKey('test-list'),
              controller: controller,
              physics: physics,
              scrollDirection: axis,
              itemExtent: 60,
              itemCount: 200,
              itemBuilder: (_, index) => Text('item $index'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('default iOS physics adds momentum, app rules do not', () {
    const previous = BouncingScrollPhysics();
    const replacement = ClampingScrollPhysics();
    expect(previous.carriedMomentum(1000), greaterThan(0));
    expect(replacement.carriedMomentum(1000), 0);
  });

  testWidgets(
    'same drag moves equally near the top, middle and bottom',
    (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await showList(tester, controller);
      final physics = controller.position.physics;
      expect(physics, isA<ClampingScrollPhysics>());
      expect(physics.carriedMomentum(2500), 0);
      final distances = <double>[];
      for (final start in [
        50.0,
        3500.0,
        controller.position.maxScrollExtent - 300,
      ]) {
        controller.jumpTo(start);
        await tester.pumpAndSettle();
        final gesture = await tester.startGesture(const Offset(200, 300));
        await gesture.moveBy(const Offset(0, -30));
        await tester.pump();
        final before = controller.offset;
        await gesture.moveBy(const Offset(0, -100));
        await tester.pump();
        distances.add(controller.offset - before);
        await gesture.up();
        await tester.pumpAndSettle();
      }
      for (final distance in distances) {
        expect(distance, closeTo(100, 0.01));
      }
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.iOS,
      TargetPlatform.android,
    }),
  );

  testWidgets(
    'endpoints clamp without bouncing beyond the content',
    (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await showList(tester, controller);
      final gesture = await tester.startGesture(const Offset(200, 200));
      await gesture.moveBy(const Offset(0, 250));
      await tester.pump();
      expect(controller.offset, 0);
      await gesture.up();
      await tester.pumpAndSettle();
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pump();
      await tester.drag(
        find.byKey(const ValueKey('test-list')),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      expect(controller.position.outOfRange, false);
      expect(controller.offset, controller.position.maxScrollExtent);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.iOS,
      TargetPlatform.android,
    }),
  );

  testWidgets('refresh-enabled lists retain scrolling but not added momentum', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await showList(
      tester,
      controller,
      physics: const AlwaysScrollableScrollPhysics(),
    );
    final physics = controller.position.physics;
    expect(physics, isA<AlwaysScrollableScrollPhysics>());
    expect(physics.parent, isA<ClampingScrollPhysics>());
    expect(physics.shouldAcceptUserOffset(controller.position), true);
    expect(physics.carriedMomentum(2000), 0);
  });

  testWidgets('horizontal lists inherit the same consistent rules', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await showList(tester, controller, axis: Axis.horizontal);
    expect(controller.position.physics, isA<ClampingScrollPhysics>());
    await tester.drag(
      find.byKey(const ValueKey('test-list')),
      const Offset(-200, 0),
    );
    await tester.pumpAndSettle();
    expect(controller.offset, greaterThan(0));
  });

  testWidgets('carousel snapping and explicitly disabled scrolling survive', (
    tester,
  ) async {
    final controller = PageController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        scrollBehavior: const AppScrollBehavior(),
        home: Scaffold(
          body: PageView(
            controller: controller,
            children: const [Text('first'), Text('second'), Text('third')],
          ),
        ),
      ),
    );
    await tester.fling(find.byType(PageView), const Offset(-500, 0), 1000);
    await tester.pumpAndSettle();
    expect(controller.page, closeTo(1, 0.001));
    ScrollPhysics? physics = controller.position.physics;
    while (physics != null && physics is! PageScrollPhysics) {
      physics = physics.parent;
    }
    expect(physics, isA<PageScrollPhysics>());
    await tester.pumpWidget(
      MaterialApp(
        scrollBehavior: const AppScrollBehavior(),
        home: ListView(
          physics: const NeverScrollableScrollPhysics(),
          children: const [SizedBox(height: 2000)],
        ),
      ),
    );
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position;
    expect(position.physics.allowUserScrolling, false);
  });
}
