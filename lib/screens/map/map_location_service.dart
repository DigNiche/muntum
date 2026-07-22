import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:muntum/services/user_service.dart';

class MapLocationService {
  MapLocationService({UserService? userService})
    : _userService = userService ?? UserService();

  final UserService _userService;

  Future<Position> determineCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      await _syncTermsConsent(false);
      throw const PermissionDeniedException('Location permission denied');
    }

    await _syncTermsConsent(true);
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } on TimeoutException {
      final lastKnownPosition = await Geolocator.getLastKnownPosition();
      if (lastKnownPosition != null) {
        return lastKnownPosition;
      }
      rethrow;
    }
  }

  Future<void> _syncTermsConsent(bool agreed) async {
    try {
      await _userService.updateLocationTermsConsent(agreed);
    } catch (_) {
      // Auth or network availability must not block the map location flow.
    }
  }
}
