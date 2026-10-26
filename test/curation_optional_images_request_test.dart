import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/api/api_client.dart';
import 'package:muntum/services/curation_service.dart';

void main() {
  for (final method in ['POST', 'PUT']) {
    for (final withImage in [false, true]) {
      test(
        '$method multipart omits images unless chosen: $withImage',
        () async {
          final transport = _HttpClient();
          final service = CurationService(
            client: ApiClient(httpClient: transport),
          );
          final paths = withImage
              ? ['assets/default_profile_img.jpg']
              : <String>[];
          if (method == 'POST') {
            await service.submit(
              programTitle: '프로그램',
              place: '장소',
              tagline: '한줄소개',
              content: '본문',
              imagePaths: paths,
            );
          } else {
            await service.update(
              id: 'note-id',
              programTitle: '프로그램',
              place: '장소',
              tagline: '한줄소개',
              content: '수정 본문',
              imagePaths: paths,
            );
          }
          expect(transport.method, method);
          expect(
            transport.uri.path,
            method == 'POST'
                ? '/api/v1/curations'
                : '/api/v1/curations/note-id',
          );
          final payload = utf8.decode(
            transport.request.bytes,
            allowMalformed: true,
          );
          expect(payload, contains('name="curation"'));
          expect(payload.contains('name="images"'), withImage);
          expect(payload, isNot(contains('"images":')));
          expect(payload.contains('filename='), withImage);
          expect(
            transport.request.headers.values['Content-Type'],
            startsWith('multipart/form-data; boundary='),
          );
        },
      );
    }
  }
}

class _HttpClient implements HttpClient {
  late String method;
  late Uri uri;
  late _Request request;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    this.method = method;
    uri = url;
    return request = _Request(method == 'POST' ? 201 : 200);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Request implements HttpClientRequest {
  _Request(this.status);
  final int status;
  final bytes = <int>[];
  @override
  final _Headers headers = _Headers();

  @override
  void add(List<int> data) => bytes.addAll(data);

  @override
  Future<HttpClientResponse> close() async => _Response(status);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Headers implements HttpHeaders {
  final values = <String, Object>{};
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    values[name] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Response extends Stream<List<int>> implements HttpClientResponse {
  _Response(this.statusCode);
  @override
  final int statusCode;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      Stream.value(
        utf8.encode(
          jsonEncode({
            'data': {'id': 'note-id', 'images': [], 'status': 'PENDING'},
          }),
        ),
      ).listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
