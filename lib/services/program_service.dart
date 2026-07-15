import 'package:muntum/api/api_client.dart';
import 'package:muntum/api/api_endpoints.dart';
import 'package:muntum/api/api_response.dart';
import 'package:muntum/models/program_model.dart';

enum ProgramSort { latest, startDate, endDate }

enum SortOrder { asc, desc }

extension ProgramSortApi on ProgramSort {
  String get apiValue => switch (this) {
    ProgramSort.latest => 'LATEST',
    ProgramSort.startDate => 'START_DATE',
    ProgramSort.endDate => 'END_DATE',
  };
}

extension SortOrderApi on SortOrder {
  String get apiValue => switch (this) {
    SortOrder.asc => 'ASC',
    SortOrder.desc => 'DESC',
  };
}

extension FilterApi on Filter {
  String? get apiChip => switch (this) {
    Filter.nowHot => null,
    Filter.free => 'FREE',
    Filter.thisWeek => 'THIS_WEEK',
    Filter.noReservation => 'NO_RESERVATION',
    Filter.exhibition ||
    Filter.show ||
    Filter.experience ||
    Filter.festival => ProgramType.fromFilter(this)?.apiValue,
  };
}

class ProgramService {
  ProgramService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<PageResponse<ProgramModel>> fetchPrograms({
    String? search,
    List<String> keywordNames = const [],
    Filter? chip,
    ProgramSort sort = ProgramSort.latest,
    SortOrder order = SortOrder.desc,
    int page = 0,
    int size = 20,
    bool authorized = false,
  }) async {
    final response = await _client.get(
      ApiEndpoints.programs,
      queryParameters: {
        'search': search,
        'keywordNames': keywordNames.isEmpty ? null : keywordNames,
        'chip': chip?.apiChip,
        'sort': sort.apiValue,
        'order': order.apiValue,
        'page': page,
        'size': size,
      },
      authorized: authorized,
    );
    return ApiResponse.fromJson(
      response,
      (data) => PageResponse.fromJson(data, ProgramModel.fromJson),
    ).data;
  }

  Future<PageResponse<ProgramModel>> fetchBannerPrograms() {
    return fetchPrograms(
      sort: ProgramSort.startDate,
      order: SortOrder.desc,
      page: 0,
      size: 5,
    );
  }

  Future<PageResponse<ProgramModel>> fetchClosingSoon({
    Filter? chip,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.get(
      ApiEndpoints.programsClosingSoon,
      queryParameters: {'chip': chip?.apiChip, 'page': page, 'size': size},
    );
    return ApiResponse.fromJson(
      response,
      (data) => PageResponse.fromJson(data, ProgramModel.fromJson),
    ).data;
  }

  Future<PageResponse<ProgramModel>> fetchHotPrograms({
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.get(
      ApiEndpoints.programsHot,
      queryParameters: {'page': page, 'size': size},
    );
    return ApiResponse.fromJson(
      response,
      (data) => PageResponse.fromJson(data, ProgramModel.fromJson),
    ).data;
  }

  Future<PageResponse<ProgramModel>> fetchHotKeywordPrograms({
    Filter? chip,
    int topN = 5,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.get(
      ApiEndpoints.programsHotKeywords,
      queryParameters: {
        'chip': chip?.apiChip,
        'topN': topN,
        'page': page,
        'size': size,
      },
    );
    return ApiResponse.fromJson(
      response,
      (data) => PageResponse.fromJson(data, ProgramModel.fromJson),
    ).data;
  }

  Future<PageResponse<ProgramModel>> fetchMapPrograms({
    required double southWestLatitude,
    required double southWestLongitude,
    required double northEastLatitude,
    required double northEastLongitude,
    String? chip,
  }) async {
    final response = await _client.get(
      ApiEndpoints.programsMap,
      queryParameters: {
        'swLat': southWestLatitude,
        'swLng': southWestLongitude,
        'neLat': northEastLatitude,
        'neLng': northEastLongitude,
        'chip': chip,
      },
    );
    return ApiResponse.fromJson(
      response,
      (data) => PageResponse.fromJson(data, ProgramModel.fromJson),
    ).data;
  }

  Future<PageResponse<ProgramModel>> fetchNearbyPrograms({
    required double latitude,
    required double longitude,
    double radiusKm = 5,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.get(
      ApiEndpoints.programsNearby,
      queryParameters: {
        'lat': latitude,
        'lng': longitude,
        'radiusKm': radiusKm,
        'page': page,
        'size': size,
      },
    );
    return ApiResponse.fromJson(
      response,
      (data) => PageResponse.fromJson(data, ProgramModel.fromJson),
    ).data;
  }

  Future<ProgramModel> fetchProgram(
    String id, {
    bool authorized = false,
  }) async {
    final response = await _client.get(
      ApiEndpoints.program(id),
      authorized: authorized,
    );
    return ApiResponse.fromJson(
      response,
      (data) =>
          ProgramModel.fromJson(data as Map<String, dynamic>? ?? const {}),
    ).data;
  }

  Future<ProgramModel> updateProgram({
    required String id,
    required Map<String, dynamic> program,
    List<String> imagePaths = const [],
  }) async {
    final response = await _client.putMultipart(
      ApiEndpoints.program(id),
      jsonPart: program,
      filePaths: imagePaths,
      authorized: true,
    );
    return ApiResponse.fromJson(
      response,
      (data) =>
          ProgramModel.fromJson(data as Map<String, dynamic>? ?? const {}),
    ).data;
  }

  Future<ProgramModel> createProgram({
    required Map<String, dynamic> program,
    List<String> imagePaths = const [],
  }) async {
    final response = await _client.postMultipart(
      ApiEndpoints.programs,
      jsonPart: program,
      filePaths: imagePaths,
      authorized: true,
    );
    return ApiResponse.fromJson(
      response,
      (data) =>
          ProgramModel.fromJson(data as Map<String, dynamic>? ?? const {}),
    ).data;
  }

  Future<void> deleteProgram(String id) async {
    await _client.delete(ApiEndpoints.program(id), authorized: true);
  }

  Future<List<String>> fetchThumbnailUrls() async {
    final response = await _client.get(ApiEndpoints.programThumbnails);
    final data = response['data'];
    if (data is List) {
      return data
          .map((item) {
            if (item is Map) return item['imageUrl'] as String?;
            if (item is String) return item;
            return null;
          })
          .whereType<String>()
          .where((url) => url.isNotEmpty)
          .map(_normalizeImageUrl)
          .toList();
    }
    return const [];
  }

  String _normalizeImageUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return 'https://$trimmed';
  }
}
