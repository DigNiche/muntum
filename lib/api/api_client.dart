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
  bool _isRefreshing = false;

  Uri _uri(String path, [Map<String, dynamic>? queryParameters]) {
    final baseUrl = ApiConfig.baseUrl;
    if (baseUrl.isEmpty) {
      throw const ApiException(
        message:
            'API_BASE_URL이 설정되지 않았습니다. .env 또는 --dart-define으로 Base URL을 넣어주세요.',
      );
    }

    final uri = Uri.parse('$baseUrl$path');
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

    if (statusCode == 401 &&
        authorized &&
        retryOnUnauthorized &&
        await _refreshToken()) {
      return _send(
        method,
        path,
        body: body,
        queryParameters: queryParameters,
        authorized: authorized,
        retryOnUnauthorized: false,
      );
    }

    final decoded = _decode(responseBody);
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

  Future<bool> _refreshToken() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;
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
      await _tokenStore.saveTokens(
        accessToken: auth.accessToken,
        refreshToken: auth.refreshToken,
        userId: auth.userId,
        email: auth.email,
        nickname: auth.nickname,
      );
      return true;
    } catch (_) {
      await _tokenStore.clear();
      return false;
    } finally {
      _isRefreshing = false;
    }
  }
}
