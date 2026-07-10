class ApiResponse<T> {
  final int? status;
  final String message;
  final T data;

  const ApiResponse({required this.message, required this.data, this.status});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) parseData,
  ) {
    return ApiResponse<T>(
      status: json['status'] as int?,
      message: json['message'] as String? ?? '',
      data: parseData(json['data']),
    );
  }
}

class PageResponse<T> {
  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool first;
  final bool last;
  final bool hasPrevious;
  final bool hasNext;

  const PageResponse({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.first,
    required this.last,
    required this.hasPrevious,
    required this.hasNext,
  });

  factory PageResponse.fromList(List<T> content) {
    return PageResponse<T>(
      content: content,
      page: 0,
      size: content.length,
      totalElements: content.length,
      totalPages: content.isEmpty ? 0 : 1,
      first: true,
      last: true,
      hasPrevious: false,
      hasNext: false,
    );
  }

  factory PageResponse.fromJson(
    Object? json,
    T Function(Map<String, dynamic> json) parseItem,
  ) {
    if (json is List) {
      return PageResponse.fromList(
        json
            .whereType<Map>()
            .map((item) => parseItem(Map<String, dynamic>.from(item)))
            .toList(),
      );
    }
    final map = json as Map<String, dynamic>? ?? const {};
    return PageResponse<T>(
      content: ((map['content'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => parseItem(Map<String, dynamic>.from(item)))
          .toList(),
      page: (map['page'] as num? ?? map['number'] as num? ?? 0).toInt(),
      size: (map['size'] as num? ?? 0).toInt(),
      totalElements: (map['totalElements'] as num? ?? 0).toInt(),
      totalPages: (map['totalPages'] as num? ?? 0).toInt(),
      first: map['first'] as bool? ?? true,
      last: map['last'] as bool? ?? true,
      hasPrevious: map['hasPrevious'] as bool? ?? false,
      hasNext: map['hasNext'] as bool? ?? false,
    );
  }
}
