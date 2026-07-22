import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/screens/map/components/current_location_pin_icon.dart';

class MapLocationOverlayController {
  static const int _pulseDurationMs = 1800;

  Future<NOverlayImage>? _iconFuture;
  Timer? _pulseTimer;

  Future<void> update({
    required BuildContext context,
    required NaverMapController mapController,
    required NLatLng location,
    required bool isActive,
  }) async {
    final overlay = mapController.getLocationOverlay();
    overlay.setIsVisible(true);
    overlay.setPosition(location);
    overlay.setCircleColor(const Color(0xFF2F80ED).withValues(alpha: 0.2));
    overlay.setCircleOutlineColor(Colors.transparent);
    overlay.setCircleOutlineWidth(0);
    overlay.setCircleRadius(24.r);
    overlay.setSubIcon(null);
    overlay.setIconSize(Size(20.r, 20.r));
    overlay.setIcon(await _getIcon(context));
    if (isActive) {
      startPulse(mapController);
    }
  }

  Future<NOverlayImage> _getIcon(BuildContext context) {
    return _iconFuture ??= NOverlayImage.fromWidget(
      context: context,
      size: Size(20.r, 20.r),
      widget: const CurrentLocationPinIcon(),
    );
  }

  void startPulse(NaverMapController? mapController) {
    if (mapController == null || _pulseTimer != null) {
      return;
    }

    final startedAt = DateTime.now();
    _pulseTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
      final progress = (elapsedMs % _pulseDurationMs) / _pulseDurationMs;
      final wave = (math.sin(progress * math.pi * 2 - math.pi / 2) + 1) / 2;
      final alpha = 0.12 + (wave * 0.18);
      mapController.getLocationOverlay().setCircleColor(
        const Color(0xFF2F80ED).withValues(alpha: alpha),
      );
    });
  }

  void stopPulse() {
    _pulseTimer?.cancel();
    _pulseTimer = null;
  }

  void dispose() => stopPulse();
}
