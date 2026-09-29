class AdminUserModel {
  final String userId;
  final String email;
  final String nickname;
  final String role;
  final int keywordCount;
  final int suggestionCount;
  final int scrapCount;
  final String? profileImageUrl;
  final DateTime? joinedAt;

  const AdminUserModel({
    required this.userId,
    required this.email,
    required this.nickname,
    required this.role,
    required this.keywordCount,
    required this.suggestionCount,
    required this.scrapCount,
    required this.profileImageUrl,
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
      profileImageUrl: _nullableUrl(json['profileImageUrl']),
      joinedAt: DateTime.tryParse(json['joinedAt']?.toString() ?? ''),
    );
  }

  static String? _nullableUrl(Object? value) {
    final url = value?.toString().trim();
    return url == null || url.isEmpty ? null : url;
  }

  String get displayName {
    if (nickname.trim().isNotEmpty) return nickname.trim();
    if (email.trim().isNotEmpty) return email.trim();
    return '사용자';
  }

  bool get isCurator => role.toUpperCase() == 'CURATOR';

  bool get isManager => role.toUpperCase() == 'MANAGER';

  String get accountLabel => '가입한 계정';

  String get formattedJoinedAt {
    final date = joinedAt;
    if (date == null) return '-';
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}.$month.$day';
  }
}
