import 'package:shared_preferences/shared_preferences.dart';
import 'package:muntum/stores/auth_state.dart';
import 'package:muntum/services/analytics_service.dart';

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
    String? role,
    String? authProvider,
  }) async {
    _accessToken = accessToken;
    AuthState.instance.replace(
      accessToken: accessToken,
      userId: userId,
      email: email,
      nickname: nickname,
      role: role,
    );
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
    if (role != null && role.isNotEmpty) {
      await prefs.setString('role', role);
    } else {
      await prefs.remove('role');
    }
    if (authProvider != null && authProvider.isNotEmpty) {
      await prefs.setString('authProvider', authProvider);
    }
    await AnalyticsService.instance.setUserId(userId);
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

  Future<String?> readRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  Future<String?> readAuthProvider() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authProvider');
  }

  Future<void> saveProfile({
    String? userId,
    String? email,
    String? nickname,
    String? role,
  }) async {
    AuthState.instance.update(
      userId: userId,
      email: email,
      nickname: nickname,
      role: role,
    );
    final prefs = await SharedPreferences.getInstance();
    if (userId != null) await prefs.setString('userId', userId);
    if (email != null) await prefs.setString('email', email);
    if (nickname != null) await prefs.setString('nickname', nickname);
    if (role != null) await prefs.setString('role', role);
  }

  Future<void> clear() async {
    _accessToken = null;
    AuthState.instance.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('refreshToken');
    await prefs.remove('userId');
    await prefs.remove('email');
    await prefs.remove('nickname');
    await prefs.remove('role');
    await prefs.remove('authProvider');
    await AnalyticsService.instance.setUserId(null);
  }
}
