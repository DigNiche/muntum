import 'package:muntum/models/program_model.dart';

/// 프로그램 검색과 필터링 규칙을 모든 화면에서 동일하게 사용합니다.
List<ProgramModel> queryPrograms(
  Iterable<ProgramModel> programs, {
  String query = '',
  Iterable<String> keywords = const [],
  Set<Filter> filters = const {},
}) {
  final queryTerms = query
      .split(RegExp(r'[\s,]+'))
      .map(_normalize)
      .where((term) => term.isNotEmpty);
  final keywordTerms = keywords
      .map(_normalize)
      .where((term) => term.isNotEmpty);
  final searchTerms = [...queryTerms, ...keywordTerms];

  return programs.where((program) {
    final matchesFilters = filters.every(program.filters.contains);
    if (!matchesFilters) {
      return false;
    }

    if (searchTerms.isEmpty) {
      return true;
    }

    final searchableText = _programSearchValues(
      program,
    ).map(_normalize).join(' ');
    return searchTerms.every(searchableText.contains);
  }).toList();
}

Iterable<String> _programSearchValues(ProgramModel program) sync* {
  yield program.title;
  yield program.oneLineDescription;
  yield program.detail;
  yield* program.keywords;
  yield program.startEndDates;
  yield program.locationName;
  for (final entry in program.location.entries) {
    yield entry.key;
    yield entry.value;
  }
  yield program.availableTime;
  yield program.cost;
  yield program.phoneNumber;
  yield program.link;
  yield '${program.images.length}개 이미지';

  for (final filter in program.filters) {
    yield filter.name;
    yield _filterLabel(filter);
  }

  yield program.isReservationNeeded
      ? 'true 사전예약 필요 예약필요'
      : 'false 사전예약 불필요 예약없이';
  yield program.isSpotlight ? 'true 지금 주목받는 spotlight' : 'false';
  yield program.isOverThisMonth ? 'true 이번달에 끝나는 over this month' : 'false';
}

String _filterLabel(Filter filter) {
  return switch (filter) {
    Filter.nowHot => '지금핫한 지금 핫한',
    Filter.free => '무료',
    Filter.thisWeek => '이번주 이번 주',
    Filter.noReservation => '예약없이 예약 없이',
    Filter.exhibition => '전시',
    Filter.show => '공연',
    Filter.experience => '체험',
    Filter.festival => '축제',
  };
}

String _normalize(String value) {
  return value
      .toLowerCase()
      .replaceAll('_', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
