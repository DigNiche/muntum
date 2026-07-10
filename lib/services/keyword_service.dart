import 'package:muntum/api/api_client.dart';
import 'package:muntum/api/api_endpoints.dart';
import 'package:muntum/api/api_response.dart';
import 'package:muntum/models/keyword_model.dart';

class KeywordService {
  KeywordService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<PageResponse<KeywordModel>> fetchKeywords({
    int page = 0,
    int size = 100,
  }) async {
    final response = await _client.get(
      ApiEndpoints.keywords,
      authorized: true,
      queryParameters: {'page': page, 'size': size},
    );
    return ApiResponse.fromJson(
      response,
      (data) => PageResponse.fromJson(data, KeywordModel.fromJson),
    ).data;
  }

  Future<List<KeywordModel>> fetchTaggedKeywords() async {
    final response = await _client.get(ApiEndpoints.taggedKeywords);
    final data = response['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => KeywordModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return PageResponse.fromJson(data, KeywordModel.fromJson).content;
  }

  Future<List<KeywordModel>> fetchTopKeywords({int topN = 6}) async {
    final response = await _client.get(
      ApiEndpoints.topKeywords,
      queryParameters: {'topN': topN},
    );
    final data = response['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => KeywordModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return PageResponse.fromJson(data, KeywordModel.fromJson).content;
  }
}
