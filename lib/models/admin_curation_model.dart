import 'package:muntum/models/curation_model.dart';

class AdminCuratorModel {
  const AdminCuratorModel({
    required this.id,
    required this.nickname,
    this.profileImageUrl,
  });

  final String id;
  final String nickname;
  final String? profileImageUrl;

  factory AdminCuratorModel.fromJson(Map<String, dynamic> json) {
    final imageUrl = json['profileImageUrl']?.toString().trim();
    return AdminCuratorModel(
      id: json['curatorId']?.toString() ?? '',
      nickname: json['nickname']?.toString() ?? '익명의 큐레이터',
      profileImageUrl: imageUrl == null || imageUrl.isEmpty ? null : imageUrl,
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
