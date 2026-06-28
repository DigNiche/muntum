import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/data/mock_program_data.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/map/map_radius.dart';
import 'package:muntum/utils/program_query.dart';

void main() {
  group('map search radius', () {
    const centerLatitude = 37.3422;
    const centerLongitude = 127.9202;

    test('includes a program inside 5km', () {
      expect(
        isWithinRadius(
          centerLatitude: centerLatitude,
          centerLongitude: centerLongitude,
          targetLatitude: 37.3494,
          targetLongitude: 127.9490,
          radiusMeters: 5000,
        ),
        isTrue,
      );
    });

    test('excludes a program outside 5km', () {
      expect(
        isWithinRadius(
          centerLatitude: centerLatitude,
          centerLongitude: centerLongitude,
          targetLatitude: 37.3435,
          targetLongitude: 127.9845,
          radiusMeters: 5000,
        ),
        isFalse,
      );
    });
  });

  group('mock program data', () {
    test('provides complete card data', () {
      expect(mockPrograms, isNotEmpty);

      for (final program in mockPrograms) {
        expect(program.title, isNotEmpty);
        expect(program.locationName, isNotEmpty);
        expect(program.startEndDates, isNotEmpty);
        expect(program.images, isNotEmpty);
        expect(program.keywords, isNotEmpty);
      }
    });

    test('provides valid map coordinates', () {
      for (final program in mockPrograms) {
        expect(double.tryParse(program.location['latitude'] ?? ''), isNotNull);
        expect(double.tryParse(program.location['longitude'] ?? ''), isNotNull);
      }
    });
  });

  group('program query', () {
    test('searches address and detail fields', () {
      expect(
        queryPrograms(mockPrograms, query: '무실로 235').single.title,
        '원주 문화공간 체험',
      );
      expect(
        queryPrograms(mockPrograms, query: '작가의 표현법').single.title,
        '무실동 전시 클래스',
      );
    });

    test('requires every selected keyword', () {
      final result = queryPrograms(
        mockPrograms,
        keywords: ['내 손으로 만드는', '여운이 남는'],
      );

      expect(result.map((program) => program.title), ['무실동 전시 클래스']);
    });

    test('requires every selected filter', () {
      final result = queryPrograms(
        mockPrograms,
        filters: {Filter.free, Filter.thisWeek},
      );

      expect(result.map((program) => program.title), ['원주 문화공간 체험']);
    });

    test('searches reservation, phone, and link parameters', () {
      expect(
        queryPrograms(mockPrograms, query: '예약없이 033-123-1004').single.title,
        '원주 중앙시장 투어',
      );
      expect(
        queryPrograms(mockPrograms, query: 'programs/8').single.title,
        '뮤지엄 나이트',
      );
    });
  });
}
