import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/screens/map/map_radius.dart';

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
}
