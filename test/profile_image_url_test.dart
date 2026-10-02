import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/models/admin_curation_model.dart';
import 'package:muntum/models/admin_user_model.dart';
import 'package:muntum/models/curation_model.dart';
import 'package:muntum/models/curator_application_model.dart';
import 'package:muntum/models/user_profile_model.dart';
import 'package:muntum/stores/auth_state.dart';
import 'package:muntum/stores/current_user_profile_image_store.dart';
import 'package:muntum/utils/image_url.dart';

void main() {
  const bareUrl = 'd1kumw248404ec.cloudfront.net/profile/avatar.jpg';
  const normalizedUrl = 'https://$bareUrl';

  test(
    'normalizes backend image URL formats without changing absolute URLs',
    () {
      expect(normalizeImageUrl(bareUrl), normalizedUrl);
      expect(normalizeImageUrl('  $bareUrl  '), normalizedUrl);
      expect(
        normalizeImageUrl('//cdn.example.com/avatar.jpg'),
        'https://cdn.example.com/avatar.jpg',
      );
      expect(
        normalizeImageUrl('/profile/avatar.jpg'),
        'https://api.muntum.work/profile/avatar.jpg',
      );
      expect(
        normalizeImageUrl('https://example.com/avatar.jpg'),
        'https://example.com/avatar.jpg',
      );
      expect(normalizeOptionalImageUrl(null), isNull);
    },
  );

  test('every profile response supplies an absolute avatar URL', () {
    expect(
      UserProfileModel.fromJson({'profileImageUrl': bareUrl}).profileImageUrl,
      normalizedUrl,
    );
    expect(
      CuratorProfileModel.fromJson({
        'profileImageUrl': bareUrl,
      }).profileImageUrl,
      normalizedUrl,
    );
    expect(
      AdminUserModel.fromJson({'profileImageUrl': bareUrl}).profileImageUrl,
      normalizedUrl,
    );
    expect(
      CuratorApplicantModel.fromJson({
        'profileImageUrl': bareUrl,
      }).profileImageUrl,
      normalizedUrl,
    );
    expect(
      AdminCuratorModel.fromJson({'profileImageUrl': bareUrl}).profileImageUrl,
      normalizedUrl,
    );
  });

  test("the current user's new image overrides only their stale avatar", () {
    AuthState.instance.replace(userId: 'me', role: 'CURATOR');
    addTearDown(() {
      CurrentUserProfileImageStore.instance.clear();
      AuthState.instance.clear();
    });
    final store = CurrentUserProfileImageStore.instance;
    store.update(userId: 'me', imageUrl: normalizedUrl);

    expect(store.resolve(userId: 'me', apiImageUrl: null), normalizedUrl);
    expect(
      store.resolve(userId: 'someone-else', apiImageUrl: 'https://other.jpg'),
      'https://other.jpg',
    );
    store.update(userId: 'me', imageUrl: null);
    expect(store.resolve(userId: 'me', apiImageUrl: normalizedUrl), isNull);
    AuthState.instance.clear();
    expect(
      store.resolve(userId: 'me', apiImageUrl: normalizedUrl),
      normalizedUrl,
    );
  });
}
