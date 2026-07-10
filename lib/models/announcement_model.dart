class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    this.createdAt,
    this.updatedAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: '${json['id'] ?? json['announcementId'] ?? ''}',
      title: json['title'] as String? ?? '',
      content: json['contents'] as String? ?? json['content'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }
}
