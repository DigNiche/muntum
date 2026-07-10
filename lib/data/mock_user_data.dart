import 'package:flutter/foundation.dart';
import 'package:muntum/data/mock_program_data.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/models/user_keyword.dart';

class MockUserSession extends ChangeNotifier {
  MockUserSession._();

  static final MockUserSession instance = MockUserSession._();

  String? email;
  String? nickname;
  final List<String> selectedKeywords = List.of(userKeywords);

  bool get isLoggedIn => email != null && nickname != null;

  void loginAsMockUser({
    String email = 'mock@muntum.app',
    String nickname = '문화발굴단',
  }) {
    this.email = email;
    this.nickname = nickname;
    notifyListeners();
  }

  void logout() {
    email = null;
    nickname = null;
    notifyListeners();
  }

  void updateNickname(String nickname) {
    this.nickname = nickname;
    notifyListeners();
  }

  void updateKeywords(Iterable<String> keywords) {
    final nextKeywords = keywords.toList();
    if (listEquals(selectedKeywords, nextKeywords)) {
      return;
    }
    selectedKeywords
      ..clear()
      ..addAll(nextKeywords);
    userKeywords
      ..clear()
      ..addAll(selectedKeywords);
    notifyListeners();
  }
}

class MockBookmarkStore extends ChangeNotifier {
  MockBookmarkStore._();

  static final MockBookmarkStore instance = MockBookmarkStore._();

  final Set<String> _bookmarkedProgramIds = {};

  List<ProgramModel> get bookmarkedPrograms =>
      mockPrograms.where(isBookmarked).toList();

  bool isBookmarked(ProgramModel program) {
    if (program.id.isNotEmpty && _bookmarkedProgramIds.contains(program.id)) {
      return true;
    }
    return program.isBookmark;
  }

  void setBookmarked(ProgramModel program, bool isBookmarked) {
    program.isBookmark = isBookmarked;
    if (program.id.isNotEmpty) {
      if (isBookmarked) {
        _bookmarkedProgramIds.add(program.id);
      } else {
        _bookmarkedProgramIds.remove(program.id);
      }
    }
    notifyListeners();
  }

  void toggle(ProgramModel program) {
    setBookmarked(program, !isBookmarked(program));
  }

  void replaceBookmarkedPrograms(
    Iterable<ProgramModel> programs, {
    bool notify = true,
  }) {
    _bookmarkedProgramIds
      ..clear()
      ..addAll(
        programs
            .map((program) => program.id)
            .where((programId) => programId.isNotEmpty),
      );
    for (final program in programs) {
      program.isBookmark = true;
    }
    if (notify) {
      notifyListeners();
    }
  }

  void notifyChanged() {
    notifyListeners();
  }
}
