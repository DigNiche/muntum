import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/components/author_profile.dart';
import 'package:muntum/components/profile_avatar.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';

void main() {
  for (final width in [390.0, 430.0, 1024.0]) {
    for (final variant in ['standard', 'changeRequest', 'large']) {
      testWidgets('$variant at $width keeps dimensions, gap and action', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1366);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var tapped = false;
        final action = GestureDetector(
          onTap: () => tapped = true,
          child: Text(variant == 'changeRequest' ? '수정요청' : '메뉴'),
        );
        final profile = switch (variant) {
          'large' => AuthorProfile.large(
            name: '이초홍',
            createdAt: '26.12.12',
            role: 'CURATOR',
            trailing: action,
          ),
          'changeRequest' => AuthorProfile.changeRequest(
            name: '이초홍',
            createdAt: '26.12.12',
            role: 'CURATOR',
            trailing: action,
          ),
          _ => AuthorProfile.standard(
            name: '이초홍',
            createdAt: '26.12.12',
            role: 'CURATOR',
            trailing: action,
          ),
        };
        await tester.pumpWidget(
          ScreenUtilPlusInit(
            designSize: const Size(390, 844),
            builder: (_, _) => MaterialApp(home: Scaffold(body: profile)),
          ),
        );
        await tester.pumpAndSettle();
        final avatar = find.byType(ProfileAvatar);
        expect(
          tester.widget<Text>(find.text('이초홍')).style,
          (variant == 'large'
                  ? AppTypography.headline1
                  : AppTypography.headline3)
              .copyWith(color: AppColors.gray800),
        );
        expect(
          tester.getSize(avatar).width,
          closeTo((variant == 'large' ? 56 : 40).r, 0.01),
        );
        expect(
          tester.getTopLeft(find.text('이초홍')).dx -
              tester.getTopRight(avatar).dx,
          closeTo((variant == 'large' ? 16 : 12).w, 0.01),
        );
        expect(find.text('작성일 26.12.12'), findsOneWidget);
        expect(
          tester.getSize(find.byKey(const ValueKey('user-role-badge-'))).width,
          closeTo((variant == 'large' ? 20 : 16).r, 0.01),
        );
        expect(
          tester.widget<ProfileAvatar>(avatar).size.badgeDiameter,
          variant == 'large' ? 20 : 16,
        );
        await tester.tap(find.text(variant == 'changeRequest' ? '수정요청' : '메뉴'));
        expect(tapped, isTrue);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('empty date is hidden and long names do not overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (_, _) => const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 240,
              child: AuthorProfile.standard(
                name: '매우 긴 큐레이터 이름이 계속 이어지는 작성자 이름입니다',
                createdAt: '',
                trailing: Icon(Icons.more_vert),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('작성일'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
