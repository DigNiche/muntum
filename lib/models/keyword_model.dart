class KeywordModel {
  final String id;
  final String name;
  final String? type;
  final String? category;
  final String? description;
  final bool active;

  const KeywordModel({
    required this.id,
    required this.name,
    this.type,
    this.category,
    this.description,
    this.active = true,
  });

  factory KeywordModel.fromJson(Map<String, dynamic> json) {
    return KeywordModel(
      id: '${json['id'] ?? ''}',
      name: json['name'] as String? ?? '',
      type: json['type'] as String?,
      category: json['category'] as String? ?? json['categories'] as String?,
      description: json['description'] as String?,
      active: json['active'] as bool? ?? true,
    );
  }
}

class TasteKeywordResult {
  final List<KeywordModel> selectedKeywords;

  const TasteKeywordResult({required this.selectedKeywords});

  factory TasteKeywordResult.fromJson(Object? json) {
    final map = json as Map<String, dynamic>? ?? const {};
    return TasteKeywordResult(
      selectedKeywords: ((map['selectedKeywords'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => KeywordModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}
