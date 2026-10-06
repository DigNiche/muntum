import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/api/api_client.dart';
import 'package:muntum/api/api_endpoints.dart';
import 'package:muntum/models/curation_model.dart';
import 'package:muntum/services/curation_service.dart';

void main() {
  test('loads public curations for a program without authorization', () async {
    final client = _RecordingApiClient();
    final service = CurationService(client: client);
    final page = await service.fetchProgramCurations('program-id', size: 5);
    expect(client.lastPath, ApiEndpoints.programCurations('program-id'));
    expect(client.lastQuery, {'page': 0, 'size': 5});
    expect(client.lastAuthorized, isFalse);
    expect(page.content.single.curatorName, '문틈 큐레이터');

    final detail = await service.fetchProgramCurationDetail(
      'program-id',
      'curation-id',
    );
    expect(
      client.lastPath,
      ApiEndpoints.programCuration('program-id', 'curation-id'),
    );
    expect(detail.content, '본문');
    expect(page.content.single.createdAt, isNull);
    expect(detail.formattedCreatedAt, '26.10.05');
  });

  test('loads my curator profile from the curator profile endpoint', () async {
    final client = _RecordingApiClient();
    final profile = await CurationService(client: client).fetchMyProfile();

    expect(client.lastPath, ApiEndpoints.myCuratorProfile);
    expect(client.lastAuthorized, isTrue);
    expect(profile.nickname, '이초홍');
    expect(profile.profileImageUrl, isNull);
    expect(profile.totalCount, 4);
  });

  test('loads my curation list using status and pagination query', () async {
    final client = _RecordingApiClient();
    final page = await CurationService(
      client: client,
    ).fetchMine(status: CurationStatus.pending, page: 2, size: 30);

    expect(client.lastPath, ApiEndpoints.myCurations);
    expect(client.lastQuery, {'status': 'PENDING', 'page': 2, 'size': 30});
    expect(page.content.single.tagline, '한줄소개');
  });

  test(
    'submits curation JSON and images with exact multipart field names',
    () async {
      final client = _RecordingApiClient();
      await CurationService(client: client).submit(
        programTitle: '마틴 파',
        place: '국립현대미술관',
        tagline: '한줄\n\n  소개',
        content: '소개글\n둘째 문단',
        imagePaths: const ['/tmp/one.jpg', '/tmp/two.webp'],
      );

      expect(client.lastPath, ApiEndpoints.curations);
      expect(client.lastJsonFieldName, 'curation');
      expect(client.lastFileFieldName, 'images');
      expect(client.lastFiles, ['/tmp/one.jpg', '/tmp/two.webp']);
      expect(client.lastJsonPart, {
        'submittedProgramTitle': '마틴 파',
        'submittedPlace': '국립현대미술관',
        'tagline': '한줄 소개',
        'content': '소개글\n둘째 문단',
      });
      expect(client.lastAuthorized, isTrue);
    },
  );

  test(
    'updates, resubmits, and deletes through documented endpoints',
    () async {
      final client = _RecordingApiClient();
      final service = CurationService(client: client);

      await service.update(
        id: 'curation-id',
        programTitle: '수정 프로그램',
        place: '수정 장소',
        tagline: '수정\r\n한줄소개',
        content: '수정 본문',
      );
      expect(client.lastMethod, 'PUT_MULTIPART');
      expect(client.lastPath, ApiEndpoints.curation('curation-id'));
      expect(client.lastFiles, isEmpty);
      expect(client.lastJsonPart?['tagline'], '수정 한줄소개');

      await service.resubmit('curation-id');
      expect(client.lastMethod, 'PATCH');
      expect(client.lastPath, ApiEndpoints.resubmitCuration('curation-id'));

      await service.delete('curation-id');
      expect(client.lastMethod, 'DELETE');
      expect(client.lastPath, ApiEndpoints.curation('curation-id'));
    },
  );
}

