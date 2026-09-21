import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/api/api_client.dart';
import 'package:muntum/api/api_endpoints.dart';
import 'package:muntum/models/curator_application_model.dart';
import 'package:muntum/models/user_profile_model.dart';
import 'package:muntum/services/curator_application_service.dart';
import 'package:muntum/utils/image_upload_format.dart';

void main() {
  group('curator application contract', () {
    test('submits the documented fields to the application endpoint', () async {
      final client = _RecordingApiClient();
      final service = CuratorApplicationService(client: client);

      await service.submit(
        programName: '프로그램',
        tagline: '한줄소개',
        curation: '소개글',
      );

      expect(client.lastMethod, 'POST');
      expect(client.lastPath, ApiEndpoints.curatorApplications);
      expect(client.lastAuthorized, isTrue);
      expect(client.lastBody, {
        'programName': '프로그램',
        'tagline': '한줄소개',
        'curation': '소개글',
      });
    });

    test('updates a pending application with PUT', () async {
      final client = _RecordingApiClient();
      final service = CuratorApplicationService(client: client);

      await service.update(
        id: 'application-id',
        programName: '수정 프로그램',
        tagline: '수정 소개',
        curation: '수정 내용',
      );

      expect(client.lastMethod, 'PUT');
      expect(
        client.lastPath,
        ApiEndpoints.curatorApplication('application-id'),
      );
      expect(client.lastAuthorized, isTrue);
    });

    test('loads the manager queue with the selected status', () async {
      final client = _RecordingApiClient();
      final service = CuratorApplicationService(client: client);

      final page = await service.fetchForManager(
        status: CuratorApplicationStatus.pending,
        page: 2,
        size: 30,
      );

      expect(client.lastMethod, 'GET');
      expect(client.lastPath, ApiEndpoints.managerCuratorApplications);
      expect(client.lastQuery, {'status': 'PENDING', 'page': 2, 'size': 30});
      expect(client.lastAuthorized, isTrue);
      expect(page.content, hasLength(1));
    });

    test('approves without sending a rejection reason', () async {
      final client = _RecordingApiClient();
      final service = CuratorApplicationService(client: client);

      await service.review(
        id: 'application-id',
        status: CuratorApplicationStatus.approved,
      );

      expect(client.lastMethod, 'PATCH');
      expect(client.lastBody, {'status': 'APPROVED'});
    });

    test('rejects with the selected documented reason', () async {
      final client = _RecordingApiClient();
      final service = CuratorApplicationService(client: client);

      await service.review(
        id: 'application-id',
        status: CuratorApplicationStatus.rejected,
        rejectReason: 'INSUFFICIENT_INFO',
      );

      expect(client.lastMethod, 'PATCH');
      expect(client.lastBody, {
        'status': 'REJECTED',
        'rejectReason': 'INSUFFICIENT_INFO',
      });
    });

    test('parses applicant and nested portfolio responses', () {
      final nested = CuratorApplicationModel.fromJson({
        'id': 'nested-id',
        'applicant': {
          'userId': 'user-id',
          'email': 'user@example.com',
          'nickname': '문화발굴단',
          'profileImageUrl': null,
          'role': 'AUDIENCE',
          'status': 'ACTIVE',
          'joinedAt': '2026-08-01',
        },
        'portfolio': {
          'programName': '중첩 프로그램',
          'tagline': '중첩 한줄소개',
          'curation': '중첩 소개글',
        },
        'statusInfo': {'status': 'PENDING'},
      });
      final flat = CuratorApplicationModel.fromJson({
        'id': 'flat-id',
        'programName': '평면 프로그램',
        'tagline': '평면 한줄소개',
        'curation': '평면 소개글',
        'statusInfo': {
          'status': 'REJECTED',
          'rejectReasonMessage': '보완이 필요합니다.',
        },
      });

      expect(nested.programName, '중첩 프로그램');
      expect(nested.status, CuratorApplicationStatus.pending);
      expect(nested.applicant?.userId, 'user-id');
      expect(nested.applicant?.profileImageUrl, isNull);
      expect(nested.applicant?.joinedAt, DateTime(2026, 8, 1));
      expect(flat.programName, '평면 프로그램');
      expect(flat.status, CuratorApplicationStatus.rejected);
      expect(flat.rejectionReason, '보완이 필요합니다.');
    });
  });

  test('null profile image URL remains null for the default avatar', () {
    final profile = UserProfileModel.fromJson({
      'userId': 'user-id',
      'email': 'user@example.com',
      'nickname': '문화발굴단',
      'role': 'AUDIENCE',
      'profileImageUrl': null,
    });

    expect(profile.profileImageUrl, isNull);
  });

  test('HEIC is converted to a temporary JPEG before upload', () async {
    expect(isSupportedUploadImagePath('/tmp/photo.heic'), isFalse);
    expect(isSupportedUploadImagePath('/tmp/photo.HEIF'), isFalse);
    expect(isConvertibleUploadImagePath('/tmp/photo.heic'), isTrue);
    expect(isConvertibleUploadImagePath('/tmp/photo.HEIF'), isTrue);
    expect(isConvertibleUploadImagePath('/tmp/photo.gif'), isFalse);
    expect(isSupportedUploadImagePath('/tmp/photo.jpg'), isTrue);
    expect(isSupportedUploadImagePath('/tmp/photo.jpeg'), isTrue);
    expect(isSupportedUploadImagePath('/tmp/photo.png'), isTrue);
    expect(isSupportedUploadImagePath('/tmp/photo.webp'), isTrue);

    final prepared = await prepareImageForUpload(
      '/tmp/photo.heic',
      jpegConverter: (source, target, quality) async {
        expect(source, '/tmp/photo.heic');
        expect(target, endsWith('.jpg'));
        expect(quality, 88);
        return target;
      },
    );
    expect(prepared.path, endsWith('.jpg'));
    expect(prepared.isTemporary, isTrue);
  });
}

