import 'package:muntum/models/report_model.dart';

final List<ReportPlace> mockReportPlaces = [
  const ReportPlace(
    name: '용산역사박물관',
    address: '서울 용산구 한강대로14길 35-29',
    latitude: 37.5244,
    longitude: 126.9647,
  ),
  const ReportPlace(
    name: '용산역사거리',
    address: '서울 용산구 한강로2가',
    latitude: 37.5296,
    longitude: 126.9645,
  ),
  const ReportPlace(
    name: '용산역사문화사회적협동조합',
    address: '서울 용산구 신흥로36길 42',
    latitude: 37.5452,
    longitude: 126.9847,
  ),
  const ReportPlace(
    name: '용산역',
    address: '서울 용산구 한강대로23길 55',
    latitude: 37.5298,
    longitude: 126.9648,
  ),
  const ReportPlace(
    name: '용산공예관',
    address: '서울 용산구 이태원로 274',
    latitude: 37.5373,
    longitude: 126.9991,
  ),
  const ReportPlace(
    name: '용산청년지음',
    address: '서울 용산구 서빙고로 17',
    latitude: 37.5265,
    longitude: 126.9657,
  ),
  const ReportPlace(
    name: '남산박물관',
    address: '서울 중구 소파로 46',
    latitude: 37.5511,
    longitude: 126.9882,
  ),
  const ReportPlace(
    name: '남산골한옥마을',
    address: '서울 중구 퇴계로34길 28',
    latitude: 37.5593,
    longitude: 126.9945,
  ),
  const ReportPlace(
    name: '문틈박물관',
    address: '강원특별자치도 원주시 중앙로 89',
    latitude: 37.3481,
    longitude: 127.9472,
  ),
  const ReportPlace(
    name: '원주문화원',
    address: '강원특별자치도 원주시 무실로 235',
    latitude: 37.3422,
    longitude: 127.9202,
  ),
  const ReportPlace(
    name: '무실예술창고',
    address: '강원특별자치도 원주시 능라동길 51',
    latitude: 37.34225,
    longitude: 127.92025,
  ),
  const ReportPlace(
    name: '원주문화의거리',
    address: '강원특별자치도 원주시 중앙로 89',
    latitude: 37.3481,
    longitude: 127.9472,
  ),
];

final List<ReportModel> mockReports = [
  ReportModel(
    id: 'report_1',
    programName: '7월 청음회',
    reason: '조용한 전시 공간에서 작은 공연이 열리고 있어 문틈에 꼭 알려주고 싶었어요.',
    place: mockReportPlaces[0],
    createdAt: DateTime(2026, 7, 1),
  ),
  ReportModel(
    id: 'report_2',
    programName: '골목 사진 산책',
    reason: '동네 골목을 함께 걸으며 사진을 찍는 프로그램입니다.',
    place: const ReportPlace(name: '원주문화의거리', address: '강원특별자치도 원주시 중앙로 89'),
    createdAt: DateTime(2026, 7, 2),
  ),
  ReportModel(
    id: 'report_3',
    programName: '작은 공방 오픈클래스',
    reason: '예약 없이 들러볼 수 있는 공예 체험이 진행 중입니다.',
    place: const ReportPlace(name: '무실예술창고', address: '강원특별자치도 원주시 능라동길 51'),
    createdAt: DateTime(2026, 7, 3),
  ),
];

void addMockReport(ReportModel report) {
  mockReports.insert(0, report);
}
