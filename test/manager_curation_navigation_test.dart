import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/api/api_response.dart';
import 'package:muntum/components/curation_like_bar.dart';
import 'package:muntum/models/admin_curation_model.dart';
import 'package:muntum/models/curation_model.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/mypage/manager/curation_review_screen.dart';
import 'package:muntum/screens/mypage/manager/program_curations_manage_screen.dart';
import 'package:muntum/screens/program_detail/components/program_curations_section.dart';
import 'package:muntum/services/admin_curation_service.dart';
import 'package:muntum/services/curation_service.dart';
import 'package:muntum/stores/auth_state.dart';

void main() {
  setUp(() => AuthState.instance.replace(accessToken: 'test', role: 'MANAGER'));
  tearDown(AuthState.instance.clear);

  Future<void> show(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (_, _) => MaterialApp(home: Scaffold(body: page)),
      ),
    );
    await tester.pumpAndSettle();
  }

  ProgramCurationsSection section(
    _PublicService public,
    _ManagerService manager,
  ) => ProgramCurationsSection(
    programId: 'program',
    programTitle: '프로그램',
    service: public,
    adminService: manager,
  );

  void expectNoLikes(WidgetTester tester) {
    expect(find.byType(CurationLikeBar), findsNothing);
    expect(find.text('77'), findsNothing);
    expect(
      tester.widgetList<SvgPicture>(find.byType(SvgPicture)).where((svg) {
        final loader = svg.bytesLoader;
        return loader is SvgAssetLoader && loader.assetName.contains('/heart_');
      }),
      isEmpty,
    );
  }

  for (final status in ['APPROVED', 'PENDING', 'CHANGES_REQUESTED']) {
    testWidgets(
      'manager opens $status program curation management from the note card',
      (tester) async {
        final manager = _ManagerService(status: status);
        final public = _PublicService();
        await show(tester, section(public, manager));
        final publicReadsBeforeOpen = public.detailReads;
        await tester.tap(find.byKey(const ValueKey('curation-note-note')));
        await tester.pumpAndSettle();
        expect(find.byType(ProgramCurationsManageScreen), findsOneWidget);
        expect(find.byType(CurationReviewScreen), findsNothing);
        expect(find.byType(PublicCurationDetailScreen), findsNothing);
        expectNoLikes(tester);
        expect(manager.readIds, ['note']);
        expect(public.detailReads, publicReadsBeforeOpen);
        expect(
          find.text('수정요청'),
          status == 'CHANGES_REQUESTED' ? findsNothing : findsOneWidget,
        );
        if (status == 'CHANGES_REQUESTED') {
          expect(find.text('수정요청 1 ›'), findsOneWidget);
          await tester.tap(find.text('수정요청 1 ›'));
          await tester.pumpAndSettle();
          expect(find.byType(CurationReviewScreen), findsOneWidget);
          expect(find.textContaining('기존 요청 사유'), findsOneWidget);
          expectNoLikes(tester);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'program curation management stays on its own page when reading a post',
    (tester) async {
      final manager = _ManagerService();
      await show(
        tester,
        ProgramCurationsManageScreen(
          program: ProgramModel.fromJson({'id': 'program', 'title': '프로그램'}),
          curationService: _PublicService(),
          adminService: manager,
        ),
      );
      expect(find.byType(ProgramCurationsManageScreen), findsOneWidget);
      await tester.tap(find.text('관리자 상세 한줄'));
      await tester.pumpAndSettle();
      expect(find.byType(CurationReviewScreen), findsNothing);
      expect(find.byType(ProgramCurationsManageScreen), findsOneWidget);
      expectNoLikes(tester);
      expect(find.text('수정요청'), findsOneWidget);
    },
  );

  for (final role in ['AUDIENCE', 'CURATOR']) {
    testWidgets(
      '$role still opens the public reader and interactive like bar',
      (tester) async {
        AuthState.instance.replace(accessToken: 'test', role: role);
        final manager = _ManagerService();
        await show(tester, section(_PublicService(), manager));
        await tester.tap(find.byKey(const ValueKey('curation-note-note')));
        await tester.pumpAndSettle();
        expect(find.byType(PublicCurationDetailScreen), findsOneWidget);
        expect(find.byType(CurationReviewScreen), findsNothing);
        expect(find.byType(CurationLikeBar), findsOneWidget);
        expect(manager.readIds, isEmpty);
      },
    );
  }

  testWidgets(
    'published resubmitted PENDING note keeps selected publication state',
    (tester) async {
      final manager = _ManagerService(status: 'PENDING');
      await show(tester, section(_PublicService(), manager));
      await tester.tap(find.byKey(const ValueKey('curation-note-note')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('수정요청'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('글 내 오탈자 및 맞춤법, 띄어쓰기를 확인해주세요.'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('수정 요청').last);
      await tester.pumpAndSettle();
      expect(manager.requestedPublication, 'PUBLISHED');
      expect(manager.requestedId, 'note');
      expect(find.byType(CurationReviewScreen), findsNothing);
      expect(find.byType(ProgramCurationsManageScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('curation review itself never displays likes', (tester) async {
    await show(
      tester,
      CurationReviewScreen.byId(curationId: 'note', service: _ManagerService()),
    );
    expect(find.text('수정요청'), findsOneWidget);
    expectNoLikes(tester);
    expect(tester.takeException(), isNull);
  });
}

class _PublicService extends CurationService {
  int detailReads = 0;

  PublicCurationModel get note => PublicCurationModel.fromJson({
    'id': 'note',
    'programId': 'program',
    'tagline': '공개 한줄',
    'content': '공개 본문',
    'like': {'count': 1, 'liked': false},
  });

  @override
  Future<PageResponse<PublicCurationModel>> fetchProgramCurations(
    String programId, {
    int page = 0,
    int size = 20,
  }) async => PageResponse.fromList([note]);

  @override
  Future<PublicCurationModel> fetchProgramCurationDetail(
    String programId,
    String id,
  ) async {
    detailReads++;
    return note;
  }
}

class _ManagerService extends AdminCurationService {
  _ManagerService({this.status = 'APPROVED'});
  final String status;
  final readIds = <String>[];
  String? requestedPublication;
  String? requestedId;

  @override
  Future<AdminCurationModel> fetchDetail(String id) async {
    readIds.add(id);
    return AdminCurationModel.fromJson({
      'id': id,
      'programId': 'program',
      'tagline': '관리자 상세 한줄',
      'content': '관리자 상세 본문',
      'status': status,
      'publicationStatus': 'PUBLISHED',
      'changeRequestReason': status == 'CHANGES_REQUESTED' ? '기존 요청 사유' : null,
      'curator': {'curatorId': 'author', 'nickname': '작성자'},
      'like': {'count': 77, 'liked': false},
    });
  }

  @override
  Future<PageResponse<AdminCurationModel>> fetchList({
    required CurationStatus status,
    int page = 0,
    int size = 20,
  }) async => PageResponse.fromList([]);

  @override
  Future<void> requestChanges({
    required String curationId,
    required String reason,
    required String publicationStatus,
  }) async {
    requestedPublication = publicationStatus;
    requestedId = curationId;
  }
}
