import 'package:muntum/api/api_config.dart';

/// Public program curation responses intentionally exclude review state.
class PublicCurationModel {
  const PublicCurationModel({
    required this.id,
    required this.programId,
    this.curatorId,
    required this.curatorName,
    required this.curatorImageUrl,
    required this.tagline,
    required this.thumbnailUrl,
    required this.content,
    required this.images,
    this.createdAt,
  });

  final String id;
  final String programId;
  final String? curatorId;
  final String curatorName;
  final String? curatorImageUrl;
  final String tagline;
  final String? thumbnailUrl;
  final String content;
  final List<CurationImageModel> images;
  final DateTime? createdAt;

  String get formattedCreatedAt {
    final date = createdAt;
    if (date == null) return '';
    return '${date.year.toString().substring(2)}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.day.toString().padLeft(2, '0')}';
  }

  PublicCurationModel mergeDetails(PublicCurationModel details) =>
      PublicCurationModel(
        id: id,
        programId: details.programId.isEmpty ? programId : details.programId,
        curatorId: details.curatorId ?? curatorId,
        curatorName: details.curatorName == '큐레이터'
            ? curatorName
            : details.curatorName,
        curatorImageUrl: details.curatorImageUrl ?? curatorImageUrl,
        tagline: details.tagline.isEmpty ? tagline : details.tagline,
        thumbnailUrl:
            thumbnailUrl ??
            (details.images.isEmpty ? null : details.images.first.imageUrl),
        content: details.content,
        images: details.images,
        createdAt: details.createdAt ?? createdAt,
      );

