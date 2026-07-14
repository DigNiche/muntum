import 'package:muntum/models/program_filter.dart';

enum ProgramType {
  exhibition(apiValue: 'EXHIBITION', label: '전시', filter: Filter.exhibition),
  performance(apiValue: 'PERFORMANCE', label: '공연', filter: Filter.show),
  experience(
    apiValue: 'CLASS_EXPERIENCE',
    label: '체험',
    filter: Filter.experience,
  ),
  festival(apiValue: 'FAIR', label: '축제', filter: Filter.festival);

  const ProgramType({
    required this.apiValue,
    required this.label,
    required this.filter,
  });

  final String apiValue;
  final String label;
  final Filter filter;

  static ProgramType? fromApiValue(String? value) {
    for (final type in values) {
      if (type.apiValue == value) return type;
    }
    return null;
  }

  static ProgramType? fromLabel(String? value) {
    for (final type in values) {
      if (type.label == value) return type;
    }
    return null;
  }

  static ProgramType? fromFilter(Filter filter) {
    for (final type in values) {
      if (type.filter == filter) return type;
    }
    return null;
  }
}
