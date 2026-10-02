import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/api/api_client.dart';
import 'package:muntum/api/api_endpoints.dart';
import 'package:muntum/services/user_service.dart';
import 'package:muntum/stores/auth_state.dart';
import 'package:muntum/stores/current_user_profile_image_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'profile photo upload uses the required profileImage multipart part',
    () async {
      final client = _RecordingApiClient();
      AuthState.instance.replace(userId: 'user-1', role: 'AUDIENCE');
      addTearDown(() {
        CurrentUserProfileImageStore.instance.clear();
        AuthState.instance.clear();
      });

      final profile = await UserService(
        client: client,
      ).updateProfileImage('/tmp/profile.jpg');

      expect(client.path, ApiEndpoints.profileImage);
      expect(client.filePath, '/tmp/profile.jpg');
      expect(client.fileFieldName, 'profileImage');
      expect(client.authorized, isTrue);
      expect(profile.profileImageUrl, 'https://example.com/profile.jpg');
      expect(
        CurrentUserProfileImageStore.instance.resolve(
          userId: 'user-1',
          apiImageUrl: null,
        ),
        'https://example.com/profile.jpg',
      );
    },
  );

  test('nickname request keeps the exact text including spaces', () async {
    SharedPreferences.setMockInitialValues({});
    final client = _RecordingApiClient();

    await UserService(client: client).updateNickname(' 문틈 큐레이터 ');

    expect(client.path, ApiEndpoints.nickname);
    expect(client.body, {'nickname': ' 문틈 큐레이터 '});
    expect(client.authorized, isTrue);
  });
}

class _RecordingApiClient extends ApiClient {
  String? path;
  String? filePath;
  String? fileFieldName;
  bool? authorized;
  Map<String, dynamic>? body;

  @override
  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    bool authorized = false,
  }) async {
    this.path = path;
    this.body = body;
    this.authorized = authorized;
    return {'data': null};
  }

  @override
  Future<Map<String, dynamic>> putFile(
    String path, {
    required String filePath,
    String fileFieldName = 'image',
    bool authorized = false,
  }) async {
    this.path = path;
    this.filePath = filePath;
    this.fileFieldName = fileFieldName;
    this.authorized = authorized;
    return {
      'data': {
        'userId': 'user-1',
        'nickname': '사용자',
        'profileImageUrl': 'https://example.com/profile.jpg',
      },
    };
  }
}