class _RecordingApiClient extends ApiClient {
  String? lastMethod;
  String? lastPath;
  Map<String, dynamic>? lastBody;
  Map<String, dynamic>? lastQuery;
  bool? lastAuthorized;

  Map<String, dynamic> get _applicationResponse => {
    'message': '성공',
    'data': {
      'id': 'application-id',
      'portfolio': {
        'programName': lastBody?['programName'] ?? '프로그램',
        'tagline': lastBody?['tagline'] ?? '한줄소개',
        'curation': lastBody?['curation'] ?? '소개글',
      },
      'statusInfo': {'status': 'PENDING'},
    },
  };

  Map<String, dynamic> get _managerPageResponse => {
    'message': '성공',
    'data': {
      'content': [
        {
          'id': 'application-id',
          'applicant': {
            'userId': 'user-id',
            'email': 'user@example.com',
            'nickname': '문화발굴단',
            'profileImageUrl': null,
            'role': 'AUDIENCE',
            'status': 'ACTIVE',
            'joinedAt': '2026-08-01',
          },
          'statusInfo': {'status': 'PENDING'},
          'createdAt': '2026-09-19',
        },
      ],
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

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authorized = false,
  }) async {
    lastMethod = 'GET';
    lastPath = path;
    lastQuery = queryParameters;
    lastAuthorized = authorized;
    return _managerPageResponse;
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    bool authorized = false,
  }) async {
    lastMethod = 'POST';
    lastPath = path;
    lastBody = body;
    lastAuthorized = authorized;
    return _applicationResponse;
  }

  @override
  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    bool authorized = false,
  }) async {
    lastMethod = 'PUT';
    lastPath = path;
    lastBody = body;
    lastAuthorized = authorized;
    return _applicationResponse;
  }

  @override
  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    bool authorized = false,
  }) async {
    lastMethod = 'PATCH';
    lastPath = path;
    lastBody = body;
    lastAuthorized = authorized;
    return _applicationResponse;
  }
}
