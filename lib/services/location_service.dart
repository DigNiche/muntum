import 'package:muntum/api/api_client.dart';
import 'package:muntum/api/api_endpoints.dart';
import 'package:muntum/api/api_response.dart';
import 'package:muntum/models/program_model.dart';

class ProgramLocation {
  final String? programId;
  final String venueName;
  final String address;
  final double latitude;
  final double longitude;

  const ProgramLocation({
    this.programId,
    required this.venueName,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory ProgramLocation.fromJson(Map<String, dynamic> json) {
    return ProgramLocation(
      programId: '${json['programId'] ?? ''}',
      venueName: json['venueName'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    );
  }
}

class LocationService {
  LocationService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<ProgramLocation> findLocation({
    String? programId,
    String? venueName,
    String? address,
  }) async {
    if (programId != null && programId.isNotEmpty) {
      final response = await _client.get(ApiEndpoints.program(programId));
      return ProgramLocation.fromJson(
        response['data'] as Map<String, dynamic>? ?? const {},
      );
    }

    final response = await _client.get(
      ApiEndpoints.programs,
      queryParameters: {
        'search': venueName?.isNotEmpty == true ? venueName : address,
        'page': 0,
        'size': 1,
      },
    );
    final page = ApiResponse.fromJson(
      response,
      (data) => PageResponse.fromJson(data, ProgramModel.fromJson),
    ).data;
    if (page.content.isEmpty) {
      return ProgramLocation(
        venueName: venueName ?? '',
        address: address ?? '',
        latitude: 0,
        longitude: 0,
      );
    }
    final program = page.content.first;
    return ProgramLocation(
      programId: program.id,
      venueName: program.locationName,
      address: program.location['address'] ?? '',
      latitude: double.tryParse(program.location['latitude'] ?? '') ?? 0,
      longitude: double.tryParse(program.location['longitude'] ?? '') ?? 0,
    );
  }
}
