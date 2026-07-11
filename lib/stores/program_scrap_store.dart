import 'package:flutter/foundation.dart';
import 'package:muntum/models/program_model.dart';

class ProgramScrapStore extends ChangeNotifier {
  ProgramScrapStore._();

  static final ProgramScrapStore instance = ProgramScrapStore._();

  final Map<String, ProgramModel> _scrappedPrograms = {};
  final Set<String> _unscrappedProgramIds = {};

  List<ProgramModel> get scrappedPrograms => _scrappedPrograms.values.toList();

  bool isScrapped(ProgramModel program) {
    if (program.id.isNotEmpty && _scrappedPrograms.containsKey(program.id)) {
      return true;
    }
    if (program.id.isNotEmpty && _unscrappedProgramIds.contains(program.id)) {
      return false;
    }
    return program.isBookmark;
  }

  void setScrapped(
    ProgramModel program,
    bool isScrapped, {
    bool notify = true,
  }) {
    program.isBookmark = isScrapped;
    if (program.id.isNotEmpty) {
      if (isScrapped) {
        _unscrappedProgramIds.remove(program.id);
        _scrappedPrograms[program.id] = program;
      } else {
        _scrappedPrograms.remove(program.id);
        _unscrappedProgramIds.add(program.id);
      }
    }
    if (notify) notifyListeners();
  }

  void replaceScrappedPrograms(
    Iterable<ProgramModel> programs, {
    bool notify = true,
  }) {
    _scrappedPrograms.clear();
    _unscrappedProgramIds.clear();
    for (final program in programs) {
      program.isBookmark = true;
      if (program.id.isNotEmpty) {
        _scrappedPrograms[program.id] = program;
      }
    }
    if (notify) notifyListeners();
  }

  void clear({bool notify = true}) {
    _scrappedPrograms.clear();
    _unscrappedProgramIds.clear();
    if (notify) notifyListeners();
  }
}
