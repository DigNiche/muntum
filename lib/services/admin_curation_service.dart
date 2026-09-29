import 'package:muntum/api/api_client.dart';
import 'package:muntum/api/api_endpoints.dart';
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

  Future<AdminCurationModel> requestChanges({
    required String curationId,
    required String reason,
    required String publicationStatus,
  }) async {
    final response = await _client.patch(
      ApiEndpoints.requestCurationChanges(curationId),
      authorized: true,
      body: {
        'changeRequestReason': reason.trim(),
        'publicationStatus': publicationStatus,
      },
    );
    return _parseDetail(response);
  }

  AdminCurationModel _parseDetail(Map<String, dynamic> response) =>
      ApiResponse.fromJson(
        response,
        (data) => AdminCurationModel.fromJson(
          data as Map<String, dynamic>? ?? const {},
        ),
      ).data;
}
