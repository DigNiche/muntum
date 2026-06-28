import 'package:geolocator/geolocator.dart';

double distanceBetweenMeters({
  required double centerLatitude,
  required double centerLongitude,
  required double targetLatitude,
  required double targetLongitude,
}) {
  return Geolocator.distanceBetween(
    centerLatitude,
    centerLongitude,
    targetLatitude,
    targetLongitude,
  );
}

bool isWithinRadius({
  required double centerLatitude,
  required double centerLongitude,
  required double targetLatitude,
  required double targetLongitude,
  required double radiusMeters,
}) {
  return distanceBetweenMeters(
        centerLatitude: centerLatitude,
        centerLongitude: centerLongitude,
        targetLatitude: targetLatitude,
        targetLongitude: targetLongitude,
      ) <=
      radiusMeters;
}
