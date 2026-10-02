import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/api/api_client.dart';
import 'package:muntum/api/api_endpoints.dart';
import 'package:muntum/api/api_exception.dart';
import 'package:muntum/models/curation_model.dart';
import 'package:muntum/services/admin_curation_service.dart';

void main() {
  test('manager list filters statuses and parses curator', () async {
    final client = _RecordingClient();
    final page = await AdminCurationService(
      client: client,
    ).fetchList(status: CurationStatus.pending, page: 1);
    expect(client.path, ApiEndpoints.managerCurations);
    expect(client.query, {'status': 'PENDING', 'page': 1, 'size': 20});
    expect(client.authorized, isTrue);
    expect(page.content.single.curator.nickname, '큐레이터명');
  });

  test('manager detail uses the manager endpoint', () async {
    final client = _RecordingClient();
    final detail = await AdminCurationService(client: client).fetchDetail('id');
    expect(client.path, ApiEndpoints.managerCuration('id'));
    expect(detail.curation.content, '소개글');
  });

  test('approval and change request use documented bodies', () async {
    final client = _RecordingClient();
    final service = AdminCurationService(client: client);

    await service.approveExisting(curationId: 'id', programId: 'program-id');
    expect(client.method, 'PATCH');
    expect(client.path, ApiEndpoints.approveExistingCuration('id'));
    expect(client.body, {'programId': 'program-id'});

    await service.approveNew(
      curationId: 'id',
      program: {'title': '새 프로그램', 'description': '소개글'},
      imagePaths: ['/tmp/image.jpg'],
    );
    expect(client.method, 'POST_MULTIPART');
    expect(client.path, ApiEndpoints.approveNewCuration('id'));
    expect(client.jsonFieldName, 'program');
    expect(client.fileFieldName, 'images');
    expect(client.files, ['/tmp/image.jpg']);

    await service.requestChanges(
      curationId: 'id',
      reason: '내용을 확인해주세요.',
      publicationStatus: 'UNPUBLISHED',
    );
    expect(client.lastPatchPath, ApiEndpoints.requestCurationChanges('id'));
    expect(client.path, ApiEndpoints.requestCurationChanges('id'));
    expect(client.body, {
      'changeRequestReason': '내용을 확인해주세요.',
      'publicationStatus': 'UNPUBLISHED',
    });
  });

  test(
    'change request is not reported successful without persisted status',
    () async {
      final client = _RecordingClient()
        ..applyChangeRequest = false
        ..patchDecodeError = true;
      await expectLater(
        AdminCurationService(client: client).requestChanges(
          curationId: 'id',
          reason: '내용을 확인해주세요.',
          publicationStatus: 'PUBLISHED',
        ),
        throwsA(isA<ApiException>()),
      );
    },
  );

  test('committed change survives an unreadable PATCH response', () async {
    final client = _RecordingClient()..patchDecodeError = true;
    await AdminCurationService(client: client).requestChanges(
      curationId: 'id',
      reason: '내용을 확인해주세요.',
      publicationStatus: 'PUBLISHED',
    );
    expect(client.changeRequestApplied, isTrue);
    expect(client.path, ApiEndpoints.managerCuration('id'));
  });

  test(
    'committed change does not show an HTTP error as a failed request',
    () async {
      final client = _RecordingClient()..patchServerError = true;
      await AdminCurationService(client: client).requestChanges(
        curationId: 'id',
        reason: '내용을 확인해주세요.',
        publicationStatus: 'UNPUBLISHED',
      );
      expect(client.changeRequestApplied, isTrue);
    },
  );
}

class _RecordingClient extends ApiClient {
  String? method;
  String? path;
  Map<String, dynamic>? query;
  Map<String, dynamic>? body;
  bool? authorized;
  String? jsonFieldName;
  String? fileFieldName;
  List<String>? files;
  String? lastPatchPath;
  bool applyChangeRequest = true;
  bool patchDecodeError = false;
  bool patchServerError = false;
  bool changeRequestApplied = false;

  Map<String, dynamic> get currentDetail {
    final detail = _detail();
    if (changeRequestApplied) {
      detail['status'] = 'CHANGES_REQUESTED';
      detail['changeRequestReason'] = body?['changeRequestReason'];
      detail['publicationStatus'] = body?['publicationStatus'];
    }
    return detail;
  }

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authorized = false,
  }) async {
    method = 'GET';
    this.path = path;
    query = queryParameters;
    this.authorized = authorized;
    return {
      'data': path == ApiEndpoints.managerCurations
          ? {
              'content': [_detail()],
              'page': 1,
              'size': 20,
              'totalElements': 1,
              'totalPages': 1,
              'first': false,
              'last': true,
            }
          : currentDetail,
    };
  }

  @override
  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    bool authorized = false,
  }) async {
    method = 'PATCH';
    this.path = path;
    lastPatchPath = path;
    this.body = body;
    this.authorized = authorized;
    if (path == ApiEndpoints.requestCurationChanges('id')) {
      changeRequestApplied = applyChangeRequest;
      if (patchServerError) {
        throw const ApiException(statusCode: 500, message: '처리 중 오류가 발생했습니다.');
      }
      if (patchDecodeError) throw const FormatException('invalid response');
      return const {};
    }
    return {'data': _detail()};
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
    method = 'POST_MULTIPART';
    this.path = path;
    body = jsonPart;
    this.jsonFieldName = jsonFieldName;
    this.fileFieldName = fileFieldName;
    files = filePaths;
    this.authorized = authorized;
    return {'data': _detail()};
  }
}

Map<String, dynamic> _detail() => {
  'id': 'id',
  'curator': {'curatorId': 'curator-id', 'nickname': '큐레이터명'},
  'submittedProgramTitle': '프로그램명',
  'submittedPlace': '장소',
  'tagline': '한줄소개',
  'content': '소개글',
  'images': const [],
  'status': 'PENDING',
  'publicationStatus': 'UNPUBLISHED',
  'createdAt': '2026-09-28T12:00:00',
};
