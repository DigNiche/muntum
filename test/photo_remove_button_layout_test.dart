import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/components/editable_photo_frame.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/mypage/curator/curation_write_screen.dart';
import 'package:muntum/screens/mypage/manager/program_edit_screen.dart';

void main() {
  Future<void> showScreen(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (_, _) => MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: screen,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void checkButtonBounds(WidgetTester tester, Finder viewport) {
    final bounds = tester.getRect(viewport);
    final buttons = find.byIcon(Icons.close);
    expect(buttons, findsAtLeastNWidgets(2));
    for (var index = 0; index < buttons.evaluate().length; index++) {
      final button = tester.getRect(
        find
            .ancestor(of: buttons.at(index), matching: find.byType(Positioned))
            .first,
      );
      expect(button.top, greaterThanOrEqualTo(bounds.top));
      expect(button.bottom, lessThanOrEqualTo(bounds.bottom));
    }
    final frames = find.byType(EditablePhotoFrame);
    for (var index = 0; index < frames.evaluate().length; index++) {
      final frame = frames.at(index);
      final widget = tester.widget<EditablePhotoFrame>(frame);
      expect(widget.topOffset, lessThan(0));
      expect(widget.rightOffset, lessThan(0));
      final thumbnail = tester.getRect(
        find.descendant(
          of: frame,
          matching: find.byKey(const ValueKey('editable-photo-thumbnail')),
        ),
      );
      final button = tester.getRect(
        find.descendant(
          of: frame,
          matching: find.byKey(const ValueKey('photo-remove-button')),
        ),
      );
      expect(button.top - thumbnail.top, closeTo(widget.topOffset, 0.01));
      expect(thumbnail.right - button.right, closeTo(widget.rightOffset, 0.01));
    }
  }

  testWidgets('program photo delete buttons stay inside the scroll viewport', (
    tester,
  ) async {
    await showScreen(
      tester,
      ProgramEditScreen(
        program: ProgramModel.fromJson({
          'id': 'photo-program',
          'title': '사진 테스트',
          'images': List.generate(
            5,
            (index) => {'imageUrl': 'https://example.com/photo-$index.png'},
          ),
        }),
      ),
    );
    checkButtonBounds(tester, find.byType(ReorderableListView));
    final button = tester.getRect(
      find.byKey(const ValueKey('photo-remove-button')).first,
    );
    await tester.tapAt(Offset(button.center.dx, button.top + 1));
    await tester.pumpAndSettle();
    expect(find.text('4/5'), findsOneWidget);
  });

  testWidgets('curation photo delete buttons stay inside the scroll viewport', (
    tester,
  ) async {
    const channel = MethodChannel('plugins.flutter.io/image_picker');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'pickMultiImage') {
            return List.filled(
              5,
              File('assets/appicon/Android.png').absolute.path,
            );
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    await showScreen(tester, const CurationWriteScreen());
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('5/5'), findsOneWidget);
    checkButtonBounds(tester, find.byType(ListView).last);
    final button = tester.getRect(
      find.byKey(const ValueKey('photo-remove-button')).first,
    );
    await tester.tapAt(Offset(button.center.dx, button.top + 1));
    await tester.pumpAndSettle();
    expect(find.text('4/5'), findsOneWidget);
  });
}
