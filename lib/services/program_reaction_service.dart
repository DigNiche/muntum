import 'package:muntum/api/api_client.dart';
import 'package:muntum/api/api_endpoints.dart';
import 'package:muntum/api/api_response.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/models/program_reaction.dart';

class ProgramReactionService {
  ProgramReactionService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<ProgramReaction?> updateReaction({
    required String programId,
    required ProgramReaction? reaction,
  }) async {
    final response = await _client.put(
      ApiEndpoints.programReaction(programId),
      body: {'reactionState': reaction?.apiValue ?? 'NONE'},
      authorized: true,
    );
    return ApiResponse.fromJson(response, (data) {
      final map = data as Map<String, dynamic>? ?? const {};
      return programReactionFromJson(map['myReaction']);
    }).data;
  }

  Future<PageResponse<ProgramModel>> fetchMyPrograms({
    required ProgramReaction reaction,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.get(
      ApiEndpoints.myProgramReactions,
      queryParameters: {
        'reactionType': reaction.apiValue,
        'page': page,
        'size': size,
      },
      authorized: true,
    );
    return ApiResponse.fromJson(
      response,
      (data) => PageResponse.fromJson(data, ProgramModel.fromJson),
    ).data;
  }
}
