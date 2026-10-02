import 'package:flutter/foundation.dart';
import 'package:muntum/stores/auth_state.dart';

class CurrentUserProfileImageStore extends ChangeNotifier {
  CurrentUserProfileImageStore._();

  static final instance = CurrentUserProfileImageStore._();

  String? _userId;
  String? _imageUrl;
  bool _hasValue = false;

  void update({required String userId, required String? imageUrl}) {
    if (userId.isEmpty) return;
    if (_hasValue && _userId == userId && _imageUrl == imageUrl) return;
    _userId = userId;
    _imageUrl = imageUrl;
    _hasValue = true;
    notifyListeners();
  }

  String? resolve({required String? userId, required String? apiImageUrl}) {
    if (_hasValue &&
        userId != null &&
        userId == AuthState.instance.userId &&
        userId == _userId) {
      return _imageUrl;
    }
    return apiImageUrl;
  }

  void refresh() {
    if (_hasValue) notifyListeners();
  }

  void clear() {
    if (!_hasValue) return;
    _userId = null;
    _imageUrl = null;
    _hasValue = false;
    notifyListeners();
  }
}
