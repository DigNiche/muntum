import 'package:muntum/api/api_client.dart';
import 'package:muntum/api/api_endpoints.dart';
import 'package:muntum/models/keyword_model.dart';

class RecentSearchModel {
  final String id;
  final String keyword;
  final DateTime? createdAt;

  const RecentSearchModel({
    required this.id,
    required this.keyword,
    this.createdAt,
  });

  factory RecentSearchModel.fromJson(Map<String, dynamic> json) {
    return RecentSearchModel(
      id: '${json['id'] ?? ''}',
      keyword:
          json['keyword'] as String? ??
          json['search'] as String? ??
          json['query'] as String? ??
          '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}

class SearchService {
  SearchService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<KeywordModel>> fetchTopSearchKeywords() async {
    final response = await _client.get(
      ApiEndpoints.topKeywords,
      queryParameters: {'topN': 6},
    );
    final data = response['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => KeywordModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    final content = (data as Map<String, dynamic>?)?['content'];
    if (content is List) {
      return content
          .whereType<Map>()
          .map((item) => KeywordModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return const [];
  }

  Future<List<RecentSearchModel>> fetchRecentSearches() async {
    final response = await _client.get(
      ApiEndpoints.recentSearch,
      authorized: true,
    );
    final data = response['data'];
    final list = data is List
        ? data
        : ((data as Map<String, dynamic>?)?['content'] as List? ?? const []);
    return list.indexed
        .map((entry) {
          final index = entry.$1;
          final item = entry.$2;
          if (item is String) {
            return RecentSearchModel(id: '$index', keyword: item);
          }
          if (item is Map) {
            return RecentSearchModel.fromJson(Map<String, dynamic>.from(item));
          }
          return null;
        })
        .whereType<RecentSearchModel>()
        .toList();
  }

  Future<void> saveRecentSearch(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return;

    try {
      await _client.post(
        ApiEndpoints.recentSearch,
        authorized: true,
        queryParameters: {'query': trimmed},
        body: {'query': trimmed},
      );
    } catch (_) {
      await _client.post(
        ApiEndpoints.recentSearch,
        authorized: true,
        queryParameters: {'query': trimmed},
        body: {'keyword': trimmed},
      );
    }
  }

  Future<void> deleteRecentSearch(String keyword) async {
    await _client.delete(
      ApiEndpoints.recentSearch,
      authorized: true,
      queryParameters: {'query': keyword},
    );
  }

  Future<void> deleteAllRecentSearches() async {
    await _client.delete(ApiEndpoints.recentSearchAll, authorized: true);
  }
}
