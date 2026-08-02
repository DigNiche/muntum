import 'package:muntum/api/api_client.dart';
import 'package:muntum/api/api_endpoints.dart';
import 'package:muntum/api/api_response.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/services/program_service.dart';
import 'package:muntum/stores/program_scrap_store.dart';

class ScrapService {
  ScrapService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<void> scrapProgram(String programId) async {
    await _client.post(ApiEndpoints.scrap(programId), authorized: true);
  }

  Future<void> unscrapProgram(String programId) async {
    await _client.delete(ApiEndpoints.scrap(programId), authorized: true);
  }

  Future<PageResponse<ProgramModel>> fetchMyScraps({
    int page = 0,
    int size = 20,
    bool syncStore = true,
  }) async {
    final response = await _client.get(
      ApiEndpoints.myScraps,
      authorized: true,
      queryParameters: {'page': page, 'size': size},
    );
    final pageResponse = ApiResponse.fromJson(
      response,
      (data) => PageResponse.fromJson(data, ProgramModel.fromJson),
    ).data;
    final enrichedPage = await ProgramService().enrichMissingPeriodDetails(
      pageResponse,
      authorized: true,
    );
    for (final program in enrichedPage.content) {
      program.isBookmark = true;
    }
    if (syncStore) {
      ProgramScrapStore.instance.replaceScrappedPrograms(
        enrichedPage.content,
        notify: false,
      );
    }
    return enrichedPage;
  }
}
