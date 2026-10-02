import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/models/user_profile_model.dart';
import 'package:muntum/screens/mypage/common/nickname_change_screen.dart';
import 'package:muntum/screens/onboarding/sign_up_screens/nickname_screen.dart';
import 'package:muntum/services/user_service.dart';

void main() {
  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (_, _) => MaterialApp(home: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('profile edit sends spaces exactly as entered', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = _RecordingUserService();
    await pumpScreen(tester, NickNameChangeScreen(service: service));

    await tester.enterText(find.byType(TextField), ' 문틈 큐레이터 ');
    await tester.pump();
    await tester.tap(find.text('완료'));
    await tester.pump();

    expect(service.updatedNickname, ' 문틈 큐레이터 ');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    service.finishUpdate();
  });

  testWidgets('onboarding accepts a nickname containing a space', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = _RecordingUserService();
    await pumpScreen(tester, NicknameScreen(service: service));

    await tester.enterText(find.byType(TextField), '문틈 큐레이터');
    await tester.tap(find.text('다음으로'));
    await tester.pump();

    expect(service.updatedNickname, '문틈 큐레이터');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    service.finishUpdate();
  });
}

class _RecordingUserService extends UserService {
  final _updateCompleter = Completer<void>();
  String? updatedNickname;

  @override
  Future<UserProfileModel> fetchProfile() async => UserProfileModel.fromJson({
    'userId': 'user-1',
    'nickname': '문틈',
    'role': 'AUDIENCE',
  });

  @override
  Future<void> updateNickname(String nickname) {
    updatedNickname = nickname;
    return _updateCompleter.future;
  }

  void finishUpdate() {
    if (!_updateCompleter.isCompleted) _updateCompleter.complete();
  }
}
