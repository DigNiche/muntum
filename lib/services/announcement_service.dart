import 'package:muntum/api/api_client.dart';
import 'package:muntum/api/api_endpoints.dart';
import 'package:muntum/api/api_response.dart';
import 'package:muntum/models/announcement_model.dart';

class AnnouncementService {
  AnnouncementService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<PageResponse<AnnouncementModel>> fetchAnnouncements({
    int page = 0,
    int size = 20,
    bool manager = false,
  }) async {
    final response = await _client.get(
      manager ? ApiEndpoints.managerAnnouncements : ApiEndpoints.announcements,
      authorized: manager,
      queryParameters: {'page': page, 'size': size},
    );
    return ApiResponse.fromJson(
      response,
      (data) => PageResponse.fromJson(data, AnnouncementModel.fromJson),
    ).data;
  }

  Future<AnnouncementModel> fetchAnnouncement(String id) async {
    final response = await _client.get(ApiEndpoints.announcement(id));
    return ApiResponse.fromJson(
      response,
      (data) =>
          AnnouncementModel.fromJson(data as Map<String, dynamic>? ?? const {}),
    ).data;
  }
}
