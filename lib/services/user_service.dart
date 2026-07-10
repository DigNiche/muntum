import 'package:muntum/api/api_client.dart';
import 'package:muntum/api/api_endpoints.dart';
import 'package:muntum/api/token_store.dart';

class UserService {
  UserService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

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
}
