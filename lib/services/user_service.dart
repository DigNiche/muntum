import 'package:muntum/api/api_client.dart';
import 'package:muntum/api/api_endpoints.dart';
import 'package:muntum/api/token_store.dart';
import 'package:muntum/api/api_response.dart';
import 'package:muntum/models/user_profile_model.dart';

class UserService {
  UserService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<UserProfileModel> fetchProfile() async {
    final response = await _client.get(ApiEndpoints.me, authorized: true);
    return ApiResponse.fromJson(
      response,
      (data) =>
          UserProfileModel.fromJson(data as Map<String, dynamic>? ?? const {}),
    ).data;
  }

  Future<UserProfileModel> updateProfileImage(String filePath) async {
    final response = await _client.putFile(
      ApiEndpoints.profileImage,
      filePath: filePath,
      fileFieldName: 'image',
      authorized: true,
    );
    return ApiResponse.fromJson(
      response,
      (data) =>
          UserProfileModel.fromJson(data as Map<String, dynamic>? ?? const {}),
    ).data;
  }

  Future<UserProfileModel> deleteProfileImage() async {
    final response = await _client.delete(
      ApiEndpoints.profileImage,
      authorized: true,
    );
    return ApiResponse.fromJson(
      response,
      (data) =>
          UserProfileModel.fromJson(data as Map<String, dynamic>? ?? const {}),
    ).data;
  }

  Future<void> updateNickname(String nickname) async {
    await _client.patch(
      ApiEndpoints.nickname,
      authorized: true,
      body: {'nickname': nickname},
    );
    await TokenStore.instance.saveProfile(nickname: nickname);
  }

  Future<void> updateTermsConsent(Map<String, dynamic> consent) async {
    await _client.patch(
      ApiEndpoints.termsConsent,
      authorized: true,
      body: consent,
    );
  }

  Future<void> updateLocationTermsConsent(bool agreed) async {
    await updateTermsConsent({
      'terms': [
        {'termType': 'LOCATION_TERMS', 'agreed': agreed},
      ],
    });
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.patch(
      ApiEndpoints.password,
      authorized: true,
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }

  Future<void> withdraw({required String password}) async {
    await _client.post(
      ApiEndpoints.me,
      authorized: true,
      body: {'password': password},
    );
  }

  Future<void> withdrawWithApple({
    required String token,
    required String authorizationCode,
    required String nonce,
  }) async {
    await _client.post(
      ApiEndpoints.me,
      authorized: true,
      body: {
        'token': token,
        'authorizationCode': authorizationCode,
        'nonce': nonce,
      },
    );
  }
}
