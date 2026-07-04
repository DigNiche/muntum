import 'package:flutter/material.dart';

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
  final bool isBookmark;

  ProgramModel({
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
  });
}
