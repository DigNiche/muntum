import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:muntum/models/report_model.dart';

abstract class ReportPlaceSearchRepository {
  Future<List<ReportPlace>> search(String query);
}

class NaverLocalPlaceSearchRepository implements ReportPlaceSearchRepository {
  const NaverLocalPlaceSearchRepository({HttpClient? httpClient})
    : this._(httpClient);

  const NaverLocalPlaceSearchRepository._(this._httpClient);

  final HttpClient? _httpClient;

  @override
  Future<List<ReportPlace>> search(String query) async {
    final keyword = query.trim();
    if (keyword.isEmpty) return const [];

    final mapsKeyId = _envValue([
      'NAVER_MAP_CLIENT_ID',
      'NAVER_MAP_API_KEY_ID',
      'NCP_MAPS_API_KEY_ID',
      'X_NCP_APIGW_API_KEY_ID',
    ]);
    final mapsKey = _envValue([
      'NAVER_MAP_CLIENT_SECRET',
      'NAVER_MAP_API_KEY',
      'NAVER_MAP_API_SECRET',
      'NCP_MAPS_API_KEY',
      'X_NCP_APIGW_API_KEY',
    ]);
    final localSearchClientId = _envValue([
      'NAVER_PLACES_API_CLIENT_ID',
      'NAVER_SEARCH_CLIENT_ID',
      'NAVER_LOCAL_SEARCH_CLIENT_ID',
      'NAVER_CLIENT_ID',
    ]);
    final localSearchClientSecret = _envValue([
      'NAVER_PLACES_API_CLIENT_SECRET',
      'NAVER_SEARCH_CLIENT_SECRET',
      'NAVER_LOCAL_SEARCH_CLIENT_SECRET',
      'NAVER_CLIENT_SECRET',
    ]);

    if (mapsKeyId.isEmpty && localSearchClientId.isEmpty) {
      return const [];
    }

    final client = _httpClient ?? HttpClient();
    try {
      if (mapsKeyId.isNotEmpty && mapsKey.isNotEmpty) {
        final places = await _searchNaverMapsPlaces(
          client: client,
          keyword: keyword,
          keyId: mapsKeyId,
          key: mapsKey,
        );
        if (places.isNotEmpty) return places;

        final geocodedPlaces = await _searchNaverMapsGeocode(
          client: client,
          keyword: keyword,
          keyId: mapsKeyId,
          key: mapsKey,
        );
        if (geocodedPlaces.isNotEmpty) return geocodedPlaces;
      }

      if (localSearchClientId.isNotEmpty &&
          localSearchClientSecret.isNotEmpty) {
        return _searchNaverLocal(
          client: client,
          keyword: keyword,
          clientId: localSearchClientId,
          clientSecret: localSearchClientSecret,
        );
      }
      return const [];
    } catch (_) {
      return const [];
    } finally {
      if (_httpClient == null) {
        client.close(force: true);
      }
    }
  }

  static Future<List<ReportPlace>> _searchNaverMapsPlaces({
    required HttpClient client,
    required String keyword,
    required String keyId,
    required String key,
  }) async {
    final uri = Uri.https(
      'naveropenapi.apigw.ntruss.com',
      '/map-place/v1/search',
      {
        'query': keyword,
        // 서울시청 좌표를 기준점으로 주면 국내 장소명 검색 품질이 더 안정적이다.
        'coordinate': '126.9783882,37.5666103',
      },
    );
    final decoded = await _getJson(
      client: client,
      uri: uri,
      headers: {'X-NCP-APIGW-API-KEY-ID': keyId, 'X-NCP-APIGW-API-KEY': key},
    );
    if (decoded == null) return const [];

    final places = decoded['places'] as List? ?? const [];
    return places
        .whereType<Map>()
        .map(
          (item) => _placeFromNaverMapsPlace(Map<String, dynamic>.from(item)),
        )
        .where((place) => place.name.isNotEmpty || place.address.isNotEmpty)
        .toList();
  }

