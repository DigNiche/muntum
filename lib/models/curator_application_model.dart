enum CuratorApplicationStatus { notApplied, pending, approved, rejected }

extension CuratorApplicationStatusX on CuratorApplicationStatus {
  String get label => switch (this) {
    CuratorApplicationStatus.notApplied => '',
    CuratorApplicationStatus.pending => '심사중',
    CuratorApplicationStatus.approved => '승인',
    CuratorApplicationStatus.rejected => '미승인',
  };

  static CuratorApplicationStatus fromApi(String? value) {
    return switch (value?.toUpperCase()) {
      'PENDING' => CuratorApplicationStatus.pending,
      'APPROVED' => CuratorApplicationStatus.approved,
      'REJECTED' => CuratorApplicationStatus.rejected,
      _ => CuratorApplicationStatus.notApplied,
    };
  }
}

class CuratorApplicationModel {
  const CuratorApplicationModel({
    required this.id,
    required this.status,
    required this.programName,
    required this.tagline,
    required this.curation,
    required this.createdAt,
    this.updatedAt,
    this.reviewedAt,
    this.applicant,
    this.rejectReason,
    this.rejectionReason,
  });

  final String id;
  final CuratorApplicationStatus status;
  final String programName;
  final String tagline;
  final String curation;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? reviewedAt;
  final CuratorApplicantModel? applicant;
  final String? rejectReason;
  final String? rejectionReason;

  bool get canEdit => status == CuratorApplicationStatus.pending;

  String get formattedCreatedAt {
    final date = createdAt;
    if (date == null) return '-';
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.'
        '${date.day.toString().padLeft(2, '0')}';
  }

  factory CuratorApplicationModel.fromJson(Map<String, dynamic> json) {
    final applicant = json['applicant'] is Map
        ? Map<String, dynamic>.from(json['applicant'] as Map)
        : null;
    final portfolio = json['portfolio'] is Map
        ? Map<String, dynamic>.from(json['portfolio'] as Map)
        : const <String, dynamic>{};
    final statusInfo = json['statusInfo'] is Map
        ? Map<String, dynamic>.from(json['statusInfo'] as Map)
        : const <String, dynamic>{};
    return CuratorApplicationModel(
      id: json['id']?.toString() ?? '',
      status: CuratorApplicationStatusX.fromApi(
        statusInfo['status']?.toString(),
      ),
      programName:
          portfolio['programName']?.toString() ??
          json['programName']?.toString() ??
          '',
      tagline:
          portfolio['tagline']?.toString() ?? json['tagline']?.toString() ?? '',
      curation:
          portfolio['curation']?.toString() ??
          json['curation']?.toString() ??
          '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
      reviewedAt: DateTime.tryParse(statusInfo['reviewedAt']?.toString() ?? ''),
      applicant: applicant == null
          ? null
          : CuratorApplicantModel.fromJson(applicant),
      rejectReason: statusInfo['rejectReason']?.toString(),
      rejectionReason: statusInfo['rejectReasonMessage']?.toString(),
    );
  }

  CuratorApplicationModel copyWithDetails(CuratorApplicationModel details) {
    return CuratorApplicationModel(
      id: id.isNotEmpty ? id : details.id,
      status: status == CuratorApplicationStatus.notApplied
          ? details.status
          : status,
      programName: details.programName,
      tagline: details.tagline,
      curation: details.curation,
      createdAt: createdAt ?? details.createdAt,
      updatedAt: updatedAt ?? details.updatedAt,
      reviewedAt: reviewedAt ?? details.reviewedAt,
      applicant: applicant ?? details.applicant,
      rejectReason: rejectReason ?? details.rejectReason,
      rejectionReason: rejectionReason ?? details.rejectionReason,
    );
  }
}

class CuratorApplicantModel {
  const CuratorApplicantModel({
    required this.userId,
    required this.email,
    required this.nickname,
    required this.profileImageUrl,
    required this.role,
    required this.status,
    required this.joinedAt,
  });

  final String userId;
  final String email;
  final String? nickname;
  final String? profileImageUrl;
  final String role;
  final String status;
  final DateTime? joinedAt;

  factory CuratorApplicantModel.fromJson(Map<String, dynamic> json) {
    final nickname = json['nickname']?.toString().trim();
    final profileImageUrl = json['profileImageUrl']?.toString().trim();
    return CuratorApplicantModel(
      userId: json['userId']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      nickname: nickname == null || nickname.isEmpty ? null : nickname,
      profileImageUrl: profileImageUrl == null || profileImageUrl.isEmpty
          ? null
          : profileImageUrl,
      role: json['role']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      joinedAt: DateTime.tryParse(json['joinedAt']?.toString() ?? ''),
    );
  }
}
