import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/map/map_program_coordinates.dart';
import 'package:muntum/screens/map/map_radius.dart';

typedef ProgramKeyResolver = String Function(ProgramModel program);

class MapClusteringController {
  static const double _samePlaceThresholdMeters = 3;
  static const double _spiderfyMarkerSpacingPixels = 50;

  final Set<String> _spiderfiedProgramKeys = {};

  void clearSpiderfiedPrograms() {
    _spiderfiedProgramKeys.clear();
  }

  void spiderfyPrograms(
    Iterable<ProgramModel> programs, {
    required ProgramKeyResolver keyFor,
  }) {
    _spiderfiedProgramKeys
      ..clear()
      ..addAll(programs.map(keyFor));
  }

  List<ProgramCluster> clusterPrograms(
    List<ProgramModel> programs,
    double zoom, {
    required ProgramKeyResolver keyFor,
  }) {
    final thresholdMeters = thresholdMetersForZoom(zoom);
    final clusters = <ProgramCluster>[];
    final spiderfiedPrograms = <ProgramModel>[];

    for (final program in programs) {
      if (_spiderfiedProgramKeys.contains(keyFor(program))) {
        spiderfiedPrograms.add(program);
        continue;
      }
      ProgramCluster? targetCluster;

      for (final cluster in clusters) {
        final distance = _distanceInMeters(
          program.latitude!,
          program.longitude!,
          cluster.latitude,
          cluster.longitude,
        );
        if (distance <= thresholdMeters) {
          targetCluster = cluster;
          break;
        }
      }

      if (targetCluster == null) {
        clusters.add(ProgramCluster(programs: [program]));
      } else {
        targetCluster.programs.add(program);
      }
    }

    clusters.addAll(
      spiderfiedPrograms.map((program) => ProgramCluster(programs: [program])),
    );
    return clusters;
  }

  double thresholdMetersForZoom(double zoom) {
    if (zoom < 12) return 1000;
    if (zoom < 13.5) return 800;
    if (zoom < 15) return 120;
    if (zoom < 16) return 40;
    if (zoom < 17) return 12;
    return _samePlaceThresholdMeters;
  }

  bool shouldSpiderfy(List<ProgramModel> programs) {
    for (var firstIndex = 0; firstIndex < programs.length; firstIndex++) {
      for (
        var secondIndex = firstIndex + 1;
        secondIndex < programs.length;
        secondIndex++
      ) {
        if (_distanceInMeters(
              programs[firstIndex].latitude!,
              programs[firstIndex].longitude!,
              programs[secondIndex].latitude!,
              programs[secondIndex].longitude!,
            ) >
            _samePlaceThresholdMeters) {
          return false;
        }
      }
    }
    return programs.length > 1;
  }

  Map<String, NLatLng> spiderfiedMarkerPositions(
    List<ProgramCluster> clusters,
    double zoom, {
    required ProgramKeyResolver keyFor,
  }) {
    final programs =
        clusters
            .where(
              (cluster) =>
                  cluster.programs.length == 1 &&
                  _spiderfiedProgramKeys.contains(
                    keyFor(cluster.programs.first),
                  ),
            )
            .map((cluster) => cluster.programs.first)
            .toList()
          ..sort((first, second) => keyFor(first).compareTo(keyFor(second)));
    if (programs.length < 2) {
      return const {};
    }

    final centerLatitude =
        programs.fold<double>(0, (sum, program) => sum + program.latitude!) /
        programs.length;
    final centerLongitude =
        programs.fold<double>(0, (sum, program) => sum + program.longitude!) /
        programs.length;
    final radiusPixels = math.max(
      27.0,
      _spiderfyMarkerSpacingPixels / (2 * math.sin(math.pi / programs.length)),
    );
    final metersPerPixel =
        156543.03392 *
        math.cos(_degreeToRadian(centerLatitude)) /
        math.pow(2, zoom);
    final radiusMeters = radiusPixels * metersPerPixel;
    final positions = <String, NLatLng>{};

    for (var index = 0; index < programs.length; index++) {
      final angle = -math.pi / 2 + (2 * math.pi * index / programs.length);
      final northMeters = math.cos(angle) * radiusMeters;
      final eastMeters = math.sin(angle) * radiusMeters;
      positions[keyFor(programs[index])] = NLatLng(
        centerLatitude + northMeters / 111320,
        centerLongitude +
            eastMeters / (111320 * math.cos(_degreeToRadian(centerLatitude))),
      );
    }
    return positions;
  }

  NCameraUpdate cameraUpdateForCluster(
    List<ProgramModel> programs,
    double currentZoom, {
    required bool spiderfyCluster,
  }) {
    final points = programs
        .map((program) => NLatLng(program.latitude!, program.longitude!))
        .toList();
    if (spiderfyCluster) {
      final center = NLatLng(
        points.fold<double>(0, (sum, point) => sum + point.latitude) /
            points.length,
        points.fold<double>(0, (sum, point) => sum + point.longitude) /
            points.length,
      );
      return NCameraUpdate.scrollAndZoomTo(
        target: center,
        zoom: math.max(currentZoom, 18.05),
      );
    }

    final latitudeSpan =
        points.map((point) => point.latitude).reduce(math.max) -
        points.map((point) => point.latitude).reduce(math.min);
    final longitudeSpan =
        points.map((point) => point.longitude).reduce(math.max) -
        points.map((point) => point.longitude).reduce(math.min);
    if (latitudeSpan > 0.000001 || longitudeSpan > 0.000001) {
      return NCameraUpdate.fitBounds(
        NLatLngBounds.from(points),
        padding: EdgeInsets.all(48.r),
      );
    }

    return NCameraUpdate.scrollAndZoomTo(
      target: points.first,
      zoom: math.min(currentZoom + 2, 18.05),
    );
  }

  double _distanceInMeters(
    double firstLatitude,
    double firstLongitude,
    double secondLatitude,
    double secondLongitude,
  ) {
    return distanceBetweenMeters(
      centerLatitude: firstLatitude,
      centerLongitude: firstLongitude,
      targetLatitude: secondLatitude,
      targetLongitude: secondLongitude,
    );
  }

  double _degreeToRadian(double degree) => degree * math.pi / 180;
}

class ProgramCluster {
  final List<ProgramModel> programs;

  ProgramCluster({required this.programs});

  double get latitude {
    final total = programs.fold<double>(
      0,
      (sum, program) => sum + (program.latitude ?? 0),
    );
    return total / programs.length;
  }

  double get longitude {
    final total = programs.fold<double>(
      0,
      (sum, program) => sum + (program.longitude ?? 0),
    );
    return total / programs.length;
  }
}
