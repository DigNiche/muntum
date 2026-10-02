import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/components/popup_widget.dart';
import 'package:muntum/constants/app_theme.dart';
import 'package:muntum/constants/colors.dart';

void main() {
  test('app theme replaces default Material accent colors', () {
    expect(AppTheme.light.colorScheme.primary, AppColors.primary500);
    expect(AppTheme.light.progressIndicatorTheme.color, AppColors.gray900);
    expect(AppTheme.light.textSelectionTheme.cursorColor, AppColors.gray900);
    expect(
      AppTheme.light.textSelectionTheme.selectionHandleColor,
      AppColors.primary500,
    );
  });

  testWidgets('curation confirmation uses the app popup and can cancel', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    bool? confirmed;
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (dialogContext) => TextButton(
                onPressed: () async {
                  confirmed = await showConfirmationPopupWidget(
                    context: dialogContext,
                    title: '작성한 글을 삭제할까요?',
                    description: '삭제한 글은 복구할 수 없어요.',
                    confirmText: '삭제',
                    confirmColor: AppColors.error,
                  );
                },
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('작성한 글을 삭제할까요?'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(confirmed, isFalse);
  });
}
