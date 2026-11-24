import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muntum/api/api_client.dart';
import 'package:muntum/api/api_endpoints.dart';
import 'package:muntum/api/api_exception.dart';
import 'package:muntum/api/token_store.dart';
import 'package:muntum/models/auth_models.dart';
import 'package:muntum/models/curation_model.dart';
import 'package:muntum/models/admin_curation_model.dart';
import 'package:muntum/models/report_model.dart';
import 'package:muntum/models/terms_model.dart';
import 'package:muntum/services/auth_service.dart';
import 'package:muntum/services/taste_service.dart';
import 'package:muntum/services/terms_service.dart';
import 'package:muntum/stores/auth_state.dart';
import 'support/terms_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await TokenStore.instance.clear();
  });

  test(
    'active terms are an unauthenticated array with server versions',
    () async {
      final client = _Client({
        'data': [
          {
            'type': 'TERMS_OF_SERVICE',
            'version': '1.0.1',
            'title': '서비스 이용약관',
            'content': '본문',
            'required': true,
          },
        ],
      });
      final documents = await TermsService(client: client).fetchSignupTerms();
      expect(documents.single.version, '1.0.1');
      expect(client.calls.single, {
        'method': 'GET',
        'path': ApiEndpoints.activeTerms,
        'authorized': false,
      });
    },
  );

  test('missing terms and malformed versions never invent consent', () async {
    await expectLater(
      TermsService(client: _Client({'data': []})).fetchSignupTerms(),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'T005')),
    );
    expect(
      () => TermDocument.fromJson({
        'type': 'TERMS_OF_SERVICE',
        'content': '본문',
        'required': true,
      }),
      throwsFormatException,
    );
    expect(() => SignupConsent([]).toJson(), throwsFormatException);
    expect(
      () => SignupConsent([
        const TermAgreement(
          type: 'TERMS_OF_SERVICE',
          agreed: true,
          version: '1.0.1',
        ),
        const TermAgreement(
          type: 'PRIVACY_POLICY',
          agreed: true,
          version: '1.0.1',
        ),
      ]).toJson(),
      throwsFormatException,
    );
  });

  test(
    'optional grants send current version, then fetch confirmed state',
    () async {
      final client = _Client(_termsState);
      await TermsService(client: client).updateOptional([
        const TermAgreement(
          type: 'MARKETING_EMAIL',
          agreed: true,
          version: '2.3',
        ),
      ]);
      expect(client.calls[0], {
        'method': 'PATCH',
        'path': ApiEndpoints.termsConsent,
        'authorized': true,
        'body': {
          'terms': [
            {'termType': 'MARKETING_EMAIL', 'agreed': true, 'version': '2.3'},
          ],
        },
      });
      expect(client.calls[1]['method'], 'GET');
      expect(client.calls[1]['authorized'], true);
    },
  );

  test('inactive optional consent can be revoked without a version', () async {
    final client = _Client(_termsState);
    await TermsService(client: client).updateOptional([
      const TermAgreement(type: 'LOCATION_TERMS', agreed: false),
    ]);
    expect((client.calls.first['body'] as Map)['terms'], [
      {'termType': 'LOCATION_TERMS', 'agreed': false},
    ]);
  });

  test(
    'optional API rejects empty, duplicate, notice, required and unversioned grants',
    () async {
      for (final changes in <List<TermAgreement>>[
        [],
        [const TermAgreement(type: 'PRIVACY_POLICY', agreed: false)],
        [const TermAgreement(type: 'TERMS_OF_SERVICE', agreed: false)],
        [const TermAgreement(type: 'MARKETING_EMAIL', agreed: true)],
        [
          const TermAgreement(type: 'MARKETING_EMAIL', agreed: false),
          const TermAgreement(type: 'MARKETING_EMAIL', agreed: false),
        ],
      ]) {
        final client = _Client(_termsState);
        await expectLater(
          TermsService(client: client).updateOptional(changes),
          throwsFormatException,
        );
        expect(client.calls, isEmpty);
      }
    },
  );

  test(
    'missing user consent record T001 remains an error, not false flags',
    () async {
      final client = _Client({})
        ..error = const ApiException(
          statusCode: 404,
          code: 'T001',
          message: '약관 동의 정보가 존재하지 않습니다',
        );
      await expectLater(
        TermsService(client: client).fetchMyConsents(),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'T001')),
      );
    },
  );

  test(
    'email signup sends explicit consent, not role or legacy version, and saves authentication',
    () async {
      final client = _Client({
        'data': {
          'userId': 'user-id',
          'email': 'user@example.com',
          'authentication': _session,
        },
      });
      final result = await AuthService(client: client).signup(
        email: 'user@example.com',
        password: 'Password!1',
        signupToken: 'signup-token',
        signupConsent: testSignupConsent(),
      );
      expect(client.calls.single['body'], {
        'email': 'user@example.com',
        'password': 'Password!1',
        'signupToken': 'signup-token',
        'signupConsent': testSignupConsent().toJson(),
      });
      expect(result.authentication!.userId, 'user-id');
      expect(TokenStore.instance.accessToken, 'access-token');
      expect(await TokenStore.instance.readRefreshToken(), 'refresh-token');
      expect(await TokenStore.instance.readAuthProvider(), 'EMAIL');
    },
  );

  test(
    'signup without authentication does not claim a login or repeat signup',
    () async {
      final client = _Client({
        'data': {'userId': 'user-id'},
      });
      await expectLater(
        AuthService(client: client).signup(
          email: 'user@example.com',
          password: 'Password!1',
          signupToken: 'signup-token',
          signupConsent: testSignupConsent(),
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            'SIGNUP_SESSION_MISSING',
          ),
        ),
      );
      expect(TokenStore.instance.accessToken, isNull);
      expect(client.calls, hasLength(1));
    },
  );

  test('Kakao preparation sends only provider and token', () async {
    final client = _Client({
      'data': {
        'status': 'SIGNUP_REQUIRED',
        'signupTicket': 'one-use-ticket',
        'expiresIn': 600,
      },
    });
    final result = await AuthService(client: client).prepareSocial(
      const SocialLoginRequest(
        provider: SocialAuthProvider.kakao,
        token: 'kakao-token',
      ),
    );
    expect(client.calls.single['path'], ApiEndpoints.socialPrepare);
    expect(client.calls.single['body'], {
      'provider': 'KAKAO',
      'token': 'kakao-token',
    });
    expect(client.calls.single['authorized'], false);
    expect(result.authentication, isNull);
    expect(result.expiresIn, 600);
    expect(TokenStore.instance.accessToken, isNull);
  });

  test(
    'existing Kakao member stores MUNTUM tokens with the Kakao provider',
    () async {
      final client = _Client({
        'data': {'status': 'LOGIN_COMPLETE', 'authentication': _session},
      });
      final result = await AuthService(client: client).prepareSocial(
        const SocialLoginRequest(
          provider: SocialAuthProvider.kakao,
          token: 'kakao-access-token',
        ),
      );
      expect(result.signupTicket, isNull);
      expect(client.calls, hasLength(1));
      expect(client.calls.single['path'], ApiEndpoints.socialPrepare);
      expect(TokenStore.instance.accessToken, 'access-token');
      expect(await TokenStore.instance.readAuthProvider(), 'KAKAO');
    },
  );

  test(
    'Kakao signup stores MUNTUM session without resending SDK tokens',
    () async {
      final client = _Client({'data': _session});
      await AuthService(client: client).signupSocial(
        signupTicket: 'kakao-signup-ticket',
        provider: SocialAuthProvider.kakao,
        signupConsent: testSignupConsent(),
      );
      expect(client.calls.single['path'], ApiEndpoints.socialSignup);
      expect(client.calls.single['body'], {
        'signupTicket': 'kakao-signup-ticket',
        'signupConsent': testSignupConsent().toJson(),
      });
      expect(TokenStore.instance.accessToken, 'access-token');
      expect(await TokenStore.instance.readAuthProvider(), 'KAKAO');
    },
  );

  test('existing social member stores JWT without requiring signup', () async {
    final client = _Client({
      'data': {'status': 'LOGIN_COMPLETE', 'authentication': _session},
    });
    final result = await AuthService(client: client).prepareSocial(
      const SocialLoginRequest(
        provider: SocialAuthProvider.apple,
        token: 'identity',
        authorizationCode: 'one-use-code',
        nonce: 'nonce',
      ),
    );
    expect(result.signupTicket, isNull);
    expect(TokenStore.instance.accessToken, 'access-token');
    expect(await TokenStore.instance.readAuthProvider(), 'APPLE');
  });

  test(
    'social signup sends ticket and consent without reusing Apple credentials',
    () async {
      final client = _Client({'data': _session});
      await AuthService(client: client).signupSocial(
        signupTicket: 'one-use-ticket',
        provider: SocialAuthProvider.apple,
        signupConsent: testSignupConsent(),
      );
      expect(client.calls.single['path'], ApiEndpoints.socialSignup);
      expect(client.calls.single['body'], {
        'signupTicket': 'one-use-ticket',
        'signupConsent': testSignupConsent().toJson(),
      });
      expect(await TokenStore.instance.readAuthProvider(), 'APPLE');
    },
  );

  test('unrecognized social response does not create an empty session', () {
    expect(
      () => SocialPrepareResult.fromJson({'status': 'OTHER'}),
      throwsFormatException,
    );
    expect(
      () => SocialPrepareResult.fromJson({
        'status': 'SIGNUP_REQUIRED',
        'signupTicket': '',
        'expiresIn': 600,
      }),
      throwsFormatException,
    );
  });

  test('refresh rotates tokens without Authorization', () async {
    await _save();
    final client = _Client({
      'data': {..._session, 'refreshToken': 'rotated'},
    });
    await AuthService(client: client).refresh();
    expect(client.calls.single, {
      'method': 'POST',
      'path': ApiEndpoints.refresh,
      'authorized': false,
      'body': {'refreshToken': 'refresh-token'},
    });
    expect(await TokenStore.instance.readRefreshToken(), 'rotated');
  });

  for (final code in ['A006', 'A007', 'A009', 'A010', 'A002']) {
    test('refresh $code clears the rejected local session', () async {
      await _save();
      final client = _Client({})
        ..error = ApiException(
          statusCode: code == 'A002' ? 404 : 401,
          code: code,
          message: '재로그인',
        );
      await expectLater(
        AuthService(client: client).refresh(),
        throwsA(isA<ApiException>()),
      );
      expect(await TokenStore.instance.readRefreshToken(), isNull);
      expect(AuthState.instance.isLoggedIn, false);
    });
  }

  test(
    'failed server logout is surfaced and a network failure preserves the session',
    () async {
      await _save();
      final client = _Client({})
        ..error = const ApiException(
          statusCode: 500,
          code: 'E001',
          message: '서버 오류',
        );
      await expectLater(
        AuthService(client: client).logout(),
        throwsA(isA<ApiException>()),
      );
      expect(await TokenStore.instance.readRefreshToken(), 'refresh-token');
      client.error = null;
      await AuthService(client: client).logout();
      expect(TokenStore.instance.accessToken, isNull);
      expect(await TokenStore.instance.readRefreshToken(), isNull);
    },
  );

  test(
    'taste keyword replacement deduplicates names and keeps order',
    () async {
      final client = _Client({
        'data': {'selectedKeywords': []},
      });
      await TasteService(client: client).saveMyKeywords(['A', 'B', 'A', 'C']);
      expect(client.calls.single['body'], {
        'selectKeywords': ['A', 'B', 'C'],
      });
    },
  );

  test('new reviewer fields preserve withdrawn display names and null IDs', () {
    final report = ReportModel.fromJson({
      'reviewerId': null,
      'reviewerNickname': '문틈',
      'reviewedById': 'stale',
      'reviewedByNickname': 'stale',
      'informerId': null,
      'informerNickname': '익명의 제보자',
    });
    expect(report.reviewerId, isNull);
    expect(report.reviewerNickname, '문틈');
    expect(report.informerId, isNull);
    expect(report.informerNickname, '익명의 제보자');
  });

  test(
    'withdrawn detail author clears a stale summary profile, unknown role stays null',
    () {
      final summary = PublicCurationModel.fromJson({
        'id': 'note',
        'curator': {
          'curatorId': 'old',
          'nickname': '이전',
          'role': 'CURATOR',
          'profileImageUrl': 'https://example.com/old.jpg',
        },
      });
      final detail = PublicCurationModel.fromJson({
        'id': 'note',
        'curator': {
          'curatorId': null,
          'nickname': '익명의 큐레이터',
          'role': 'CURATOR',
          'profileImageUrl': null,
        },
      });
      final merged = summary.mergeDetails(detail);
      expect(merged.curatorId, isNull);
      expect(merged.curatorImageUrl, isNull);
      expect(merged.curatorName, '익명의 큐레이터');
      expect(
        PublicCurationModel.fromJson({
          'curator': {'role': null},
        }).curatorRole,
        isNull,
      );
      expect(
        AdminCurationModel.fromJson({
          'curator': {'role': null},
        }).curator.role,
        isNull,
      );
    },
  );

  test(
    'refresh token migrates once from preferences and is only written securely',
    () async {
      SharedPreferences.setMockInitialValues({'refreshToken': 'legacy-token'});
      expect(await TokenStore.instance.readRefreshToken(), 'legacy-token');
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.containsKey('refreshToken'), false);
      expect(
        await const FlutterSecureStorage().read(key: 'refreshToken'),
        'legacy-token',
      );
      await _save();
      expect(preferences.containsKey('refreshToken'), false);
      expect(
        await const FlutterSecureStorage().read(key: 'refreshToken'),
        'refresh-token',
      );
    },
  );
}

