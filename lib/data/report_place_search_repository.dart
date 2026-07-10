import 'package:muntum/data/mock_report_data.dart';
import 'package:muntum/models/report_model.dart';

abstract class ReportPlaceSearchRepository {
  Future<List<ReportPlace>> search(String query);
}

class MockReportPlaceSearchRepository implements ReportPlaceSearchRepository {
  const MockReportPlaceSearchRepository();

  @override
  Future<List<ReportPlace>> search(String query) async {
    final normalizedQuery = _normalize(query);
    final tokens = _tokens(query);

    if (normalizedQuery.isEmpty) return const [];

    final scoredPlaces =
        mockReportPlaces
            .map((place) {
              final normalizedName = _normalize(place.name);
              final normalizedAddress = _normalize(place.address);
              final searchable = '$normalizedName $normalizedAddress';

              final isMatched =
                  searchable.contains(normalizedQuery) ||
                  tokens.every(searchable.contains);
              if (!isMatched) return null;

              var score = 0;
              if (normalizedName == normalizedQuery) score += 100;
              if (normalizedName.startsWith(normalizedQuery)) score += 60;
              if (normalizedName.contains(normalizedQuery)) score += 40;
              if (normalizedAddress.contains(normalizedQuery)) score += 25;
              score += tokens.where(searchable.contains).length * 5;

              return _ScoredReportPlace(place: place, score: score);
            })
            .whereType<_ScoredReportPlace>()
            .toList()
          ..sort((a, b) => b.score.compareTo(a.score));

    return scoredPlaces.map((scoredPlace) => scoredPlace.place).toList();
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[\s\-_.,()]'), '');
  }

  List<String> _tokens(String value) {
    return value
        .split(RegExp(r'\s+'))
        .map(_normalize)
        .where((token) => token.isNotEmpty)
        .toList();
  }
}

class _ScoredReportPlace {
  final ReportPlace place;
  final int score;

  const _ScoredReportPlace({required this.place, required this.score});
}
