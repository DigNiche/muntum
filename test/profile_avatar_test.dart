import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/components/profile_avatar.dart';
import 'package:muntum/models/curation_model.dart';
import 'package:muntum/models/admin_curation_model.dart';

void main() {
  Future<void> show(WidgetTester tester, ProfileAvatar avatar) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (_, _) => MaterialApp(
          home: Scaffold(body: Center(child: avatar)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final size in ProfileAvatarSize.values) {
    for (final role in ['CURATOR', 'MANAGER']) {
      testWidgets('${size.name} avatar and $role badge use fixed diameters', (
        tester,
      ) async {
        await show(
          tester,
          ProfileAvatar(userId: 'user', role: role, size: size),
        );
        expect(
          tester.getSize(find.byType(ProfileAvatar)),
          Size(size.diameter, size.diameter),
        );
        final badge = find.byKey(const ValueKey('user-role-badge-user'));
        expect(
          tester.getSize(badge),
          Size(size.badgeDiameter, size.badgeDiameter),
        );
        final svg =
            tester.widget<SvgPicture>(badge).bytesLoader as SvgAssetLoader;
        expect(
          svg.assetName,
          'assets/icons/${role == 'MANAGER' ? 'manager' : 'curator'}_badge.svg',
        );
        final avatarRect = tester.getRect(find.byType(ProfileAvatar));
        final badgeRect = tester.getRect(badge);
        expect(avatarRect.contains(badgeRect.topLeft), isTrue);
        expect(badgeRect.right, lessThanOrEqualTo(avatarRect.right));
        expect(badgeRect.bottom, lessThanOrEqualTo(avatarRect.bottom));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('audience avatar does not render a staff badge', (tester) async {
    await show(tester, const ProfileAvatar(role: 'AUDIENCE'));
    expect(find.byType(SvgPicture), findsNothing);
    expect(find.byType(ClipOval), findsOneWidget);
  });

  testWidgets('editing preview can suppress badge and current user override', (
    tester,
  ) async {
    await show(
      tester,
      const ProfileAvatar(
        role: 'MANAGER',
        size: ProfileAvatarSize.large,
        showRoleBadge: false,
        useCurrentUserImage: false,
      ),
    );
    expect(find.byType(SvgPicture), findsNothing);
    expect(tester.getSize(find.byType(ProfileAvatar)), const Size(56, 56));
  });

  test(
    'public and manager curator models preserve manager role for avatars',
    () {
      final json = {
        'id': 'note',
        'curator': {'curatorId': 'author', 'role': 'MANAGER'},
      };
      expect(PublicCurationModel.fromJson(json).curatorRole, 'MANAGER');
      expect(AdminCurationModel.fromJson(json).curator.role, 'MANAGER');
    },
  );
}