const _session = {
  'accessToken': 'access-token',
  'refreshToken': 'refresh-token',
  'userId': 'user-id',
  'email': 'user@example.com',
  'accessExpiresIn': 3600000,
  'refreshExpiresIn': 1209600000,
};
const _termsState = {
  'data': {
    'optionalConsents': {
      'MARKETING_EMAIL': true,
      'MARKETING_PUSH': false,
      'LOCATION_TERMS': false,
      'THIRD_PARTY_OFFER': false,
    },
    'agreementVersions': {'TERMS_OF_SERVICE': '1.0.1'},
    'updatedAt': null,
  },
};

Future<void> _save() => TokenStore.instance.saveTokens(
  accessToken: 'access-token',
  refreshToken: 'refresh-token',
  userId: 'user-id',
  email: 'user@example.com',
);

class _Client extends ApiClient {
  _Client(this.response);
  Map<String, dynamic> response;
  Object? error;
  final calls = <Map<String, dynamic>>[];

  Map<String, dynamic> _record(
    String method,
    String path,
    bool authorized, [
    Map<String, dynamic>? body,
  ]) {
    calls.add({
      'method': method,
      'path': path,
      'authorized': authorized,
      'body': ?body,
    });
    if (error != null) throw error!;
    return response;
  }

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authorized = false,
  }) async => _record('GET', path, authorized);
  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    bool authorized = false,
  }) async => _record('POST', path, authorized, body);
  @override
  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    bool authorized = false,
  }) async => _record('PATCH', path, authorized, body);
}
