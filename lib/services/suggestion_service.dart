import 'package:muntum/api/api_client.dart';
import 'package:muntum/api/api_endpoints.dart';
import 'package:muntum/api/api_response.dart';
import 'package:muntum/models/report_model.dart';

class SuggestionService {
  SuggestionService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<ReportModel> createSuggestion({
    required String programName,
    required String address,
    required String reason,
    String? placeName,
  }) async {
    final suggestionAddress = ReportPlace(
      name: placeName ?? '',
      address: address,
    ).toSuggestionAddress();
    final response = await _client.post(
      ApiEndpoints.suggestions,
      authorized: true,
      body: {
        'programName': programName,
        'address': suggestionAddress,
        'reason': reason,
      },
    );
    return ApiResponse.fromJson(
      response,
      (data) => ReportModel.fromJson(data as Map<String, dynamic>? ?? const {}),
    ).data;
  }

  Future<PageResponse<ReportModel>> fetchMySuggestions({
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.get(
      ApiEndpoints.mySuggestions,
      authorized: true,
      queryParameters: {'page': page, 'size': size},
    );
    return ApiResponse.fromJson(
      response,
      (data) => PageResponse.fromJson(data, ReportModel.fromJson),
    ).data;
  }

  Future<PageResponse<ReportModel>> fetchManagerSuggestions({
    String? status,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.get(
      ApiEndpoints.managerSuggestions,
      authorized: true,
      queryParameters: {'status': status, 'page': page, 'size': size},
    );
    return ApiResponse.fromJson(
      response,
      (data) => PageResponse.fromJson(data, ReportModel.fromJson),
    ).data;
  }

  Future<PageResponse<ReportModel>> fetchManagerDeletedSuggestions({
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.get(
      ApiEndpoints.managerDeletedSuggestions,
      authorized: true,
      queryParameters: {'page': page, 'size': size},
    );
    return ApiResponse.fromJson(
      response,
      (data) => PageResponse.fromJson(data, ReportModel.fromJson),
    ).data;
  }

  Future<ReportModel> fetchSuggestion(String id) async {
    final response = await _client.get(ApiEndpoints.suggestion(id));
    return ApiResponse.fromJson(
      response,
      (data) => ReportModel.fromJson(data as Map<String, dynamic>? ?? const {}),
    ).data;
  }

  Future<ReportModel> updateSuggestion({
    required String id,
    required String programName,
    required String address,
    required String reason,
    String? placeName,
  }) async {
    final suggestionAddress = ReportPlace(
      name: placeName ?? '',
      address: address,
    ).toSuggestionAddress();
    final response = await _client.put(
      ApiEndpoints.suggestion(id),
      authorized: true,
      body: {
        'programName': programName,
        'address': suggestionAddress,
        'reason': reason,
      },
    );
    return ApiResponse.fromJson(
      response,
      (data) => ReportModel.fromJson(data as Map<String, dynamic>? ?? const {}),
    ).data;
  }

  Future<void> updateSuggestionStatus({
    required String id,
    required String status,
  }) async {
    await _client.patch(
      ApiEndpoints.suggestionStatus(id),
      authorized: true,
      body: {'status': status},
    );
  }

  Future<void> deleteSuggestion(String id) async {
    await _client.delete(ApiEndpoints.suggestion(id), authorized: true);
  }
}
