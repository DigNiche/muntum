import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/api/api_client.dart';
import 'package:muntum/api/api_endpoints.dart';
import 'package:muntum/screens/map/map_program_repository.dart';
import 'package:muntum/services/program_service.dart';

void main() {
  test(
    'published posts, not the program curator field, set the badge',
    () async {
      final client = _CurationApiClient();
      final service = ProgramService(client: client);

      final page = await service.fetchPrograms();
      expect(page.content.map((program) => program.hasCurator), [false, true]);
      expect(
        client.detailCalls,
        1,
      ); // Missing list date was filled from detail.
      expect(client.curationCalls['manager-only'], 1);
      expect(client.curationCalls['published'], 1);

      final detail = await service.fetchProgram('manager-only');
      expect(detail.hasCurator, isFalse);
      expect(client.curationCalls['manager-only'], 1); // Reuses the lookup.
    },
  );

  test('map badges also use public curation presence', () async {
    final client = _CurationApiClient();
    final repository = MapProgramRepository(
      programService: ProgramService(client: client),
    );
    final bounds = NLatLngBounds(
      southWest: const NLatLng(37.5, 126.9),
      northEast: const NLatLng(37.6, 127.0),
    );

    final first = await repository.fetchInBounds(bounds: bounds);
    final second = await repository.fetchInBounds(bounds: bounds);

    expect(first.map((program) => program.hasCurator), [false, true]);
    expect(second.map((program) => program.hasCurator), [false, true]);
    expect(client.curationCalls['manager-only'], 1);
    expect(client.curationCalls['published'], 1);
  });
}

class _CurationApiClient extends ApiClient {
  final Map<String, int> curationCalls = {};
  int detailCalls = 0;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authorized = false,
  }) async {
    if (path == ApiEndpoints.programs || path == ApiEndpoints.programsMap) {
      return {
        'data': {
          'content': [
            {
              'id': 'manager-only',
              'title': '관리자 작성 프로그램',
              'curator': {'role': 'MANAGER', 'nickname': '문틈'},
              'latitude': 37.55,
              'longitude': 126.95,
            },
            {
              'id': 'published',
              'title': '공개 큐레이션 글이 있는 프로그램',
              'startDate': '2026-09-01',
              'endDate': '2026-12-31',
              'latitude': 37.56,
              'longitude': 126.96,
            },
          ],
          'totalElements': 2,
          'last': true,
        },
      };
    }
    if (path == ApiEndpoints.program('manager-only')) {
      detailCalls++;
      return {
        'data': {
          'id': 'manager-only',
          'title': '관리자 작성 프로그램',
          'curator': {'role': 'MANAGER', 'nickname': '문틈'},
          'operatingPeriodMeta': '2026.01.01',
          'latitude': 37.55,
          'longitude': 126.95,
        },
      };
    }
    if (path.endsWith('/curations')) {
      expect(queryParameters, {'page': 0, 'size': 1});
      final id = path.split('/')[4];
      curationCalls.update(id, (count) => count + 1, ifAbsent: () => 1);
      return {
        'data': {
          'content': id == 'published'
              ? [
                  {'id': 'curation-id'},
                ]
              : [],
          'totalElements': id == 'published' ? 1 : 0,
        },
      };
    }
    throw StateError('Unexpected request: $path');
  }
}
