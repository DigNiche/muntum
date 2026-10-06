import 'package:muntum/api/api_client.dart';
import 'package:muntum/api/api_endpoints.dart';
import 'package:muntum/api/api_response.dart';
import 'package:muntum/models/curator_application_model.dart';
import 'package:muntum/utils/single_line_text.dart';

class CuratorApplicationService {
  CuratorApplicationService({ApiClient? client})
    : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<CuratorApplicationModel> submit({
    required String programName,
    required String tagline,
    required String curation,
  }) async {
    final response = await _client.post(
      ApiEndpoints.curatorApplications,
      authorized: true,
      body: {
        'programName': programName,
        'tagline': singleLineIntroduction(tagline),
        'curation': curation,
      },
    );
    return _parseApplication(response);
  }

  Future<CuratorApplicationModel> fetchLatest() async {
    final response = await _client.get(
      ApiEndpoints.latestCuratorApplication,
      authorized: true,
    );
    return _parseApplication(response);
  }

  Future<PageResponse<CuratorApplicationModel>> fetchMine({
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.get(
      ApiEndpoints.myCuratorApplications,
      authorized: true,
      queryParameters: {'page': page, 'size': size},
    );
    final result = ApiResponse.fromJson(
      response,
      (data) => PageResponse.fromJson(data, CuratorApplicationModel.fromJson),
    ).data;

    final content = await Future.wait(
      result.content.map((application) async {
        if (application.id.isEmpty || application.programName.isNotEmpty) {
          return application;
        }
        try {
          final details = await fetchDetail(application.id);
          return application.copyWithDetails(details);
        } catch (_) {
          return application;
        }
      }),
    );
    return PageResponse(
      content: content,
      page: result.page,
      size: result.size,
      totalElements: result.totalElements,
      totalPages: result.totalPages,
      first: result.first,
      last: result.last,
      hasPrevious: result.hasPrevious,
      hasNext: result.hasNext,
    );
  }

  Future<CuratorApplicationModel> fetchDetail(String id) async {
    final response = await _client.get(
      ApiEndpoints.curatorApplication(id),
      authorized: true,
    );
    return _parseApplication(response);
  }

  Future<PageResponse<CuratorApplicationModel>> fetchForManager({
    required CuratorApplicationStatus status,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.get(
      ApiEndpoints.managerCuratorApplications,
      authorized: true,
      queryParameters: {
        'status': status.name.toUpperCase(),
        'page': page,
        'size': size,
      },
    );
    return ApiResponse.fromJson(
      response,
      (data) => PageResponse.fromJson(data, CuratorApplicationModel.fromJson),
    ).data;
  }

  Future<List<CuratorApplicationModel>> fetchAllForManager({
    required CuratorApplicationStatus status,
    int pageSize = 100,
  }) async {
    final applications = <CuratorApplicationModel>[];
    var pageNumber = 0;
    while (true) {
      final page = await fetchForManager(
        status: status,
        page: pageNumber,
        size: pageSize,
      );
      applications.addAll(page.content);
      if (!page.hasMore) break;
      final nextPage = page.page + 1;
      if (nextPage <= pageNumber) break;
      pageNumber = nextPage;
    }
    return applications;
  }

  Future<CuratorApplicationModel> review({
    required String id,
    required CuratorApplicationStatus status,
    String? rejectReason,
  }) async {
    final response = await _client.patch(
      ApiEndpoints.curatorApplication(id),
      authorized: true,
      body: {
        'status': status.name.toUpperCase(),
        'rejectReason': ?rejectReason,
      },
    );
    return _parseApplication(response);
  }

  Future<CuratorApplicationModel> update({
    required String id,
    required String programName,
    required String tagline,
    required String curation,
  }) async {
    final response = await _client.put(
      ApiEndpoints.curatorApplication(id),
      authorized: true,
      body: {
        'programName': programName,
        'tagline': singleLineIntroduction(tagline),
        'curation': curation,
      },
    );
    return _parseApplication(response);
  }

  CuratorApplicationModel _parseApplication(Map<String, dynamic> response) {
    return ApiResponse.fromJson(
      response,
      (data) => CuratorApplicationModel.fromJson(
        data as Map<String, dynamic>? ?? const {},
      ),
    ).data;
  }
}
