import 'package:muntum/models/program_model.dart';

int programKeywordMatchCount(
  ProgramModel program,
  Iterable<String> selectedKeywords,
) {
  final selected = selectedKeywords
      .map((keyword) => keyword.trim())
      .where((keyword) => keyword.isNotEmpty)
      .toSet();
  if (selected.isEmpty) {
    return 0;
  }

  return program.keywords
      .map((keyword) => keyword.trim())
      .where(selected.contains)
      .toSet()
      .length;
}

int programKeywordMatchLevel(
  ProgramModel program,
  Iterable<String> selectedKeywords,
) {
  return programKeywordMatchCount(program, selectedKeywords).clamp(0, 3);
}

List<ProgramModel> sortProgramsByKeywordMatch(
  Iterable<ProgramModel> programs,
  Iterable<String> selectedKeywords,
) {
  final indexedPrograms = programs.indexed.toList();
  indexedPrograms.sort((left, right) {
    final leftScore = programKeywordMatchCount(left.$2, selectedKeywords);
    final rightScore = programKeywordMatchCount(right.$2, selectedKeywords);
    final scoreCompare = rightScore.compareTo(leftScore);
    if (scoreCompare != 0) {
      return scoreCompare;
    }
    return left.$1.compareTo(right.$1);
  });
  return indexedPrograms.map((item) => item.$2).toList();
}
