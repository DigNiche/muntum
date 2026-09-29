import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/api/api_response.dart';
import 'package:muntum/models/curation_model.dart';
import 'package:muntum/screens/program_detail/components/program_curations_section.dart';
import 'package:muntum/services/curation_service.dart';
import 'package:muntum/stores/auth_state.dart';

void main() {
  testWidgets('curator Note shows the supplied SVG and a layered card', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProgramCurationsSection(
                programId: 'program-id',
                programTitle: '프로그램명',
                service: _FakePublicCurationService(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('큐레이터'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('curator-note-title-svg')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('curator-by-font-svg')), findsOneWidget);
    expect(find.byKey(const ValueKey('curator-note-next-arrow')), findsNothing);
    expect(find.text('본문 미리보기'), findsOneWidget);
    expect(find.byKey(const ValueKey('curation-note-note-id')), findsOneWidget);
    final cardRect = tester.getRect(
      find.byKey(const ValueKey('curation-note-note-id')),
    );
    expect(cardRect.width / cardRect.height, closeTo(300 / 395, 0.001));
    expect(cardRect.center.dx, closeTo(195, 0.1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('multiple curator cards show the supplied next arrow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(
          home: Scaffold(
            body: ProgramCurationsSection(
              programId: 'program-id',
              programTitle: '프로그램명',
              service: _FakePublicCurationService(count: 2),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('curator-note-next-arrow')), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('curation detail matches author, date and image spacing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(
          home: PublicCurationDetailScreen(
            programId: 'program-id',
            programTitle: '프로그램명',
            summary: PublicCurationModel.fromJson({
              'id': 'note-id',
              'programId': 'program-id',
              'curator': {'nickname': '문틈 큐레이터'},
              'tagline': '큐레이션 한줄소개',
              'createdAt': '2026-12-12T10:00:00',
            }),
            service: _FakePublicCurationService(includeImages: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('작성일 26.12.12'), findsOneWidget);
    expect(find.byKey(const ValueKey('program-curator-badge')), findsOneWidget);
    final title = tester.getRect(
      find.byKey(const ValueKey('curation-detail-title')),
    );
    final image = tester.getRect(
      find.byKey(const ValueKey('curation-detail-image-0')),
    );
    final secondImage = tester.getRect(
      find.byKey(const ValueKey('curation-detail-image-1')),
    );
    final content = tester.getRect(
      find.byKey(const ValueKey('curation-detail-content')),
    );
    expect(title.left, closeTo(20, 0.1));
    expect(image.left, closeTo(20, 0.1));
    expect(image.width, closeTo(240, 0.1));
    expect(image.height, closeTo(320, 0.1));
    expect(secondImage.left - image.right, closeTo(12, 0.1));
    expect(content.top - image.bottom, closeTo(24, 0.1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('public curation hides actions from non-authors', (tester) async {
    AuthState.instance.replace(userId: 'someone-else', role: 'CURATOR');
    addTearDown(AuthState.instance.clear);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(
          home: PublicCurationDetailScreen(
            programId: 'program-id',
            programTitle: '프로그램명',
            summary: PublicCurationModel.fromJson({
              'id': 'note-id',
              'programId': 'program-id',
              'curator': {'curatorId': 'author-id', 'nickname': '문틈 큐레이터'},
              'tagline': '큐레이션 한줄소개',
            }),
            service: _FakePublicCurationService(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('public-curation-actions')), findsNothing);
  });
}

class _FakePublicCurationService extends CurationService {
  _FakePublicCurationService({this.count = 1, this.includeImages = false});

  final int count;
  final bool includeImages;

  @override
  Future<PageResponse<PublicCurationModel>> fetchProgramCurations(
    String programId, {
    int page = 0,
    int size = 20,
  }) async => PageResponse.fromList(
    List.generate(
      count,
      (index) => PublicCurationModel.fromJson({
        'id': index == 0 ? 'note-id' : 'note-$index',
        'programId': programId,
        'curator': {'curatorId': 'author-id', 'nickname': '문틈 큐레이터'},
        'tagline': '큐레이션 한줄소개',
        'thumbnailUrl': null,
      }),
    ),
  );

  @override
  Future<PublicCurationModel> fetchProgramCurationDetail(
    String programId,
    String curationId,
  ) async => PublicCurationModel.fromJson({
    'id': curationId,
    'programId': programId,
    'curator': {'curatorId': 'author-id', 'nickname': '문틈 큐레이터'},
    'tagline': '큐레이션 한줄소개',
    'content': '본문 미리보기',
    'images': includeImages
        ? [
            {'id': 'image-1', 'imageUrl': '', 'displayOrder': 0},
            {'id': 'image-2', 'imageUrl': '', 'displayOrder': 1},
          ]
        : [],
  });
}
