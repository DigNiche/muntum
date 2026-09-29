import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/map/map_program_coordinates.dart';
import 'package:muntum/screens/map/map_radius.dart';
import 'package:muntum/services/program_service.dart';

class MapProgramRepository {
  MapProgramRepository({ProgramService? programService})
    : _programService = programService ?? ProgramService();

  final ProgramService _programService;

  Future<List<ProgramModel>> fetchNearby({
    required NLatLng center,
    required double radiusMeters,
  }) async {
    final programs = <ProgramModel>[];
    var page = 0;
    var hasNext = true;

    while (hasNext) {
      final response = await _programService.fetchNearbyPrograms(
        latitude: center.latitude,
        longitude: center.longitude,
        radiusKm: radiusMeters / 1000,
        page: page,
        size: 20,
      );
      programs.addAll(
        response.content.where((program) => program.hasMapCoordinates),
      );
      hasNext = response.hasMore;
      page = response.page + 1;
    }

    programs.sort(
      (first, second) =>
          _distanceFrom(center, first).compareTo(_distanceFrom(center, second)),
    );
    return programs;
  }

  Future<List<ProgramModel>> fetchInBounds({
    required NLatLngBounds bounds,
    Filter? filter,
  }) async {
    final response = await _programService.fetchMapPrograms(
      southWestLatitude: bounds.southWest.latitude,
      southWestLongitude: bounds.southWest.longitude,
      northEastLatitude: bounds.northEast.latitude,
      northEastLongitude: bounds.northEast.longitude,
      chip: filter?.mapApiChip,
    );
    final programs = response.content
        .where((program) => program.hasMapCoordinates)
        .toList();

    if (filter != Filter.nowHot) {
      programs.sort(
        (first, second) => _distanceFrom(
          bounds.center,
          first,
        ).compareTo(_distanceFrom(bounds.center, second)),
      );
    }
    return programs;
  }

  double _distanceFrom(NLatLng center, ProgramModel program) {
    return distanceBetweenMeters(
      centerLatitude: center.latitude,
      centerLongitude: center.longitude,
      targetLatitude: program.latitude!,
      targetLongitude: program.longitude!,
    );
  }
}
