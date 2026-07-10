import 'package:shared_preferences/shared_preferences.dart';

class TokenStore {
  TokenStore._();

  static final TokenStore instance = TokenStore._();

  String? _accessToken;

  String? get accessToken => _accessToken;

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? userId,
    String? email,
    String? nickname,
  }) async {
    _accessToken = accessToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('refreshToken', refreshToken);
    if (userId != null) {
      await prefs.setString('userId', userId);
    } else {
      await prefs.remove('userId');
    }
    if (email != null) {
      await prefs.setString('email', email);
    } else {
      await prefs.remove('email');
    }
    if (nickname != null && nickname.isNotEmpty) {
      await prefs.setString('nickname', nickname);
    } else {
      await prefs.remove('nickname');
    }
  }

  Future<String?> readRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refreshToken');
  }

  Future<String?> readEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email');
  }

  Future<String?> readNickname() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('nickname');
  }

  Future<void> saveProfile({
    String? userId,
    String? email,
    String? nickname,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId != null) await prefs.setString('userId', userId);
    if (email != null) await prefs.setString('email', email);
    if (nickname != null) await prefs.setString('nickname', nickname);
  }

  Future<void> clear() async {
    _accessToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('refreshToken');
    await prefs.remove('userId');
    await prefs.remove('email');
    await prefs.remove('nickname');
  }
}
