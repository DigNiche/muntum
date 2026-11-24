import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muntum/api/api_client.dart';
import 'package:muntum/api/api_endpoints.dart';
import 'package:muntum/api/api_exception.dart';
import 'package:muntum/api/token_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await TokenStore.instance.saveTokens(
      accessToken: 'old-access',
      refreshToken: 'old-refresh',
    );
  });

  for (final code in ['A003', 'A016', 'A021']) {
    test('$code is not retried with a new MUNTUM JWT', () async {
      final transport = _Transport(
        (_) async => _Response(401, {'error': code, 'message': '재인증 실패'}),
      );
      await expectLater(
        ApiClient(httpClient: transport).post(
          ApiEndpoints.me,
          authorized: true,
          body: {'token': 'apple-identity'},
        ),
        throwsA(isA<ApiException>()),
      );
      expect(transport.requests, hasLength(1));
      expect(await TokenStore.instance.readRefreshToken(), 'old-refresh');
    });
  }

  test(
    'withdrawn token clears the local session without refresh or replay',
    () async {
      final transport = _Transport(
        (_) async => _Response(401, {
          'error': 'WITHDRAWN_TOKEN',
          'message': '탈퇴된 사용자의 토큰입니다.',
        }),
      );
      await expectLater(
        ApiClient(httpClient: transport).get('/protected', authorized: true),
        throwsA(isA<ApiException>()),
      );
      expect(transport.requests, hasLength(1));
      expect(TokenStore.instance.accessToken, isNull);
      expect(await TokenStore.instance.readRefreshToken(), isNull);
    },
  );

  test(
    'A007 rotates tokens without an Authorization header, then replays once',
    () async {
      final transport = _Transport((request) async {
        if (request.uri.path == ApiEndpoints.refresh) {
          expect(request.headers.values.containsKey('Authorization'), false);
          expect(jsonDecode(utf8.decode(request.bytes)), {
            'refreshToken': 'old-refresh',
          });
          return _Response(200, _rotated);
        }
        return request.headers.values['Authorization'] == 'Bearer new-access'
            ? _Response(200, {'data': 'success'})
            : _Response(401, {'error': 'A007', 'message': '만료'});
      });
      final response = await ApiClient(
        httpClient: transport,
      ).get('/protected', authorized: true);
      expect(response['data'], 'success');
      expect(transport.requests, hasLength(3));
      expect(await TokenStore.instance.readRefreshToken(), 'new-refresh');
    },
  );

  test('failed refresh due to a server outage preserves the token', () async {
    final transport = _Transport(
      (request) async => request.uri.path == ApiEndpoints.refresh
          ? _Response(500, {'error': 'E001', 'message': '서버 오류'})
          : _Response(401, {'error': 'A007', 'message': '만료'}),
    );
    await expectLater(
      ApiClient(httpClient: transport).get('/protected', authorized: true),
      throwsA(isA<ApiException>()),
    );
    expect(transport.requests, hasLength(2));
    expect(await TokenStore.instance.readRefreshToken(), 'old-refresh');
  });

  test(
    'simultaneous expired requests share a single rotating refresh',
    () async {
      final refreshPending = Completer<void>();
      final transport = _Transport((request) async {
        if (request.uri.path == ApiEndpoints.refresh) {
          await refreshPending.future;
          return _Response(200, _rotated);
        }
        return request.headers.values['Authorization'] == 'Bearer new-access'
            ? _Response(200, {'data': 'success'})
            : _Response(401, {'error': 'A007', 'message': '만료'});
      });
      final client = ApiClient(httpClient: transport);
      final requests = Future.wait([
        client.get('/first', authorized: true),
        ApiClient(httpClient: transport).get('/second', authorized: true),
      ]);
      await Future<void>.delayed(Duration.zero);
      refreshPending.complete();
      final responses = await requests;
      expect(responses.map((response) => response['data']), [
        'success',
        'success',
      ]);
      expect(
        transport.requests.where(
          (request) => request.uri.path == ApiEndpoints.refresh,
        ),
        hasLength(1),
      );
    },
  );
}

const _rotated = {
  'data': {
    'accessToken': 'new-access',
    'refreshToken': 'new-refresh',
    'userId': 'user-id',
    'email': 'user@example.com',
  },
};

class _Transport implements HttpClient {
  _Transport(this.respond);
  final Future<_Response> Function(_Request) respond;
  final requests = <_Request>[];
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    final request = _Request(url, respond);
    requests.add(request);
    return request;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Request implements HttpClientRequest {
  _Request(this.uri, this.respond);
  @override
  final Uri uri;
  final Future<_Response> Function(_Request) respond;
  final bytes = <int>[];
  @override
  final _Headers headers = _Headers();
  @override
  void add(List<int> data) => bytes.addAll(data);
  @override
  Future<HttpClientResponse> close() => respond(this);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Headers implements HttpHeaders {
  final values = <String, Object>{};
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) =>
      values[name] = value;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Response extends Stream<List<int>> implements HttpClientResponse {
  _Response(this.statusCode, this.body);
  @override
  final int statusCode;
  final Map<String, dynamic> body;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream.value(utf8.encode(jsonEncode(body))).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
