import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/api/api_response.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/map/map_program_repository.dart';
import 'package:muntum/services/program_service.dart';

void main() {
  test(
    'map entries without curator use and cache the program detail flag',
    () async {
      final service = _FakeProgramService();
      final repository = MapProgramRepository(programService: service);
      final bounds = NLatLngBounds(
        southWest: const NLatLng(37.5, 126.9),
        northEast: const NLatLng(37.6, 127.0),
      );

      final first = await repository.fetchInBounds(bounds: bounds);
      final second = await repository.fetchInBounds(bounds: bounds);

      expect(first.single.hasCurator, isTrue);
      expect(second.single.hasCurator, isTrue);
      expect(service.detailCalls, 1);
    },
  );
}

class _FakeProgramService extends ProgramService {
  int detailCalls = 0;

  @override
  Future<PageResponse<ProgramModel>> fetchMapPrograms({
    required double southWestLatitude,
    required double southWestLongitude,
    required double northEastLatitude,
    required double northEastLongitude,
    String? chip,
  }) async => PageResponse.fromList([
    ProgramModel.fromJson({
      'id': 'program-id',
      'title': '큐레이션 프로그램',
      'latitude': 37.55,
      'longitude': 126.95,
    }),
  ]);

  @override
  Future<ProgramModel> fetchProgram(
    String id, {
    bool authorized = false,
  }) async {
    detailCalls++;
    return ProgramModel.fromJson({
      'id': id,
      'title': '큐레이션 프로그램',
      'curator': {'nickname': '문틈 큐레이터'},
    });
  }
}