  static Future<List<ReportPlace>> _searchNaverMapsGeocode({
    required HttpClient client,
    required String keyword,
    required String keyId,
    required String key,
  }) async {
    final uri = Uri.https('maps.apigw.ntruss.com', '/map-geocode/v2/geocode', {
      'query': keyword,
    });
    final decoded = await _getJson(
      client: client,
      uri: uri,
      headers: {'X-NCP-APIGW-API-KEY-ID': keyId, 'X-NCP-APIGW-API-KEY': key},
    );
    if (decoded == null) return const [];

    final addresses = decoded['addresses'] as List? ?? const [];
    return addresses
        .whereType<Map>()
        .map(
          (item) => _placeFromNaverMapsAddress(Map<String, dynamic>.from(item)),
        )
        .where((place) => place.name.isNotEmpty || place.address.isNotEmpty)
        .toList();
  }

  static Future<List<ReportPlace>> _searchNaverLocal({
    required HttpClient client,
    required String keyword,
    required String clientId,
    required String clientSecret,
  }) async {
    final uri = Uri.https('openapi.naver.com', '/v1/search/local.json', {
      'query': keyword,
      'display': '5',
      'start': '1',
      'sort': 'random',
    });
    final decoded = await _getJson(
      client: client,
      uri: uri,
      headers: {
        'X-Naver-Client-Id': clientId,
        'X-Naver-Client-Secret': clientSecret,
      },
    );
    if (decoded == null) return const [];

    final items = decoded['items'] as List? ?? const [];
    return items
        .whereType<Map>()
        .map(
          (item) => _placeFromNaverLocalItem(Map<String, dynamic>.from(item)),
        )
        .where((place) => place.name.isNotEmpty || place.address.isNotEmpty)
        .toList();
  }

  static Future<Map<String, dynamic>?> _getJson({
    required HttpClient client,
    required Uri uri,
    required Map<String, String> headers,
  }) async {
    final request = await client.getUrl(uri);
    request.headers.set('Accept', 'application/json');
    for (final entry in headers.entries) {
      if (entry.value.trim().isNotEmpty) {
        request.headers.set(entry.key, entry.value.trim());
      }
    }

    final response = await request.close();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      await response.drain<void>();
      return null;
    }
    final body = await utf8.decodeStream(response);
    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  static String _envValue(List<String> keys) {
    try {
      for (final key in keys) {
        final value = dotenv.env[key]?.trim() ?? '';
        if (value.isNotEmpty) return value;
      }
    } catch (_) {
      return '';
    }
    return '';
  }

  static ReportPlace _placeFromNaverMapsPlace(Map<String, dynamic> item) {
    final name = _cleanText('${item['name'] ?? item['title'] ?? ''}');
    final roadAddress = _cleanText(
      '${item['road_address'] ?? item['roadAddress'] ?? ''}',
    );
    final address = _cleanText(
      '${item['jibun_address'] ?? item['jibunAddress'] ?? item['address'] ?? ''}',
    );

    return ReportPlace(
      name: name,
      address: roadAddress.isNotEmpty ? roadAddress : address,
      longitude: double.tryParse('${item['x'] ?? item['longitude'] ?? ''}'),
      latitude: double.tryParse('${item['y'] ?? item['latitude'] ?? ''}'),
    );
  }

  static ReportPlace _placeFromNaverMapsAddress(Map<String, dynamic> item) {
    final roadAddress = _cleanText('${item['roadAddress'] ?? ''}');
    final jibunAddress = _cleanText('${item['jibunAddress'] ?? ''}');
    final englishAddress = _cleanText('${item['englishAddress'] ?? ''}');
    final address = roadAddress.isNotEmpty
        ? roadAddress
        : jibunAddress.isNotEmpty
        ? jibunAddress
        : englishAddress;

    return ReportPlace(
      name: address,
      address: address,
      longitude: double.tryParse('${item['x'] ?? ''}'),
      latitude: double.tryParse('${item['y'] ?? ''}'),
    );
  }

  static ReportPlace _placeFromNaverLocalItem(Map<String, dynamic> item) {
    final name = _stripHtml(item['title'] as String? ?? '');
    final roadAddress = item['roadAddress'] as String? ?? '';
    final address = item['address'] as String? ?? '';
    final longitude = double.tryParse('${item['mapx'] ?? ''}');
    final latitude = double.tryParse('${item['mapy'] ?? ''}');

    return ReportPlace(
      name: name,
      address: roadAddress.isNotEmpty ? roadAddress : address,
      longitude: longitude == null ? null : longitude / 10000000,
      latitude: latitude == null ? null : latitude / 10000000,
    );
  }

  static String _stripHtml(String value) {
    return _cleanText(
      value
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&quot;', '"'),
    );
  }

  static String _cleanText(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