class _RecordingApiClient extends ApiClient {
  String? lastMethod;
  String? lastPath;
  Map<String, dynamic>? lastQuery;
  Map<String, dynamic>? lastJsonPart;
  String? lastJsonFieldName;
  String? lastFileFieldName;
  List<String>? lastFiles;
  bool? lastAuthorized;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authorized = false,
  }) async {
    lastMethod = 'POST_MULTIPART';
    lastPath = path;
    lastQuery = queryParameters;
    lastAuthorized = authorized;
    if (path == ApiEndpoints.myCuratorProfile) {
      return {
        'message': '성공',
        'data': {
          'curatorId': 'curator-id',
          'nickname': '이초홍',
          'profileImageUrl': null,
          'approvedCount': 2,
          'pendingCount': 1,
          'changesRequestedCount': 1,
        },
      };
    }
    if (path == ApiEndpoints.programCuration('program-id', 'curation-id')) {
      return {
        'message': '성공',
        'data': {
          'id': 'curation-id',
          'programId': 'program-id',
          'curator': {'nickname': '문틈 큐레이터'},
          'tagline': '한줄소개',
          'content': '본문',
          'createdAt': '2026-10-05T14:15:49.334852',
          'images': [],
        },
      };
    }
    if (path == ApiEndpoints.programCurations('program-id')) {
      return {
        'message': '성공',
        'data': {
          'content': [
            {
              'id': 'curation-id',
              'curator': {'nickname': '문틈 큐레이터'},
              'tagline': '한줄소개',
              'thumbnailUrl': null,
            },
          ],
          'page': 0,
          'size': 5,
          'totalElements': 1,
          'totalPages': 1,
          'first': true,
          'last': true,
        },
      };
    }
    return {
      'message': '성공',
      'data': {
        'content': [_curationJson()],
        'page': 2,
        'size': 30,
        'totalElements': 1,
        'totalPages': 1,
        'first': false,
        'last': true,
        'hasPrevious': true,
        'hasNext': false,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, dynamic> jsonPart,
    String jsonFieldName = 'program',
    List<String> filePaths = const [],
    String fileFieldName = 'images',
    bool authorized = false,
  }) async {
    lastPath = path;
    lastJsonPart = jsonPart;
    lastJsonFieldName = jsonFieldName;
    lastFileFieldName = fileFieldName;
    lastFiles = filePaths;
    lastAuthorized = authorized;
    return {'message': '성공', 'data': _curationJson()};
  }

  @override
  Future<Map<String, dynamic>> putMultipart(
    String path, {
    required Map<String, dynamic> jsonPart,
    String jsonFieldName = 'program',
    List<String> filePaths = const [],
    String fileFieldName = 'images',
    bool authorized = false,
  }) async {
    lastMethod = 'PUT_MULTIPART';
    lastPath = path;
    lastJsonPart = jsonPart;
    lastJsonFieldName = jsonFieldName;
    lastFileFieldName = fileFieldName;
    lastFiles = filePaths;
    lastAuthorized = authorized;
    return {'message': '성공', 'data': _curationJson()};
  }

  @override
  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    bool authorized = false,
  }) async {
    lastMethod = 'PATCH';
    lastPath = path;
    lastAuthorized = authorized;
    return {'message': '성공', 'data': _curationJson()};
  }

  @override
  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authorized = false,
  }) async {
    lastMethod = 'DELETE';
    lastPath = path;
    lastAuthorized = authorized;
    return {'message': '성공'};
  }
}

Map<String, dynamic> _curationJson() => {
  'id': 'curation-id',
  'programId': null,
  'submittedProgramTitle': '마틴 파',
  'submittedPlace': '국립현대미술관',
  'tagline': '한줄소개',
  'content': '소개글',
  'images': const [],
  'status': 'PENDING',
  'publicationStatus': 'UNPUBLISHED',
  'createdAt': '2026-09-28T12:00:00',
  'updatedAt': '2026-09-28T12:00:00',
};
