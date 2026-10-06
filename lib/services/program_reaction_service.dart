import 'package:muntum/api/api_client.dart';
import 'package:muntum/api/api_endpoints.dart';
import 'package:muntum/api/api_response.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/models/program_reaction.dart';

class ProgramReactionService {
  ProgramReactionService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<ProgramReactionRecord> updateReaction({
    required String programId,
    required ProgramReaction? reaction,
    String? comment,
  }) async {
    final response = await _client.put(
      ApiEndpoints.programReaction(programId),
      body: {
        'reactionState': reaction?.apiValue ?? 'NONE',
        if (reaction != null && comment != null) 'comment': comment,
      },
      authorized: true,
    );
    return ApiResponse.fromJson(response, ProgramReactionRecord.fromJson).data;
  }

  Future<ProgramReactionSummary> fetchMyRecord(String programId) async {
    final response = await _client.get(
      ApiEndpoints.program(programId),
      authorized: true,
    );
    return ApiResponse.fromJson(response, (data) {
      if (data is! Map) return const ProgramReactionSummary();
      return ProgramReactionSummary.fromJson(data['reaction']);
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
