/// The four optional consent types supported by the users API.
const optionalTermTypes = {
  'MARKETING_PUSH',
  'MARKETING_EMAIL',
  'LOCATION_TERMS',
  'THIRD_PARTY_OFFER',
};

/// A published document returned by the active-terms API.
class TermDocument {
  /// Creates a server-versioned terms document.
  const TermDocument({
    required this.type,
    required this.version,
    required this.title,
    required this.content,
    required this.required,
  });

  /// The server's term type.
  final String type;

  /// The actual published version, never a client default.
  final String version;

  /// The document's display title.
  final String title;

  /// The server's Markdown document body.
  final String content;

  /// Whether the published document requires consent.
  final bool required;

  /// Whether users may change this optional consent.
  bool get isOptional => optionalTermTypes.contains(type);

  /// Whether this is a notice rather than a consent item.
  bool get isNotice => type == 'PRIVACY_POLICY';

  /// Parses a document without inventing a version or content.
  factory TermDocument.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? '';
    final version = json['version'] as String? ?? '';
    if (type.isEmpty || version.isEmpty || json['content'] is! String) {
      throw const FormatException('약관 정보를 확인할 수 없습니다.');
    }
    return TermDocument(
      type: type,
      version: version,
      title: json['title'] as String? ?? type,
      content: json['content'] as String,
      required: json['required'] == true,
    );
  }
}

/// A user's explicit decision for one published document.
class TermAgreement {
  /// Creates a consent decision; a grant requires the active version.
  const TermAgreement({required this.type, required this.agreed, this.version});

  /// The document's API type.
  final String type;

  /// Whether consent was explicitly granted.
  final bool agreed;

  /// The displayed version; optional only for a withdrawal.
  final String? version;

  /// Serializes the exact users and signup agreement field names.
  Map<String, dynamic> toJson() => {
    'termType': type,
    'agreed': agreed,
    if (version != null) 'version': version,
  };
}

/// The decisions made in the signup sheet, retained until account creation.
class SignupConsent {
  /// Creates a consent payload from explicit user decisions.
  SignupConsent(List<TermAgreement> agreements)
    : agreements = List.unmodifiable(agreements);

  /// The versioned decisions; privacy notices are never submitted.
  final List<TermAgreement> agreements;

  /// Validates the required service agreement and serializes the payload.
  Map<String, dynamic> toJson() {
    final seen = <String>{};
    for (final agreement in agreements) {
      if (!seen.add(agreement.type) ||
          (agreement.type != 'TERMS_OF_SERVICE' &&
              !optionalTermTypes.contains(agreement.type)) ||
          agreement.version?.isNotEmpty != true) {
        throw const FormatException('약관 동의 정보를 다시 확인해주세요.');
      }
    }
    if (!agreements.any(
      (agreement) => agreement.type == 'TERMS_OF_SERVICE' && agreement.agreed,
    )) {
      throw const FormatException('필수 약관에 동의해주세요.');
    }
    return {'agreements': agreements.map((item) => item.toJson()).toList()};
  }
}

/// The user's recorded optional consents and document versions.
class UserTermsState {
  /// Creates a snapshot from the authenticated users API.
  const UserTermsState({
    required this.optionalConsents,
    required this.agreementVersions,
    this.updatedAt,
  });

  /// Current optional consent flags; these are not available-document flags.
  final Map<String, bool> optionalConsents;

  /// The last recorded versions, which may omit some optional documents.
  final Map<String, String> agreementVersions;

  /// The server's last consent update time, if present.
  final DateTime? updatedAt;

  /// Parses the recorded state without creating a missing consent record.
  factory UserTermsState.fromJson(Map<String, dynamic> json) {
    if (json['optionalConsents'] is! Map) {
      throw const FormatException('약관 동의 정보를 확인할 수 없습니다.');
    }
    return UserTermsState(
      optionalConsents: Map<String, bool>.from(json['optionalConsents'] as Map),
      agreementVersions: Map<String, String>.from(
        json['agreementVersions'] as Map? ?? const {},
      ),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }
}
