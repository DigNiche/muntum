import 'package:flutter/material.dart' as legacy_material;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:muntum/constants/app_theme.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/screens/program_detail/components/program_detail_markdown_body.dart';

void main() {
  Future<void> pumpBody(
    WidgetTester tester,
    String markdown, {
    ValueChanged<String>? onTapLink,
  }) async {
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (_, _) => MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProgramDetailMarkdownBody(
                markdown: markdown,
                onTapLink: onTapLink ?? (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('markdown renders under migrated theme with selection colors', (
    tester,
  ) async {
    await pumpBody(tester, '# 소개\n\n**한글** 설명\n\n- 목록\n\n> 인용');
    expect(tester.takeException(), isNull);
    expect(find.byType(legacy_material.SelectableText), findsWidgets);
    final context = tester.element(find.byType(MarkdownBody));
    final selection = legacy_material.TextSelectionTheme.of(context);
    expect(selection.cursorColor, AppColors.black);
    expect(selection.selectionHandleColor, AppColors.black);
    expect(selection.selectionColor, AppColors.black.withValues(alpha: 0.18));
    final theme = legacy_material.Theme.of(context);
    expect(theme.primaryColor, AppTheme.light.primaryColor);
    expect(theme.dividerColor, AppTheme.light.dividerColor);
    expect(theme.textTheme.bodyMedium, Theme.of(context).textTheme.bodyMedium);
  });

  testWidgets('program points keep separate bodies and links remain tappable', (
    tester,
  ) async {
    String? tapped;
    await pumpBody(
      tester,
      '소개\n\n---\n\n## 프로그램 포인트\n\n[링크](https://example.com)',
      onTapLink: (url) => tapped = url,
    );
    expect(find.byType(MarkdownBody), findsNWidgets(2));
    final bodies = tester.widgetList<MarkdownBody>(find.byType(MarkdownBody));
    expect(bodies.every((body) => !body.data.contains('---')), isTrue);
    await tester.tap(find.text('링크', findRichText: true));
    expect(tapped, 'https://example.com');
    expect(tester.takeException(), isNull);
  });
}
