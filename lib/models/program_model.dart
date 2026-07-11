import 'package:flutter/material.dart';
import 'package:muntum/models/keyword_model.dart';

enum Filter {
  nowHot,
  free,
  thisWeek,
  noReservation,
  exhibition,
  show,
  experience,
  festival,
}

class ProgramModel {
  final String id;
  final String? programType;
  // 제목
  final String title;
  // 한줄소개
  final String oneLineDescription;
  // 상세내용
  final String detail;
  // 사진
  final List<Image> images;
  // keywords
  final List<String> keywords;
  // 날짜
  final String startEndDates;
  // 장소명
  final String locationName;
  // 장소 (위도경도)
  final Map<String, String> location;
  // 시간
  final String availableTime;
  // 가격
  final String cost;
  // 사전예약
  final bool isReservationNeeded;
  // 전화번호
  final String phoneNumber;
  // 링크
  final String link;
  // 필터링
  final List<Filter> filters;
  // 지금 주목받는지
  final bool isSpotlight;
  // 이번달에 끝나는지
  final bool isOverThisMonth;
  // 스크랩
  bool isBookmark;
  final bool ended;
  final int viewCount;
  final String? officialUrl;
  final List<String> imageUrls;
  final List<KeywordModel> keywordModels;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String startDate;
  final String endDate;

  ProgramModel({
    this.id = '',
    this.programType,
    required this.title,
    required this.oneLineDescription,
    required this.detail,
    required this.images,
    required this.keywords,
    required this.startEndDates,
    required this.locationName,
    required this.location,
    required this.availableTime,
    required this.cost,
    required this.isReservationNeeded,
    required this.phoneNumber,
    required this.link,
    required this.filters,
    required this.isSpotlight,
    required this.isOverThisMonth,
    required this.isBookmark,
    this.ended = false,
    this.viewCount = 0,
    this.officialUrl,
    this.imageUrls = const [],
    this.keywordModels = const [],
    this.createdAt,
    this.updatedAt,
    this.startDate = '',
    this.endDate = '',
  });

