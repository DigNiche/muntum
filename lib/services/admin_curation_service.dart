import 'package:muntum/api/api_client.dart';
import 'package:muntum/api/api_endpoints.dart';
import 'package:muntum/api/api_exception.dart';
import 'package:muntum/api/api_response.dart';
import 'package:muntum/models/admin_curation_model.dart';
import 'package:muntum/models/curation_model.dart';

class AdminCurationService {
  AdminCurationService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<PageResponse<AdminCurationModel>> fetchList({
    required CurationStatus status,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.get(
      ApiEndpoints.managerCurations,
      authorized: true,
      queryParameters: {
        'status': switch (status) {
          CurationStatus.pending => 'PENDING',
          CurationStatus.changesRequested => 'CHANGES_REQUESTED',
          CurationStatus.approved => 'APPROVED',
          CurationStatus.unknown => null,
        },
        'page': page,
        'size': size,
      },
    );
    return ApiResponse.fromJson(
      response,
      (data) => PageResponse.fromJson(data, AdminCurationModel.fromJson),
    ).data;
  }

  Future<AdminCurationModel> fetchDetail(String id) async {
    final response = await _client.get(
      ApiEndpoints.managerCuration(id),
      authorized: true,
    );
    return _parseDetail(response);
  }

  Future<AdminCurationModel> approveExisting({
    required String curationId,
    required String programId,
  }) async {
    final response = await _client.patch(
      ApiEndpoints.approveExistingCuration(curationId),
      authorized: true,
      body: {'programId': programId},
    );
    return _parseDetail(response);
  }

  Future<AdminCurationModel> approveNew({
    required String curationId,
    required Map<String, dynamic> program,
    List<String> imagePaths = const [],
  }) async {
    final response = await _client.postMultipart(
      ApiEndpoints.approveNewCuration(curationId),
      authorized: true,
      jsonFieldName: 'program',
      jsonPart: program,
      fileFieldName: 'images',
      filePaths: imagePaths,
    );
    return _parseDetail(response);
  }

  Future<void> requestChanges({
    required String curationId,
    required String reason,
    required String publicationStatus,
  }) async {
    Object? requestError;
    try {
      await _client.patch(
        ApiEndpoints.requestCurationChanges(curationId),
        authorized: true,
        body: {
          'changeRequestReason': reason.trim(),
          'publicationStatus': publicationStatus,
        },
      );
      return;
    } catch (error) {
      requestError = error;
    }

    // The server may commit the request but return a response the client
    // cannot decode. Check the persisted review state before showing an error.
    for (var attempt = 0; attempt < 2; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
      try {
        final detail = await fetchDetail(curationId);
        if (detail.curation.status == CurationStatus.changesRequested) return;
      } catch (_) {
        // The list endpoint can still reflect a successful request.
      }
      try {
        var page = 0;
        while (true) {
          final result = await fetchList(
            status: CurationStatus.changesRequested,
            page: page,
            size: 100,
          );
          if (result.content.any(
            (item) =>
                item.curation.id == curationId &&
                item.curation.status == CurationStatus.changesRequested,
          )) {
            return;
          }
          if (!result.hasMore || result.content.isEmpty) break;
          page = result.page + 1;
        }
      } catch (_) {
        // Preserve the original API error if this read also fails.
      }
    }
    if (requestError is ApiException) throw requestError;
    throw const ApiException(
      code: 'CURATION_CHANGE_UNVERIFIED',
      message: '수정 요청 결과를 확인하지 못했어요. 목록을 새로고침해 주세요.',
    );
  }

  AdminCurationModel _parseDetail(Map<String, dynamic> response) =>
      ApiResponse.fromJson(
        response,
        (data) => AdminCurationModel.fromJson(
          data as Map<String, dynamic>? ?? const {},
        ),
      ).data;
}
