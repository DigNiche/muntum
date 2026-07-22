import 'dart:math' as math;

import 'package:flutter_naver_map/flutter_naver_map.dart';

NLatLngBounds boundsAround(NLatLng center, double radiusMeters) {
  final latitudeDelta = radiusMeters / 111320;
  final longitudeDelta =
      radiusMeters / (111320 * math.cos(center.latitude * math.pi / 180).abs());

  return NLatLngBounds(
    southWest: NLatLng(
      center.latitude - latitudeDelta,
      center.longitude - longitudeDelta,
    ),
    northEast: NLatLng(
      center.latitude + latitudeDelta,
      center.longitude + longitudeDelta,
    ),
  );
}