  factory ProgramModel.fromJson(Map<String, dynamic> json) {
    final imageUrls = _parseImageUrls(json);
    final keywordModels = ((json['keywords'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => KeywordModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    final programType = json['programType'] as String?;
    final free = json['free'] as bool? ?? false;
    final reserved = json['reserved'] as bool? ?? false;
    final ended =
        json['ended'] as bool? ?? _isEnded(json['endDate'] as String?);
    final startDate =
        json['startDate'] as String? ?? json['startTime'] as String? ?? '';
    final endDate =
        json['endDate'] as String? ?? json['endTime'] as String? ?? '';

    return ProgramModel(
      id: '${json['id'] ?? ''}',
      programType: programType,
      title: json['title'] as String? ?? '',
      oneLineDescription:
          json['tagline'] as String? ??
          json['oneLineDescription'] as String? ??
          '',
      detail: json['curation'] as String? ?? json['detail'] as String? ?? '',
      images: imageUrls
          .map((url) => Image.network(url, fit: BoxFit.cover))
          .toList(),
      imageUrls: imageUrls,
      keywords: keywordModels.map((keyword) => keyword.name).toList(),
      keywordModels: keywordModels,
      startEndDates: _formatDateRange(startDate, endDate, compactYear: true),
      startDate: startDate,
      endDate: endDate,
      locationName: json['venueName'] as String? ?? '',
      location: {
        'address': json['address'] as String? ?? '',
        'latitude': '${json['latitude'] ?? ''}',
        'longitude': '${json['longitude'] ?? ''}',
      },
      availableTime: json['operatingHours'] as String? ?? '',
      cost: json['price'] as String? ?? (free ? '무료' : ''),
      isReservationNeeded: reserved,
      phoneNumber: json['inquiryContact'] as String? ?? '',
      link: json['officialUrl'] as String? ?? '',
      filters: _filtersFromApi(
        programType: programType,
        free: free,
        reserved: reserved,
      ),
      isSpotlight: false,
      isOverThisMonth: _isOverThisMonth(endDate),
      isBookmark: json['scrapped'] as bool? ?? json['saved'] as bool? ?? false,
      ended: ended,
      viewCount: json['viewCount'] as int? ?? 0,
      officialUrl: json['officialUrl'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }

  static List<String> _parseImageUrls(Map<String, dynamic> json) {
    final thumbnailUrl = json['thumbnailUrl'] as String?;
    final images = ((json['images'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => item['imageUrl'] as String?)
        .whereType<String>()
        .where((url) => url.isNotEmpty)
        .map(_normalizeImageUrl)
        .toList();
    if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
      final normalizedThumbnail = _normalizeImageUrl(thumbnailUrl);
      return [
        normalizedThumbnail,
        ...images.where((url) => url != normalizedThumbnail),
      ];
    }
    return images;
  }

  static String _normalizeImageUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return 'https://$trimmed';
  }

  static List<Filter> _filtersFromApi({
    required String? programType,
    required bool free,
    required bool reserved,
  }) {
    final filters = <Filter>[];
    if (free) filters.add(Filter.free);
    if (!reserved) filters.add(Filter.noReservation);
    switch (programType) {
      case 'EXHIBITION':
        filters.add(Filter.exhibition);
      case 'PERFORMANCE':
        filters.add(Filter.show);
      case 'CLASS_EXPERIENCE':
        filters.add(Filter.experience);
      case 'FAIR':
        filters.add(Filter.festival);
    }
    return filters;
  }

  static bool _isEnded(String? endDate) {
    final parsed = DateTime.tryParse(endDate ?? '');
    if (parsed == null) return false;
    final now = DateTime.now();
    return DateTime(
      parsed.year,
      parsed.month,
      parsed.day,
    ).isBefore(DateTime(now.year, now.month, now.day));
  }

  static bool _isOverThisMonth(String? endDate) {
    final parsed = DateTime.tryParse(endDate ?? '');
    if (parsed == null) return false;
    final now = DateTime.now();
    return parsed.year == now.year && parsed.month == now.month;
  }

  String get cardDateText {
    final formatted = _formatDateRange(startDate, endDate, compactYear: true);
    if (formatted.isNotEmpty) return formatted;
    return _formatStoredDateRange(startEndDates, compactYear: true);
  }

  String get detailDateText {
    final formatted = _formatDateRange(startDate, endDate, compactYear: false);
    if (formatted.isNotEmpty) return formatted;
    return _formatStoredDateRange(startEndDates, compactYear: false);
  }

  static String _formatStoredDateRange(
    String value, {
    required bool compactYear,
  }) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';

    final parts = trimmed
        .split(RegExp(r'\s*-\s*'))
        .map((part) => part.trim())
        .toList();
    if (parts.length >= 2) {
      return _formatDateRange(
        parts[0],
        parts.sublist(1).join('-'),
        compactYear: compactYear,
      );
    }

    final date = _formatSingleDate(trimmed, compactYear: compactYear);
    return date.isEmpty ? trimmed : date;
  }

  static String _formatDateRange(
    String start,
    String end, {
    required bool compactYear,
  }) {
    final formattedStart = _formatSingleDate(start, compactYear: compactYear);
    final formattedEnd = _formatSingleDate(end, compactYear: compactYear);

    if (formattedStart.isEmpty && formattedEnd.isEmpty) return '';
    if (formattedStart.isEmpty) return formattedEnd;
    if (formattedEnd.isEmpty) {
      return compactYear ? '$formattedStart-상시' : '$formattedStart - 상시';
    }
    return compactYear
        ? '$formattedStart-$formattedEnd'
        : '$formattedStart - $formattedEnd';
  }

  static String _formatSingleDate(String value, {required bool compactYear}) {
    final parsed = _parseDate(value);
    if (parsed == null) return '';
    final year = compactYear
        ? (parsed.year % 100).toString().padLeft(2, '0')
        : parsed.year.toString().padLeft(4, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    return '$year.$month.$day';
  }

  static DateTime? _parseDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == '상시') return null;

    final normalized = trimmed
        .replaceAll('.', '-')
        .replaceAll('/', '-')
        .split(RegExp(r'\s+'))
        .first;
    final directParsed = DateTime.tryParse(normalized);
    if (directParsed != null) return directParsed;

    final match = RegExp(
      r'^(\d{2,4})-(\d{1,2})-(\d{1,2})$',
    ).firstMatch(normalized);
    if (match == null) return null;
    var year = int.tryParse(match.group(1) ?? '');
    final month = int.tryParse(match.group(2) ?? '');
    final day = int.tryParse(match.group(3) ?? '');
    if (year == null || month == null || day == null) return null;
    if (year < 100) year += 2000;
    return DateTime(year, month, day);
  }
}
