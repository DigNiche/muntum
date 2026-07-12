class ReportPlace {
  static const String _encodedSeparator = '\n';

  final String name;
  final String address;
  final double? latitude;
  final double? longitude;

  const ReportPlace({
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
  });

  factory ReportPlace.fromSuggestionAddress({
    String? venueName,
    String? placeName,
    required String address,
  }) {
    final explicitName =
        (venueName?.trim().isNotEmpty == true ? venueName : placeName)?.trim();
    final parsed = _parseEncodedAddress(address);
    final parsedName = parsed.$1;
    final parsedAddress = parsed.$2;

    return ReportPlace(
      name: explicitName?.isNotEmpty == true
          ? explicitName!
          : parsedName.isNotEmpty
          ? parsedName
          : parsedAddress,
      address: parsedAddress,
    );
  }

  String toSuggestionAddress() {
    final trimmedName = name.trim();
    final trimmedAddress = address.trim();
    if (trimmedName.isEmpty || trimmedName == trimmedAddress) {
      return trimmedAddress;
    }
    return '$trimmedName$_encodedSeparator$trimmedAddress';
  }

  static (String, String) _parseEncodedAddress(String value) {
    final trimmed = value.trim();
    final lines = trimmed
        .split(_encodedSeparator)
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.length >= 2) {
      return (lines.first, lines.skip(1).join(' '));
    }
    return ('', trimmed);
  }
}

class ReportModel {
  final String id;
  final String? informerId;
  final String? informerNickname;
  final String? reviewedById;
  final String? reviewedByNickname;
  final DateTime? reviewedAt;
  final String programName;
  final String reason;
  final ReportPlace place;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ReportModel({
    required this.id,
    this.informerId,
    this.informerNickname,
    this.reviewedById,
    this.reviewedByNickname,
    this.reviewedAt,
    required this.programName,
    required this.reason,
    required this.place,
    this.status = 'PENDING',
    required this.createdAt,
    this.updatedAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: '${json['id'] ?? ''}',
      informerId: json['informerId'] as String?,
      informerNickname: json['informerNickname'] as String?,
      reviewedById: json['reviewedById'] as String?,
      reviewedByNickname: json['reviewedByNickname'] as String?,
      reviewedAt: DateTime.tryParse(json['reviewedAt'] as String? ?? ''),
      programName: json['programName'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      place: ReportPlace.fromSuggestionAddress(
        venueName: json['venueName'] as String?,
        placeName: json['placeName'] as String?,
        address:
            (json['address'] as String?) ??
            (json['programAddress'] as String?) ??
            (json['venueAddress'] as String?) ??
            '',
      ),
      status: json['status'] as String? ?? 'PENDING',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'programName': programName,
      'address': place.toSuggestionAddress(),
      'reason': reason,
    };
  }
}
