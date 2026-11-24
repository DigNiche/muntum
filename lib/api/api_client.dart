import 'dart:convert';
import 'dart:io';

import 'package:muntum/api/api_config.dart';
import 'package:muntum/api/api_endpoints.dart';
import 'package:muntum/api/api_exception.dart';
import 'package:muntum/api/token_store.dart';
import 'package:muntum/models/auth_models.dart';

class ApiClient {
  ApiClient({HttpClient? httpClient, TokenStore? tokenStore})
    : _httpClient = httpClient ?? HttpClient(),
      _tokenStore = tokenStore ?? TokenStore.instance;

  final HttpClient _httpClient;
  final TokenStore _tokenStore;
  static Future<bool>? _refreshInFlight;

  Uri _uri(String path, [Map<String, dynamic>? queryParameters]) {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final filteredQuery = <String, dynamic>{};
    queryParameters?.forEach((key, value) {
      if (value == null) return;
      filteredQuery[key] = value;
    });
    return uri.replace(queryParameters: _flattenQuery(filteredQuery));
  }

  Map<String, dynamic> _flattenQuery(Map<String, dynamic> query) {
    return query.map((key, value) {
      if (value is Iterable) {
        return MapEntry(key, value.map((e) => e.toString()).toList());
      }
      return MapEntry(key, value.toString());
    });
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authorized = false,
  }) {
    return _send(
      'GET',
      path,
      queryParameters: queryParameters,
      authorized: authorized,
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    bool authorized = false,
  }) {
    return _send(
      'POST',
      path,
      body: body,
      queryParameters: queryParameters,
      authorized: authorized,
    );
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    bool authorized = false,
  }) {
    return _send('PUT', path, body: body, authorized: authorized);
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    bool authorized = false,
  }) {
    return _send('PATCH', path, body: body, authorized: authorized);
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authorized = false,
  }) {
    return _send(
      'DELETE',
      path,
      queryParameters: queryParameters,
      authorized: authorized,
    );
  }

  Future<Map<String, dynamic>> putMultipart(
    String path, {
    required Map<String, dynamic> jsonPart,
    String jsonFieldName = 'program',
    List<String> filePaths = const [],
    String fileFieldName = 'images',
    bool authorized = false,
  }) {
    return _sendMultipart(
      'PUT',
      path,
      jsonPart: jsonPart,
      jsonFieldName: jsonFieldName,
      filePaths: filePaths,
      fileFieldName: fileFieldName,
      authorized: authorized,
    );
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, dynamic> jsonPart,
    String jsonFieldName = 'program',
    List<String> filePaths = const [],
    String fileFieldName = 'images',
    bool authorized = false,
  }) {
    return _sendMultipart(
      'POST',
      path,
      jsonPart: jsonPart,
      jsonFieldName: jsonFieldName,
      filePaths: filePaths,
      fileFieldName: fileFieldName,
      authorized: authorized,
    );
  }

  Future<Map<String, dynamic>> putFile(
    String path, {
    required String filePath,
    String fileFieldName = 'image',
    bool authorized = false,
  }) {
    return _sendMultipart(
      'PUT',
      path,
      filePaths: [filePath],
      fileFieldName: fileFieldName,
      authorized: authorized,
    );
  }

  Future<Map<String, dynamic>> _sendMultipart(
    String method,
    String path, {
    Map<String, dynamic>? jsonPart,
    String jsonFieldName = 'program',
    required List<String> filePaths,
    required String fileFieldName,
    required bool authorized,
    bool retryOnUnauthorized = true,
  }) async {
    final boundary =
        'muntum-${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}';
    final request = await _httpClient.openUrl(method, _uri(path));
    request.headers.set('Accept', 'application/json');
    request.headers.set(
      'Content-Type',
      'multipart/form-data; boundary=$boundary',
    );
    if (authorized) {
      final accessToken = _tokenStore.accessToken;
      if (accessToken != null && accessToken.isNotEmpty) {
        request.headers.set('Authorization', 'Bearer $accessToken');
      }
    }

    void addText(String value) => request.add(utf8.encode(value));

    if (jsonPart != null) {
      addText('--$boundary\r\n');
      addText('Content-Disposition: form-data; name="$jsonFieldName"\r\n');
      addText('Content-Type: application/json; charset=utf-8\r\n\r\n');
      addText(jsonEncode(jsonPart));
      addText('\r\n');
    }

    for (final path in filePaths) {
      final file = File(path);
      if (!await file.exists()) continue;
      final filename = Uri.file(path).pathSegments.last.replaceAll('"', '');
      addText('--$boundary\r\n');
      addText(
        'Content-Disposition: form-data; name="$fileFieldName"; '
        'filename="$filename"\r\n',
      );
      addText('Content-Type: ${_imageContentType(filename)}\r\n\r\n');
      request.add(await file.readAsBytes());
      addText('\r\n');
    }
    addText('--$boundary--\r\n');

    final response = await request.close();
    final statusCode = response.statusCode;
    final responseBody = await utf8.decodeStream(response);
    final decoded = _decode(responseBody);

    if (await _shouldRefresh(
      statusCode,
      decoded,
      authorized,
      retryOnUnauthorized,
    )) {
      return _sendMultipart(
        method,
        path,
        jsonPart: jsonPart,
        jsonFieldName: jsonFieldName,
        filePaths: filePaths,
        fileFieldName: fileFieldName,
        authorized: authorized,
        retryOnUnauthorized: false,
      );
    }

    if (statusCode < 200 || statusCode >= 300) {
      throw ApiException(
        statusCode: statusCode,
        code: decoded['error'] as String? ?? decoded['code'] as String?,
        message: decoded['message'] as String? ?? 'API 요청에 실패했습니다.',
        body: decoded,
      );
    }
    return decoded;
  }

  String _imageContentType(String filename) {
    final extension = filename.toLowerCase().split('.').last;
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => throw const FormatException(
        '지원하지 않는 이미지 형식입니다. JPG, PNG, WEBP, GIF 파일을 사용해주세요.',
      ),
    };
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    bool authorized = false,
    bool retryOnUnauthorized = true,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };
    if (authorized) {
      final accessToken = _tokenStore.accessToken;
      if (accessToken != null && accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
      }
    }

    final request = await _httpClient.openUrl(
      method,
      _uri(path, queryParameters),
    );
    headers.forEach(request.headers.set);
    if (body != null) {
      request.add(utf8.encode(jsonEncode(body)));
    }

    final response = await request.close();
    final statusCode = response.statusCode;
    final responseBody = await utf8.decodeStream(response);
    final decoded = _decode(responseBody);

    if (await _shouldRefresh(
      statusCode,
      decoded,
      authorized,
      retryOnUnauthorized,
    )) {
      return _send(
        method,
        path,
        body: body,
        queryParameters: queryParameters,
        authorized: authorized,
        retryOnUnauthorized: false,
      );
    }

    if (statusCode < 200 || statusCode >= 300) {
      throw ApiException(
        statusCode: statusCode,
        code: decoded['error'] as String? ?? decoded['code'] as String?,
        message: decoded['message'] as String? ?? 'API 요청에 실패했습니다.',
        body: decoded,
      );
    }
    return decoded;
  }

  Map<String, dynamic> _decode(String body) {
    if (body.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    return {'data': decoded};
  }

  Future<bool> _shouldRefresh(
    int statusCode,
    Map<String, dynamic> response,
    bool authorized,
    bool retryOnUnauthorized,
  ) async {
    if (!authorized || statusCode != 401) return false;
    if (response['error'] == 'WITHDRAWN_TOKEN') {
      await _tokenStore.clear();
      return false;
    }
    // Password and social-token failures are not expired MUNTUM JWTs.
    return retryOnUnauthorized &&
        response['error'] == 'A007' &&
        await _refreshToken();
  }

  Future<bool> _refreshToken() {
    return _refreshInFlight ??= _performRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<bool> _performRefresh() async {
    try {
      final refreshToken = await _tokenStore.readRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final response = await _send(
        'POST',
        ApiEndpoints.refresh,
        body: {'refreshToken': refreshToken},
        retryOnUnauthorized: false,
      );
      final auth = AuthSession.fromJson(
        response['data'] as Map<String, dynamic>? ?? const {},
      );
      if (auth.accessToken.isEmpty || auth.refreshToken.isEmpty) {
        throw const FormatException('재발급 인증 정보를 확인할 수 없습니다.');
      }
      await _tokenStore.saveTokens(
        accessToken: auth.accessToken,
        refreshToken: auth.refreshToken,
        userId: auth.userId,
        email: auth.email,
        nickname: auth.nickname,
        role: auth.role,
      );
      return true;
    } on ApiException catch (error) {
      if (error.statusCode == 401 ||
          (error.statusCode == 404 && error.code == 'A002')) {
        await _tokenStore.clear();
      }
      return false;
    } catch (_) {
      // A temporary network failure must not erase a usable refresh token.
      return false;
    }
  }
}
