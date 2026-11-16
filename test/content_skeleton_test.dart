import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:muntum/components/content_skeleton.dart';

void main() {
  for (final viewport in [const Size(320, 568), const Size(1024, 768)]) {
    testWidgets('page skeletons fit a constrained viewport: $viewport', (
      tester,
    ) async {
      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final skeleton in const [
        PageLoadingSkeleton.programs(),
        PageLoadingSkeleton.rows(),
        PageLoadingSkeleton.detail(),
      ]) {
        await tester.pumpWidget(
          ScreenUtilPlusInit(
            designSize: const Size(390, 844),
            builder: (_, _) => MaterialApp(
              home: Scaffold(body: SizedBox(height: 120, child: skeleton)),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(SkeletonBlock), findsWidgets);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(tester.takeException(), isNull);
      }
    });
  }
}
