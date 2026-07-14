import 'package:muntum/api/api_client.dart';
import 'package:muntum/api/api_endpoints.dart';
import 'package:muntum/api/api_response.dart';
import 'package:muntum/models/admin_user_model.dart';

class AdminUserService {
  AdminUserService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<PageResponse<AdminUserModel>> fetchUsers({
    String? search,
    int page = 0,
    int size = 20,
  }) async {
    final normalizedSearch = search?.trim();
    final response = await _client.get(
      ApiEndpoints.adminUsers,
      authorized: true,
      queryParameters: {
        if (normalizedSearch != null && normalizedSearch.isNotEmpty)
          'search': normalizedSearch,
        'page': page,
        'size': size,
      },
    );

    return ApiResponse.fromJson(
      response,
      (data) => PageResponse.fromJson(data, AdminUserModel.fromJson),
    ).data;
  }
}
