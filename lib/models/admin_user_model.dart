class AdminUserModel {
  final String userId;
  final String email;
  final String nickname;
  final String role;
  final int keywordCount;
  final int suggestionCount;
  final int scrapCount;
  final DateTime? joinedAt;

  const AdminUserModel({
    required this.userId,
    required this.email,
    required this.nickname,
    required this.role,
    required this.keywordCount,
    required this.suggestionCount,
    required this.scrapCount,
    required this.joinedAt,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      userId: json['userId']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      nickname: json['nickname']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      keywordCount: (json['keywordCount'] as num? ?? 0).toInt(),
      suggestionCount: (json['suggestionCount'] as num? ?? 0).toInt(),
      scrapCount: (json['scrapCount'] as num? ?? 0).toInt(),
      joinedAt: DateTime.tryParse(json['joinedAt']?.toString() ?? ''),
    );
  }

  String get displayName {
    if (nickname.trim().isNotEmpty) return nickname.trim();
    if (email.trim().isNotEmpty) return email.trim();
    return '사용자';
  }

  String get accountLabel =>
      role.toUpperCase() == 'MANAGER' ? '관리자 계정' : '가입 계정';

  String get formattedJoinedAt {
    final date = joinedAt;
    if (date == null) return '-';
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
