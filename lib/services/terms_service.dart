import 'package:muntum/api/api_client.dart';
import 'package:muntum/api/api_endpoints.dart';
import 'package:muntum/api/api_exception.dart';
import 'package:muntum/models/terms_model.dart';

/// Loads published terms and updates only explicitly selected optional consents.
class TermsService {
  /// Creates the terms service with an injectable client for verification.
  TermsService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// Loads current published documents without attaching a login token.
  Future<List<TermDocument>> fetchActive() async {
    final response = await _client.get(ApiEndpoints.activeTerms);
    final data = response['data'];
    if (data is! List) {
      throw const FormatException('게시된 약관을 확인할 수 없습니다.');
    }
    final documents = data.map((item) {
      return TermDocument.fromJson(Map<String, dynamic>.from(item as Map));
    }).toList();
    final types = <String>{};
    for (final document in documents) {
      if (!types.add(document.type)) {
        throw const FormatException('게시된 약관이 중복되었습니다.');
      }
    }
    return documents;
  }

  /// Requires published service terms before presenting a signup decision.
  Future<List<TermDocument>> fetchSignupTerms() async {
    final documents = await fetchActive();
    if (!documents.any((term) => term.type == 'TERMS_OF_SERVICE') ||
        documents.any(
          (term) =>
              term.required &&
              term.type != 'TERMS_OF_SERVICE' &&
              !term.isOptional &&
              !term.isNotice,
        )) {
      throw const ApiException(
        code: 'T005',
        message: '회원가입에 필요한 게시 약관을 확인할 수 없습니다.',
      );
    }
    return documents;
  }

  /// Loads the authenticated user's recorded state; T001 remains an error.
  Future<UserTermsState> fetchMyConsents() async {
    final response = await _client.get(
      ApiEndpoints.termsConsent,
      authorized: true,
    );
    return UserTermsState.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }

  /// Updates optional decisions and reads back the server's confirmed state.
  ///
  /// Revocation needs no current document or version; new grants do.
  Future<UserTermsState> updateOptional(List<TermAgreement> changes) async {
    final types = <String>{};
    if (changes.isEmpty ||
        changes.any(
          (change) =>
              !optionalTermTypes.contains(change.type) ||
              !types.add(change.type) ||
              (change.agreed && change.version?.isNotEmpty != true),
        )) {
      throw const FormatException('선택 약관 변경 정보를 확인해주세요.');
    }
    await _client.patch(
      ApiEndpoints.termsConsent,
      authorized: true,
      body: {'terms': changes.map((change) => change.toJson()).toList()},
    );
    return fetchMyConsents();
  }
}
