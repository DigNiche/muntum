import 'package:muntum/utils/image_url.dart';

class UserProfileModel {
  const UserProfileModel({
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

  final String userId;
  final String email;
  final String nickname;
  final String role;
  final int keywordCount;
  final int suggestionCount;
  final int scrapCount;
  final String? profileImageUrl;
  final DateTime? joinedAt;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      userId: json['userId']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      nickname: json['nickname']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      keywordCount: (json['keywordCount'] as num? ?? 0).toInt(),
      suggestionCount: (json['suggestionCount'] as num? ?? 0).toInt(),
      scrapCount: (json['scrapCount'] as num? ?? 0).toInt(),
      profileImageUrl: normalizeOptionalImageUrl(json['profileImageUrl']),
      joinedAt: DateTime.tryParse(json['joinedAt']?.toString() ?? ''),
    );
  }
}
