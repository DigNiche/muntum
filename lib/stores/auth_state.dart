import 'package:flutter/foundation.dart';

class AuthState extends ChangeNotifier {
  AuthState._();

  static final AuthState instance = AuthState._();

  String? _accessToken;
  String? _userId;
  String? _email;
  String? _nickname;
  String? _role;

  String? get accessToken => _accessToken;
  String? get userId => _userId;
  String? get email => _email;
  String? get nickname => _nickname;
  String? get role => _role;

  bool get isLoggedIn => _accessToken?.isNotEmpty == true;
  bool get isAdmin => _role == 'MANAGER';

  void update({
    String? accessToken,
    String? userId,
    String? email,
    String? nickname,
    String? role,
  }) {
    var changed = false;

    changed =
        _setIfProvided(
          () => _accessToken,
          (value) => _accessToken = value,
          accessToken,
        ) ||
        changed;
    changed =
        _setIfProvided(() => _userId, (value) => _userId = value, userId) ||
        changed;
    changed =
        _setIfProvided(() => _email, (value) => _email = value, email) ||
        changed;
    changed =
        _setIfProvided(
          () => _nickname,
          (value) => _nickname = value,
          nickname,
        ) ||
        changed;
    changed =
        _setIfProvided(() => _role, (value) => _role = value, role) || changed;

    if (changed) notifyListeners();
  }

  void replace({
    String? accessToken,
    String? userId,
    String? email,
    String? nickname,
    String? role,
  }) {
    final changed =
        _accessToken != accessToken ||
        _userId != userId ||
        _email != email ||
        _nickname != nickname ||
        _role != role;

    _accessToken = accessToken;
    _userId = userId;
    _email = email;
    _nickname = nickname;
    _role = role;

    if (changed) notifyListeners();
  }

  void clear() {
    replace();
  }

  bool _setIfProvided(
    String? Function() current,
    void Function(String?) setValue,
    String? next,
  ) {
    if (next == null) return false;
    if (current() == next) return false;
    setValue(next);
    return true;
  }
}
