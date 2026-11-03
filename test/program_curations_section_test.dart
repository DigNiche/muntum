import 'dart:convert';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/api/api_response.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/models/curation_model.dart';
import 'package:muntum/screens/program_detail/components/program_curations_section.dart';
import 'package:muntum/services/curation_service.dart';
import 'package:muntum/stores/auth_state.dart';
import 'package:muntum/stores/current_user_profile_image_store.dart';

Future<void> pumpSection(
  WidgetTester tester, {
  required CurationService service,
  ImageProvider? programPoster,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ScreenUtilPlusInit(
      designSize: const Size(390, 844),
      builder: (_, _) => MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProgramCurationsSection(
              programId: 'program-id',
              programTitle: '프로그램명',
              programPoster: programPoster,
              service: service,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'public note uses shared white app bar before and after scrolling',
    (tester) async {
      tester.view.padding = FakeViewPadding(top: 47, bottom: 34);
      addTearDown(tester.view.resetPadding);
      await pumpSection(
        tester,
        service: _FakePublicCurationService(
          content: List.filled(80, '스크롤해도 앱바는 흰색으로 유지됩니다.').join('\n'),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('curation-note-note-id')));
      await tester.pumpAndSettle();
      final header = find.byType(AppBarWidget);
      expect(header, findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
      expect(tester.widget<AppBarWidget>(header).center, '프로그램명');
      final initialRect = tester.getRect(header);
      final surface = find
          .ancestor(of: header, matching: find.byType(ColoredBox))
          .first;
      expect(tester.widget<ColoredBox>(surface).color, AppColors.white);

      Future<void> expectWhitePixels() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find
              .ancestor(of: header, matching: find.byType(RepaintBoundary))
              .first,
        );
        final point = boundary.globalToLocal(
          initialRect.topLeft + Offset(3, initialRect.height / 2),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          final index = (point.dy.floor() * image.width + point.dx.floor()) * 4;
          expect(
            List.generate(4, (channel) => bytes.getUint8(index + channel)),
            [255, 255, 255, 255],
          );
          image.dispose();
        });
      }

      await expectWhitePixels();
      final content = find.byKey(const ValueKey('curation-detail-content'));
      final contentTop = tester.getTopLeft(content).dy;
      await tester.drag(
        find.byType(SingleChildScrollView).last,
        const Offset(0, -700),
      );
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(content).dy, lessThan(contentTop - 100));
      expect(tester.getRect(header), initialRect);
      await expectWhitePixels();
      expect(tester.takeException(), isNull);
      await tester.tapAt(initialRect.centerLeft + const Offset(20, 0));
      await tester.pumpAndSettle();
      expect(find.byType(PublicCurationDetailScreen), findsNothing);
    },
  );
  final poster = MemoryImage(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aZ1kAAAAASUVORK5CYII=',
    ),
  );

  for (final staleThumbnail in [null, 'https://example.com/old-note.jpg']) {
    testWidgets(
      'imageless note uses poster only on card; stale=$staleThumbnail',
      (tester) async {
        await pumpSection(
          tester,
          service: _FakePublicCurationService(thumbnailUrl: staleThumbnail),
          programPoster: poster,
        );
        final card = find.byKey(const ValueKey('curation-note-note-id'));
        expect(
          tester
              .widgetList<Image>(
                find.descendant(of: card, matching: find.byType(Image)),
              )
              .where((image) => image.image == poster),
          hasLength(1),
        );
        await tester.tap(card);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('curation-detail-images')),
          findsNothing,
        );
        expect(
          tester
              .widgetList<Image>(find.byType(Image))
              .where((image) => image.image == poster),
          isEmpty,
        );
        expect(find.text('본문 미리보기'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('curation-detail-title')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('uploaded note photos take priority over program poster', (
    tester,
  ) async {
    const imageUrl = 'https://example.com/note.jpg';
    await pumpSection(
      tester,
      service: _FakePublicCurationService(
        includeImages: true,
        imageUrl: imageUrl,
      ),
      programPoster: poster,
    );
    final card = find.byKey(const ValueKey('curation-note-note-id'));
    final images = tester.widgetList<Image>(
      find.descendant(of: card, matching: find.byType(Image)),
    );
    expect(
      images.any((image) => image.image == const NetworkImage(imageUrl)),
      isTrue,
    );
    expect(images.any((image) => image.image == poster), isFalse);
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('curation-detail-images')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('curation-detail-image-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('curation-detail-image-1')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('imageless note with no program poster still opens text detail', (
    tester,
  ) async {
    await pumpSection(tester, service: _FakePublicCurationService());
    await tester.tap(find.byKey(const ValueKey('curation-note-note-id')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('curation-detail-images')), findsNothing);
    expect(find.text('본문 미리보기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('current author photo appears when public curation omits it', (
    tester,
  ) async {
    AuthState.instance.replace(userId: 'author-id', role: 'CURATOR');
    addTearDown(() {
      CurrentUserProfileImageStore.instance.clear();
      AuthState.instance.clear();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(
          home: Scaffold(
            body: ProgramCurationsSection(
              programId: 'program-id',
              programTitle: '프로그램명',
              service: _FakePublicCurationService(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    CurrentUserProfileImageStore.instance.update(
      userId: 'author-id',
      imageUrl: 'https://example.com/new-profile.jpg',
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widgetList<Image>(find.byType(Image))
          .any(
            (image) =>
                image.image is NetworkImage &&
                (image.image as NetworkImage).url ==
                    'https://example.com/new-profile.jpg',
          ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

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

  testWidgets('curator card arrows move between next and previous notes', (
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
    expect(
      find.byKey(const ValueKey('curator-note-next-arrow')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('curator-note-previous-arrow')),
      findsOneWidget,
    );
    final first = tester.getRect(
      find.byKey(const ValueKey('curation-note-note-id')),
    );
    final second = tester.getRect(
      find.byKey(const ValueKey('curation-note-note-1')),
    );
    expect(first.left, closeTo(20, 0.1));
    expect(second.left - first.right, closeTo(12, 0.1));
    expect(first.width / first.height, closeTo(300 / 395, 0.001));
    await tester.tap(find.byKey(const ValueKey('curator-note-next-arrow')));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(const ValueKey('curation-note-note-1'))).left,
      closeTo(20, 0.1),
    );
    await tester.tap(find.byKey(const ValueKey('curator-note-previous-arrow')));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(const ValueKey('curation-note-note-id'))).left,
      closeTo(20, 0.1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'curation detail shows detail-only date with author and image spacing',
    (tester) async {
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
              }),
              service: _FakePublicCurationService(
                includeImages: true,
                detailCreatedAt: '2026-10-05T14:15:49.334852',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('작성일 26.10.05'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('user-role-badge-author-id')),
        findsOneWidget,
      );
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
    },
  );

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
  _FakePublicCurationService({
    this.count = 1,
    this.includeImages = false,
    this.detailCreatedAt,
    this.thumbnailUrl,
    this.imageUrl = '',
    this.content = '본문 미리보기',
  });

  final int count;
  final bool includeImages;
  final String? detailCreatedAt;
  final String? thumbnailUrl;
  final String imageUrl;
  final String content;

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
        'thumbnailUrl': thumbnailUrl,
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
    'content': content,
    if (detailCreatedAt != null) 'createdAt': detailCreatedAt,
    'images': includeImages
        ? [
            {'id': 'image-1', 'imageUrl': imageUrl, 'displayOrder': 0},
            {'id': 'image-2', 'imageUrl': imageUrl, 'displayOrder': 1},
          ]
        : [],
  });
}
