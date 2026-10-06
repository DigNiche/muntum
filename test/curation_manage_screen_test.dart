import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/api/api_response.dart';
import 'package:muntum/models/admin_curation_model.dart';
import 'package:muntum/models/curation_model.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/models/report_model.dart';
import 'package:muntum/screens/mypage/manager/curation_manage_screen.dart';
import 'package:muntum/screens/mypage/manager/curation_review_screen.dart';
import 'package:muntum/screens/mypage/manager/program_edit_screen.dart';
import 'package:muntum/services/admin_curation_service.dart';
import 'package:muntum/services/program_service.dart';

void main() {
  testWidgets('manager can open a pending curation and inspect its details', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = _FakeService();
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (_, _) =>
            MaterialApp(home: CurationManageScreen(service: service)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('대기 1'), findsOneWidget);
    expect(find.text('수정 요청 0'), findsOneWidget);
    expect(find.text('프로그램명'), findsWidgets);
    await tester.tap(find.text('확인하기'));
    await tester.pumpAndSettle();
    expect(find.byType(CurationReviewScreen), findsOneWidget);
    expect(find.text('소개글'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('new program approval calls the dedicated endpoint once', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = _FakeService();
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (_, _) => MaterialApp(
          home: ProgramEditScreen(
            approvalCuration: service.item,
            adminCurationService: service,
            initialReport: ReportModel(
              id: 'report',
              programName: '프로그램명',
              reason: '소개글',
              place: const ReportPlace(name: '장소', address: '서울시 종로구 1'),
              createdAt: DateTime(2026),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('큐레이션'), findsOneWidget);
    await tester.tap(find.text('작성하기').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('작성완료'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('작성하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('작성완료'));
    await tester.pumpAndSettle();
    expect(find.text('작성완료'), findsOneWidget);
    expect(service.approvalCalls, 0);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    final startDateField = find
        .byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.hintText == '예: 2026.07.14',
        )
        .first;
    await tester.ensureVisible(startDateField);
    await tester.enterText(startDateField, '2026.10.05');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('작성완료'));
    await tester.tap(find.text('작성완료'));
    await tester.pumpAndSettle();
    expect(find.text('작성완료'), findsOneWidget);
    expect(service.approvalCalls, 0);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    final hoursField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText == '예: 월-목 11:00~20:00',
    );
    await tester.ensureVisible(hoursField);
    await tester.enterText(hoursField, '월-목 11:00~20:00');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('사전예약'));
    await tester.tap(find.text('사전예약'));
    await tester.pumpAndSettle();
    final reservationField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.hintText == '링크를 첨부해주세요.',
    );
    await tester.ensureVisible(reservationField);
    await tester.enterText(reservationField, 'https://example.com/book');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('작성완료'));
    await tester.tap(find.text('작성완료'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('등록하기'));
    await tester.tap(find.text('등록하기'));
    await tester.pumpAndSettle();

    expect(service.approvalCalls, 1);
    expect(service.lastProgram?['description'], '소개글');
    expect(service.lastProgram?['operatingHours'], '월-목 11:00~20:00');
    expect(service.lastProgram?['operatingPeriodMeta'], '2026.10.05');
    expect(service.lastProgram?['operatingPeriod'], isNull);
    expect(service.lastProgram?['reserved'], isTrue);
    expect(service.lastProgram?['reservationType'], 'PRE_REGISTRATION');
    expect(service.lastProgram?['reservationUrl'], 'https://example.com/book');
    expect(service.lastProgram?.containsKey('curation'), isFalse);
  });

  testWidgets('pending review sends a selected change reason', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = _FakeService();
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (_, _) =>
            MaterialApp(home: CurationManageScreen(service: service)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('확인하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('수정요청'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('글 내 오탈자 및 맞춤법, 띄어쓰기를 확인해주세요.'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('수정 요청').last);
    await tester.pumpAndSettle();

    expect(service.lastReason, '글 내 오탈자 및 맞춤법, 띄어쓰기를 확인해주세요.');
    expect(service.lastPublicationStatus, 'UNPUBLISHED');
    expect(tester.takeException(), isNull);
  });

  testWidgets('manager links an existing program before approval', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = _FakeService();
    final programService = _FakeProgramService();
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (_, _) => MaterialApp(
          home: CurationReviewScreen(
            summary: service.item,
            service: service,
            programService: programService,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('프로그램 검색'));
    await tester.pumpAndSettle();
    expect(find.textContaining('유사 프로그램', findRichText: true), findsOneWidget);
    expect(programService.lastSearch, '프로그램명');
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      isEmpty,
    );
    await tester.tap(find.text('연결할 프로그램'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('등록하기'));
    await tester.pumpAndSettle();

    expect(service.lastProgramId, 'program-id');
    expect(tester.takeException(), isNull);
  });

  testWidgets('hides similar programs when search has no results', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = _FakeService();
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (_, _) => MaterialApp(
          home: CurationReviewScreen(
            summary: service.item,
            service: service,
            programService: _FakeProgramService(empty: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('프로그램 검색'));
    await tester.pumpAndSettle();

    expect(find.textContaining('유사 프로그램', findRichText: true), findsNothing);
    expect(find.text('프로그램명을 입력해 주세요.'), findsOneWidget);
    expect(find.text('새로 등록'), findsOneWidget);
  });

  testWidgets('linked program is selected and can be opened for replacement', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = _LinkedFakeService();
    final programs = _FakeProgramService();
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (_, _) => MaterialApp(
          home: CurationReviewScreen(
            summary: service.linkedItem,
            service: service,
            programService: programs,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(programs.loadedId, 'program-id');
    expect(find.text('연결할 프로그램'), findsOneWidget);
    expect(find.text('프로그램 검색'), findsNothing);
    await tester.tap(find.text('연결할 프로그램'));
    await tester.pumpAndSettle();
    expect(find.text('프로그램 검색'), findsOneWidget);
  });
}

class _LinkedFakeService extends _FakeService {
  final linkedItem = AdminCurationModel.fromJson({
    'id': 'curation-id',
    'programId': 'program-id',
    'curator': {'curatorId': 'curator-id', 'nickname': '큐레이터명'},
    'submittedProgramTitle': '임시 제목',
    'submittedPlace': '장소',
    'tagline': '한줄소개',
    'content': '소개글',
    'images': const [],
    'status': 'CHANGES_REQUESTED',
    'publicationStatus': 'UNPUBLISHED',
  });

  @override
  Future<AdminCurationModel> fetchDetail(String id) async => linkedItem;
}

class _FakeService extends AdminCurationService {
  int approvalCalls = 0;
  Map<String, dynamic>? lastProgram;
  String? lastReason;
  String? lastPublicationStatus;
  String? lastProgramId;
  final item = AdminCurationModel.fromJson({
    'id': 'curation-id',
    'curator': {'curatorId': 'curator-id', 'nickname': '큐레이터명'},
    'submittedProgramTitle': '프로그램명',
    'submittedPlace': '장소',
    'tagline': '한줄소개',
    'content': '소개글',
    'images': const [],
    'status': 'PENDING',
    'publicationStatus': 'UNPUBLISHED',
    'createdAt': '2026-09-28T12:00:00',
  });

  @override
  Future<PageResponse<AdminCurationModel>> fetchList({
    required CurationStatus status,
    int page = 0,
    int size = 20,
  }) async =>
      PageResponse.fromList(status == CurationStatus.pending ? [item] : []);

  @override
  Future<AdminCurationModel> fetchDetail(String id) async => item;

  @override
  Future<AdminCurationModel> approveNew({
    required String curationId,
    required Map<String, dynamic> program,
    List<String> imagePaths = const [],
  }) async {
    approvalCalls++;
    lastProgram = program;
    return item;
  }

  @override
  Future<void> requestChanges({
    required String curationId,
    required String reason,
    required String publicationStatus,
  }) async {
    lastReason = reason;
    lastPublicationStatus = publicationStatus;
  }

  @override
  Future<AdminCurationModel> approveExisting({
    required String curationId,
    required String programId,
  }) async {
    lastProgramId = programId;
    return item;
  }
}

class _FakeProgramService extends ProgramService {
  _FakeProgramService({this.empty = false});

  final bool empty;
  String? lastSearch;
  String? loadedId;

  @override
  Future<ProgramModel> fetchProgram(
    String id, {
    bool authorized = false,
  }) async {
    loadedId = id;
    return ProgramModel.fromJson({
      'id': id,
      'title': '연결할 프로그램',
      'venueName': '장소',
      'programType': 'EXHIBITION',
    });
  }

  @override
  Future<PageResponse<ProgramModel>> fetchPrograms({
    String? search,
    List<String> keywordNames = const [],
    Filter? chip,
    ProgramSort sort = ProgramSort.latest,
    SortOrder order = SortOrder.desc,
    int page = 0,
    int size = 20,
    bool authorized = false,
  }) async {
    lastSearch = search;
    return PageResponse.fromList(
      empty
          ? []
          : [
              ProgramModel.fromJson({
                'id': 'program-id',
                'title': '연결할 프로그램',
                'venueName': '장소',
                'programType': 'EXHIBITION',
              }),
            ],
    );
  }
}
