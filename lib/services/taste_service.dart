import 'package:muntum/api/api_client.dart';
import 'package:muntum/api/api_endpoints.dart';
import 'package:muntum/api/api_response.dart';
import 'package:muntum/models/keyword_model.dart';
import 'package:muntum/models/program_model.dart';

class TasteService {
  TasteService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<TasteKeywordResult> fetchMyKeywords() async {
    final response = await _client.get(
      ApiEndpoints.myTasteKeywords,
      authorized: true,
    );
    return ApiResponse.fromJson(response, TasteKeywordResult.fromJson).data;
  }

  Future<TasteKeywordResult> saveMyKeywords(List<String> keywordNames) async {
    final response = await _client.post(
      ApiEndpoints.myTasteKeywords,
      authorized: true,
      body: {'selectKeywords': keywordNames},
    );
    return ApiResponse.fromJson(response, TasteKeywordResult.fromJson).data;
  }

  Future<PageResponse<ProgramModel>> fetchTastePrograms({
    String? chip,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.get(
      ApiEndpoints.myTastePrograms,
      authorized: true,
      queryParameters: {'chip': chip, 'page': page, 'size': size},
    );
    return ApiResponse.fromJson(
      response,
      (data) => PageResponse.fromJson(data, ProgramModel.fromJson),
    ).data;
  }
}
