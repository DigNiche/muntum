import 'package:muntum/models/curation_model.dart';
import 'package:muntum/utils/image_url.dart';

class AdminCuratorModel {
  const AdminCuratorModel({
    required this.id,
    required this.nickname,
    this.profileImageUrl,
    this.role = 'CURATOR',
  });

  final String id;
  final String nickname;
  final String? profileImageUrl;
  final String role;

  factory AdminCuratorModel.fromJson(Map<String, dynamic> json) {
    return AdminCuratorModel(
      id: json['curatorId']?.toString() ?? '',
      nickname: json['nickname']?.toString() ?? '익명의 큐레이터',
      role: json['role']?.toString() ?? 'CURATOR',
      profileImageUrl: normalizeOptionalImageUrl(json['profileImageUrl']),
    );
  }
}

class AdminCurationModel {
  const AdminCurationModel({required this.curation, required this.curator});

  final CurationModel curation;
  final AdminCuratorModel curator;

  factory AdminCurationModel.fromJson(Map<String, dynamic> json) {
    return AdminCurationModel(
      curation: CurationModel.fromJson(json),
      curator: AdminCuratorModel.fromJson(
        Map<String, dynamic>.from(json['curator'] as Map? ?? const {}),
      ),
    );
  }
}
