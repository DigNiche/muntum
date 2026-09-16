import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/screens/mypage/curator/components/curator_welcome_card.dart';

void main() {
  testWidgets('curator welcome card exposes dismiss and activity actions', (
    tester,
  ) async {
    var didClose = false;
    var didTapAction = false;

    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(
          home: Scaffold(
            body: CuratorWelcomeCard(
              nickname: '문화발굴단',
              onClose: () => didClose = true,
              onTapAction: () => didTapAction = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('문화발굴단님,\n큐레이터가 되신 것을 축하합니다!'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('curator-welcome-celebration')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('curator-welcome-close')));
    expect(didClose, isTrue);

    await tester.tap(find.text('지금 바로 활동을 시작해보세요'));
    expect(didTapAction, isTrue);
  });
}
