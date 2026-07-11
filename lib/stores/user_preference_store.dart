import 'package:flutter/foundation.dart';

class UserPreferenceStore extends ChangeNotifier {
  UserPreferenceStore._();

  static final UserPreferenceStore instance = UserPreferenceStore._();

  final Set<String> _selectedKeywords = {};

  Set<String> get selectedKeywords => Set.unmodifiable(_selectedKeywords);

  void updateKeywords(Iterable<String> keywords) {
    final nextKeywords = keywords
        .where((keyword) => keyword.trim().isNotEmpty)
        .toSet();
    if (_selectedKeywords.length == nextKeywords.length &&
        _selectedKeywords.containsAll(nextKeywords)) {
      return;
    }
    _selectedKeywords
      ..clear()
      ..addAll(nextKeywords);
    notifyListeners();
  }

  void clear() {
    if (_selectedKeywords.isEmpty) return;
    _selectedKeywords.clear();
    notifyListeners();
  }
}
