class ReportPlace {
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
      place: ReportPlace(
        name:
            json['venueName'] as String? ??
            json['programName'] as String? ??
            '',
        address: json['address'] as String? ?? '',
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
      'address': place.address,
      'reason': reason,
    };
  }
}