  factory PublicCurationModel.fromJson(Map<String, dynamic> json) {
    final curator = json['curator'] as Map<String, dynamic>? ?? const {};
    String? imageUrl(Object? value) {
      final raw = value?.toString().trim() ?? '';
      return raw.isEmpty ? null : CurationImageModel.normalizeImageUrl(raw);
    }

    final images =
        ((json['images'] as List?) ?? const [])
            .whereType<Map>()
            .map(
              (item) =>
                  CurationImageModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList()
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return PublicCurationModel(
      id: json['id']?.toString() ?? '',
      programId: json['programId']?.toString() ?? '',
      curatorId: curator['curatorId']?.toString(),
      curatorName: curator['nickname']?.toString() ?? '큐레이터',
      curatorImageUrl: imageUrl(curator['profileImageUrl']),
      tagline: json['tagline']?.toString() ?? '',
      thumbnailUrl: imageUrl(json['thumbnailUrl']),
      content: json['content']?.toString() ?? '',
      images: images,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}

enum CurationStatus { pending, approved, changesRequested, unknown }

extension CurationStatusX on CurationStatus {
  static CurationStatus fromApi(String? value) => switch (value) {
    'PENDING' => CurationStatus.pending,
    'APPROVED' => CurationStatus.approved,
    'CHANGES_REQUESTED' => CurationStatus.changesRequested,
    _ => CurationStatus.unknown,
  };

  String get label => switch (this) {
    CurationStatus.pending => '심사중',
    CurationStatus.approved => '승인',
    CurationStatus.changesRequested => '수정요청',
    CurationStatus.unknown => '',
  };
}

class CurationImageModel {
  const CurationImageModel({
    required this.id,
    required this.imageUrl,
    required this.displayOrder,
  });

  final String id;
  final String imageUrl;
  final int displayOrder;

  factory CurationImageModel.fromJson(Map<String, dynamic> json) {
    return CurationImageModel(
      id: json['id']?.toString() ?? '',
      imageUrl: normalizeImageUrl(json['imageUrl']?.toString() ?? ''),
      displayOrder: (json['displayOrder'] as num? ?? 0).toInt(),
    );
  }

  static String normalizeImageUrl(String rawUrl) {
    final url = rawUrl.trim();
    if (url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('//')) return 'https:$url';
    if (url.startsWith('/')) return '${ApiConfig.baseUrl}$url';
    if (RegExp(r'^[\w-]+(?:\.[\w-]+)+(?:\:\d+)?(?:/|$)').hasMatch(url)) {
      return 'https://$url';
    }
    return '${ApiConfig.baseUrl}/$url';
  }
}

class CurationModel {
  const CurationModel({
    required this.id,
    required this.programId,
    required this.programTitle,
    required this.place,
    required this.tagline,
    required this.content,
    required this.images,
    required this.status,
    required this.publicationStatus,
    required this.changeRequestReason,
    required this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? programId;
  final String programTitle;
  final String place;
  final String tagline;
  final String content;
  final List<CurationImageModel> images;
  final CurationStatus status;
  final String publicationStatus;
  final String? changeRequestReason;
  final DateTime? reviewedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // The resubmit API keeps the previous reason after moving back to PENDING.
  // This distinguishes a revised submission from a first-time submission.
  bool get isRevisedPending =>
      status == CurationStatus.pending &&
      changeRequestReason != null &&
      changeRequestReason!.isNotEmpty;

  String get formattedCreatedAt {
    final date = createdAt;
    if (date == null) return '-';
    return '${date.year.toString().substring(2)}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.day.toString().padLeft(2, '0')}';
  }

  factory CurationModel.fromJson(Map<String, dynamic> json) {
    final images =
        ((json['images'] as List?) ?? const [])
            .whereType<Map>()
            .map(
              (image) =>
                  CurationImageModel.fromJson(Map<String, dynamic>.from(image)),
            )
            .toList()
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    final reason = json['changeRequestReason']?.toString().trim();
    return CurationModel(
      id: json['id']?.toString() ?? '',
      programId: json['programId']?.toString(),
      programTitle: json['submittedProgramTitle']?.toString() ?? '',
      place: json['submittedPlace']?.toString() ?? '',
      tagline: json['tagline']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      images: images,
      status: CurationStatusX.fromApi(json['status']?.toString()),
      publicationStatus: json['publicationStatus']?.toString() ?? '',
      changeRequestReason: reason == null || reason.isEmpty ? null : reason,
      reviewedAt: DateTime.tryParse(json['reviewedAt']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  CurationModel mergeDetails(CurationModel details) {
    return CurationModel(
      id: id,
      programId: details.programId ?? programId,
      programTitle: details.programTitle.isEmpty
          ? programTitle
          : details.programTitle,
      place: details.place.isEmpty ? place : details.place,
      tagline: details.tagline.isEmpty ? tagline : details.tagline,
      content: details.content,
      images: details.images,
      status: details.status == CurationStatus.unknown
          ? status
          : details.status,
      publicationStatus: details.publicationStatus.isEmpty
          ? publicationStatus
          : details.publicationStatus,
      changeRequestReason: details.changeRequestReason,
      reviewedAt: details.reviewedAt ?? reviewedAt,
      createdAt: details.createdAt ?? createdAt,
      updatedAt: details.updatedAt ?? updatedAt,
    );
  }
}

class CuratorProfileModel {
  const CuratorProfileModel({
    required this.curatorId,
    required this.nickname,
    required this.profileImageUrl,
    required this.approvedCount,
    required this.pendingCount,
    required this.changesRequestedCount,
  });

  final String curatorId;
  final String nickname;
  final String? profileImageUrl;
  final int approvedCount;
  final int pendingCount;
  final int changesRequestedCount;

  int get totalCount => approvedCount + pendingCount + changesRequestedCount;

  factory CuratorProfileModel.fromJson(Map<String, dynamic> json) {
    final imageUrl = json['profileImageUrl']?.toString().trim();
    return CuratorProfileModel(
      curatorId: json['curatorId']?.toString() ?? '',
      nickname: json['nickname']?.toString() ?? '',
      profileImageUrl: imageUrl == null || imageUrl.isEmpty ? null : imageUrl,
      approvedCount: (json['approvedCount'] as num? ?? 0).toInt(),
      pendingCount: (json['pendingCount'] as num? ?? 0).toInt(),
      changesRequestedCount: (json['changesRequestedCount'] as num? ?? 0)
          .toInt(),
    );
  }
}
