import 'package:muntum/api/api_client.dart';
import 'package:muntum/api/api_endpoints.dart';
import 'package:muntum/api/api_response.dart';
import 'package:muntum/models/curation_model.dart';

class CurationService {
  CurationService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<PageResponse<PublicCurationModel>> fetchProgramCurations(
    String programId, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.get(
      ApiEndpoints.programCurations(programId),
      queryParameters: {'page': page, 'size': size},
    );
    return ApiResponse.fromJson(
      response,
      (data) => PageResponse.fromJson(data, PublicCurationModel.fromJson),
    ).data;
  }

  Future<PublicCurationModel> fetchProgramCurationDetail(
    String programId,
    String curationId,
  ) async {
    final response = await _client.get(
      ApiEndpoints.programCuration(programId, curationId),
    );
    return ApiResponse.fromJson(
      response,
      (data) => PublicCurationModel.fromJson(
        data as Map<String, dynamic>? ?? const {},
      ),
    ).data;
  }

  Future<CuratorProfileModel> fetchMyProfile() async {
    final response = await _client.get(
      ApiEndpoints.myCuratorProfile,
      authorized: true,
    );
    return ApiResponse.fromJson(
      response,
      (data) => CuratorProfileModel.fromJson(
        data as Map<String, dynamic>? ?? const {},
      ),
    ).data;
  }

  Future<PageResponse<CurationModel>> fetchMine({
    CurationStatus? status,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.get(
      ApiEndpoints.myCurations,
      authorized: true,
      queryParameters: {
        'status': status == null ? null : _statusValue(status),
        'page': page,
        'size': size,
      },
    );
    return ApiResponse.fromJson(
      response,
      (data) => PageResponse.fromJson(data, CurationModel.fromJson),
    ).data;
  }

  Future<List<CurationModel>> fetchAllMineWithDetails() async {
    final summaries = <CurationModel>[];
    var pageNumber = 0;
    while (true) {
      final page = await fetchMine(page: pageNumber, size: 100);
      summaries.addAll(page.content);
      if (!page.hasMore) break;
      pageNumber = page.page + 1;
    }
    return Future.wait(
      summaries.map((summary) async {
        try {
          return summary.mergeDetails(await fetchMyDetail(summary.id));
        } catch (_) {
          return summary;
        }
      }),
    );
  }

  Future<CurationModel> fetchMyDetail(String id) async {
    final response = await _client.get(
      ApiEndpoints.myCuration(id),
      authorized: true,
    );
    return _parseCuration(response);
  }

  Future<CurationModel> submit({
    required String programTitle,
    required String place,
    required String tagline,
    required String content,
    required List<String> imagePaths,
  }) async {
    final response = await _client.postMultipart(
      ApiEndpoints.curations,
      authorized: true,
      jsonFieldName: 'curation',
      fileFieldName: 'images',
      jsonPart: {
        'submittedProgramTitle': programTitle,
        'submittedPlace': place,
        'tagline': tagline,
        'content': content,
      },
      filePaths: imagePaths,
    );
    return _parseCuration(response);
  }

  Future<CurationModel> update({
    required String id,
    required String programTitle,
    required String place,
    required String tagline,
    required String content,
    List<String> imagePaths = const [],
  }) async {
    final response = await _client.putMultipart(
      ApiEndpoints.curation(id),
      authorized: true,
      jsonFieldName: 'curation',
      fileFieldName: 'images',
      jsonPart: {
        'submittedProgramTitle': programTitle,
        'submittedPlace': place,
        'tagline': tagline,
        'content': content,
      },
      filePaths: imagePaths,
    );
    return _parseCuration(response);
  }

  Future<CurationModel> resubmit(String id) async {
    final response = await _client.patch(
      ApiEndpoints.resubmitCuration(id),
      authorized: true,
    );
    return _parseCuration(response);
  }

  Future<void> delete(String id) async {
    await _client.delete(ApiEndpoints.curation(id), authorized: true);
  }

  CurationModel _parseCuration(Map<String, dynamic> response) {
    return ApiResponse.fromJson(
      response,
      (data) =>
          CurationModel.fromJson(data as Map<String, dynamic>? ?? const {}),
    ).data;
  }

  String _statusValue(CurationStatus status) => switch (status) {
    CurationStatus.pending => 'PENDING',
    CurationStatus.approved => 'APPROVED',
    CurationStatus.changesRequested => 'CHANGES_REQUESTED',
    CurationStatus.unknown => '',
  };
}
