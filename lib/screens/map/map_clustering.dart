import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/map/map_program_coordinates.dart';
import 'package:muntum/screens/map/map_radius.dart';

typedef ProgramKeyResolver = String Function(ProgramModel program);

/// 지도 줌과 프로그램 간 거리를 기준으로 마커 클러스터를 관리한다.
class MapClusteringController {
  static const double _samePlaceThresholdMeters = 3;
  static const double _spiderfyMarkerSpacingPixels = 50;

  final List<Set<String>> _spiderfiedProgramKeyGroups = [];

  /// 펼쳐진 마커 그룹을 모두 초기화해 다시 클러스터링할 수 있게 한다.
  void clearSpiderfiedPrograms() {
    _spiderfiedProgramKeyGroups.clear();
  }

  /// 기존 펼침 상태를 지우고 전달받은 프로그램 그룹만 펼침 대상으로 등록한다.
  void spiderfyPrograms(
    Iterable<ProgramModel> programs, {
    required ProgramKeyResolver keyFor,
  }) {
    clearSpiderfiedPrograms();
    addSpiderfiedPrograms(programs, keyFor: keyFor);
  }

  /// 기존 펼침 상태를 유지하면서 새로운 프로그램 그룹을 추가한다.
  void addSpiderfiedPrograms(
    Iterable<ProgramModel> programs, {
    required ProgramKeyResolver keyFor,
  }) {
    final keys = programs.map(keyFor).toSet();
    if (keys.length < 2) return;
    _spiderfiedProgramKeyGroups.removeWhere(
      (group) => group.any(keys.contains),
    );
    _spiderfiedProgramKeyGroups.add(keys);
  }

  /// 현재 줌의 거리 기준으로 프로그램을 묶어 화면에 표시할 클러스터를 만든다.
  ///
  /// 펼침 대상으로 등록된 프로그램은 거리와 관계없이 개별 클러스터로 반환한다.
  List<ProgramCluster> clusterPrograms(
    List<ProgramModel> programs,
    double zoom, {
    required ProgramKeyResolver keyFor,
  }) {
    final thresholdMeters = thresholdMetersForZoom(zoom);
    final clusters = <ProgramCluster>[];
    final spiderfiedPrograms = <ProgramModel>[];

    for (final program in programs) {
      if (_isSpiderfied(keyFor(program))) {
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

  /// 줌이 커질수록 클러스터로 묶는 최대 거리를 줄여 개별 마커를 노출한다.
  double thresholdMetersForZoom(double zoom) {
    print(zoom);
    if (zoom < 12.0) return 450;
    if (zoom < 12.5) return 100;
    if (zoom < 13.5) return 30;
    if (zoom < 14.5) return 10;
    return _samePlaceThresholdMeters;
  }

  /// 충분히 확대되어 동일 장소의 프로그램까지 자동으로 펼쳐야 하는지 반환한다.
  bool shouldAutomaticallySpiderfy(double zoom) {
    return zoom >= 16.5;
  }

  /// 모든 프로그램이 같은 장소 범위 안에 있어 펼칠 수 있는 그룹인지 확인한다.
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

  /// 펼침 대상으로 등록된 프로그램들의 실제 지도 표시 좌표를 계산한다.
  Map<String, NLatLng> spiderfiedMarkerPositions(
    List<ProgramCluster> clusters,
    double zoom, {
    required ProgramKeyResolver keyFor,
  }) {
    final programsByKey = {
      for (final cluster in clusters)
        if (cluster.programs.length == 1)
          keyFor(cluster.programs.first): cluster.programs.first,
    };
    final positions = <String, NLatLng>{};
    for (final group in _spiderfiedProgramKeyGroups) {
      final programs =
          group
              .map((key) => programsByKey[key])
              .whereType<ProgramModel>()
              .toList()
            ..sort((first, second) => keyFor(first).compareTo(keyFor(second)));
      positions.addAll(
        _spiderfiedPositionsForGroup(programs, zoom, keyFor: keyFor),
      );
    }
    return positions;
  }

  /// 같은 장소의 마커가 겹치지 않도록 그룹 중심을 기준으로 원형 배치한다.
  Map<String, NLatLng> _spiderfiedPositionsForGroup(
    List<ProgramModel> programs,
    double zoom, {
    required ProgramKeyResolver keyFor,
  }) {
    if (programs.length < 2) return const {};
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

  /// 프로그램 키가 현재 펼쳐진 그룹 중 하나에 포함되어 있는지 확인한다.
  bool _isSpiderfied(String programKey) {
    return _spiderfiedProgramKeyGroups.any(
      (group) => group.contains(programKey),
    );
  }

  /// 클러스터 선택 시 모든 프로그램을 확인할 수 있는 카메라 이동을 생성한다.
  ///
  /// 같은 장소 그룹은 확대하고, 서로 다른 장소 그룹은 전체 좌표가 보이도록 맞춘다.
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

  /// 두 위경도 사이의 직선거리를 미터 단위로 계산한다.
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

  /// 삼각함수 계산에 사용할 수 있도록 각도를 라디안으로 변환한다.
  double _degreeToRadian(double degree) => degree * math.pi / 180;
}

/// 하나의 클러스터에 포함된 프로그램과 중심 좌표를 제공한다.
class ProgramCluster {
  final List<ProgramModel> programs;

  ProgramCluster({required this.programs});

  /// 포함된 프로그램들의 평균 위도다.
  double get latitude {
    final total = programs.fold<double>(
      0,
      (sum, program) => sum + (program.latitude ?? 0),
    );
    return total / programs.length;
  }

  /// 포함된 프로그램들의 평균 경도다.
  double get longitude {
    final total = programs.fold<double>(
      0,
      (sum, program) => sum + (program.longitude ?? 0),
    );
    return total / programs.length;
  }
}
