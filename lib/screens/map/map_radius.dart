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
