import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:muntum/api/api_response.dart';
import 'package:muntum/components/content_skeleton.dart';
import 'package:muntum/components/cards/horizontal.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/scroll_to_top_button.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/home/components/explore_taste_section.dart';
import 'package:muntum/screens/home/see_more_screen.dart';
import 'package:muntum/screens/mypage/audience/keyword_change_screen.dart';
import 'package:muntum/models/keyword_model.dart';
import 'package:muntum/services/keyword_service.dart';
import 'package:muntum/services/taste_service.dart';
import 'package:muntum/stores/auth_state.dart';
import 'package:muntum/stores/user_preference_store.dart';

Future<void> _pumpSection(
  WidgetTester tester,
  PageResponse<ProgramModel> programs, {
  Future<PageResponse<ProgramModel>> Function()? loadPrograms,
  NavigatorObserver? observer,
  bool loggedIn = true,
}) async {
  AuthState.instance.replace(accessToken: loggedIn ? 'test' : null);
  addTearDown(AuthState.instance.clear);
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ScreenUtilPlusInit(
      designSize: const Size(390, 844),
      builder: (_, _) => MaterialApp(
        navigatorObservers: [?observer],
        home: Scaffold(
          body: ListView(
            children: [
              ExploreTasteSection(
                loadPrograms: loadPrograms ?? () async => programs,
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _RouteObserver extends NavigatorObserver {
  int detailPushes = 0;
  MaterialPageRoute<dynamic>? lastRoute;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) {
      detailPushes++;
      if (route is MaterialPageRoute<dynamic>) lastRoute = route;
    }
  }
}

class _TasteService extends TasteService {
  _TasteService({this.ready, this.programCount = 1});

  final Future<void>? ready;
  final int programCount;
  final chips = <String?>[];

  @override
  Future<TasteKeywordResult> fetchMyKeywords() async =>
      const TasteKeywordResult(
        selectedKeywords: [KeywordModel(id: '1', name: '사진맛집')],
      );

  @override
  Future<PageResponse<ProgramModel>> fetchTastePrograms({
    String? chip,
    int page = 0,
    int size = 20,
  }) async {
    chips.add(chip);
    await ready;
    if (programCount > 1) {
      return PageResponse.fromList([
        for (var index = 1; index <= programCount; index++)
          ProgramModel.fromJson({'id': index, 'title': '프로그램 $index'}),
      ]);
    }
    return PageResponse.fromList([
      ProgramModel.fromJson({
        'id': 1,
        'title': '목록 프로그램',
        'keywords': [
          for (final name in ['전시', '공연', '축제', '사진맛집']) {'name': name},
        ],
      }),
    ]);
  }
}

class _KeywordService extends KeywordService {
  @override
  Future<List<KeywordModel>> fetchTaggedKeywords() async => const [
    KeywordModel(id: '1', name: '사진맛집'),
    KeywordModel(id: '2', name: '새로 고른 키워드'),
  ];
}

void main() {
  testWidgets(
    'guest preview keeps its space without requesting recommendations',
    (tester) async {
      final programs = PageResponse.fromList([
        ProgramModel.fromJson({'id': 1, 'title': '취향 프로그램'}),
      ]);
      var requests = 0;
      await _pumpSection(
        tester,
        programs,
        loggedIn: false,
        loadPrograms: () async {
          requests++;
          return programs;
        },
      );

      final section = find.byType(ExploreTasteSection);
      final guestHeight = tester.getSize(section).height;
      expect(guestHeight, greaterThanOrEqualTo(430));
      expect(find.text('내 취향 모아보기'), findsNothing);
      expect(find.text('전체보기'), findsNothing);
      expect(find.byType(PageView), findsNothing);
      expect(find.byType(SkeletonBlock), findsNothing);
      expect(requests, 0);

      AuthState.instance.update(accessToken: 'test');
      await tester.pumpAndSettle();
      expect(requests, 1);
      expect(find.text('취향 프로그램'), findsOneWidget);
      expect(find.text('전체보기'), findsOneWidget);
      expect(tester.getSize(section).height, closeTo(guestHeight, 1));

      AuthState.instance.clear();
      await tester.pumpAndSettle();
      expect(requests, 1);
      expect(find.text('전체보기'), findsNothing);
      expect(find.byType(PageView), findsNothing);
      expect(tester.getSize(section).height, closeTo(guestHeight, 1));
    },
  );

  for (final directEdit in [true, false]) {
    for (final hasChanges in [true, false]) {
      testWidgets(
        'keyword back preserves the entry flow: direct=$directEdit, changed=$hasChanges',
        (tester) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            ScreenUtilPlusInit(
              designSize: const Size(390, 844),
              builder: (_, _) => MaterialApp(
                home: Builder(
                  builder: (context) => Scaffold(
                    body: TextButton(
                      onPressed: () => Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) => KeywordChangeScreen(
                            initiallyEditing: directEdit,
                            popAfterSave: directEdit,
                            keywordService: _KeywordService(),
                            tasteService: _TasteService(),
                          ),
                        ),
                      ),
                      child: const Text('목록으로 복귀'),
                    ),
                  ),
                ),
              ),
            ),
          );
          addTearDown(UserPreferenceStore.instance.clear);
          await tester.tap(find.text('목록으로 복귀'));
          await tester.pumpAndSettle();

          if (!directEdit) {
            await tester.tap(find.text('편집'));
            await tester.pumpAndSettle();
          }
          expect(find.text('키워드 편집'), findsOneWidget);
          if (hasChanges) {
            final keyword = tester.getRect(find.text('새로 고른 키워드'));
            await tester.tapAt(Offset(keyword.left - 22, keyword.center.dy));
            await tester.pumpAndSettle();
          }
          final appBar = tester.getRect(find.byType(AppBarWidget));
          await tester.tapAt(Offset(appBar.left + 32, appBar.center.dy));
          await tester.pumpAndSettle();
          if (hasChanges) {
            expect(find.text('변경사항을 저장할까요?'), findsOneWidget);
            await tester.tap(find.text('나가기'));
            await tester.pumpAndSettle();
            expect(UserPreferenceStore.instance.selectedKeywords, {'사진맛집'});
          }

          expect(find.text('키워드 편집'), findsNothing);
          expect(find.text(directEdit ? '목록으로 복귀' : '키워드'), findsOneWidget);
        },
      );
    }
  }

  testWidgets(
    'only Android reserves the system bar inset for the list and scroll button',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(bottom: 64);
      tester.view.viewPadding = const FakeViewPadding(bottom: 64);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      AuthState.instance.update(accessToken: 'test');
      addTearDown(AuthState.instance.clear);
      addTearDown(UserPreferenceStore.instance.clear);
      await tester.pumpWidget(
        ScreenUtilPlusInit(
          designSize: const Size(390, 844),
          builder: (_, _) => MaterialApp(
            home: SeeMoreScreen(
              type: SeeMoreType.myTaste,
              tasteService: _TasteService(programCount: 8),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final list = find.byType(CustomScrollView);
      final scrollable = find.descendant(
        of: list,
        matching: find.byType(Scrollable),
      );
      final position = tester.state<ScrollableState>(scrollable).position;
      // The first jump lays out the tail of the sliver; the second reaches its final extent.
      position.jumpTo(position.maxScrollExtent);
      await tester.pumpAndSettle();
      position.jumpTo(position.maxScrollExtent);
      await tester.pumpAndSettle();

      final bottom = defaultTargetPlatform == TargetPlatform.android
          ? 780.0
          : 844.0;
      final lastCard = find.ancestor(
        of: find.text('프로그램 8'),
        matching: find.byType(HorizontalCard),
      );
      expect(tester.getRect(list).bottom, closeTo(bottom, 0.1));
      expect(tester.getRect(lastCard).bottom, closeTo(bottom - 24, 0.1));
      final button = find.byType(ScrollToTopButton);
      expect(tester.getRect(button).bottom, closeTo(bottom - 24, 0.1));
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(position.pixels, 0);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );

  testWidgets('header opens the full taste list even with no preview', (
    tester,
  ) async {
    final observer = _RouteObserver();
    await _pumpSection(tester, PageResponse.fromList([]), observer: observer);
    final more = find.text('전체보기');
    await tester.tap(more);
    final screen = observer.lastRoute!.builder(tester.element(more));
    expect(screen, isA<SeeMoreScreen>());
    expect((screen as SeeMoreScreen).type, SeeMoreType.myTaste);
  });

  testWidgets(
    'taste list applies filters and opens the existing keyword editor',
    (tester) async {
      AuthState.instance.update(accessToken: 'test');
      addTearDown(AuthState.instance.clear);
      addTearDown(UserPreferenceStore.instance.clear);
      final ready = Completer<void>();
      final service = _TasteService(ready: ready.future);
      final observer = _RouteObserver();
      await tester.pumpWidget(
        ScreenUtilPlusInit(
          designSize: const Size(390, 844),
          builder: (_, _) => MaterialApp(
            navigatorObservers: [observer],
            home: SeeMoreScreen(
              type: SeeMoreType.myTaste,
              tasteService: service,
            ),
          ),
        ),
      );
      expect(find.byType(ProgramListSkeleton), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      ready.complete();
      await tester.pumpAndSettle();
      expect(find.byType(ProgramListSkeleton), findsNothing);
      expect(find.text('목록 프로그램'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('사진맛집')).dx,
        lessThan(tester.getTopLeft(find.text('전시').last).dx),
      );
      expect(find.text('+2'), findsOneWidget);
      expect(find.text('더 찾아보기'), findsNothing);
      await tester.tap(find.text('무료'));
      await tester.pumpAndSettle();
      expect(service.chips.last, 'FREE');
      final keywords = find.text('내 취향 키워드');
      final program = find.text('목록 프로그램');
      final collapsedY = tester.getTopLeft(program).dy;
      await tester.tap(keywords);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final expandingY = tester.getTopLeft(program).dy;
      await tester.pumpAndSettle();
      expect(expandingY, greaterThan(collapsedY));
      expect(tester.getTopLeft(program).dy, greaterThan(expandingY));
      expect(find.text('사진맛집'), findsNWidgets(2));
      await tester.tap(keywords);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(program).dy, collapsedY);
      expect(find.text('더 찾아보기'), findsNothing);
      await tester.tap(keywords);
      await tester.pumpAndSettle();

      final before = service.chips.length;
      UserPreferenceStore.instance.updateKeywords(['새 키워드']);
      await tester.pumpAndSettle();
      expect(service.chips.length, greaterThan(before));
      expect(find.text('새 키워드'), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('새 키워드'),
          matching: find.byWidgetPredicate((widget) {
            final decoration = widget is Container ? widget.decoration : null;
            return decoration is BoxDecoration &&
                decoration.borderRadius == BorderRadius.circular(999);
          }),
        ),
        findsOneWidget,
      );
      final edit = find.text('더 찾아보기');
      await tester.tap(edit);
      final screen = observer.lastRoute!.builder(tester.element(edit));
      expect(screen, isA<KeywordChangeScreen>());
      expect((screen as KeywordChangeScreen).initiallyEditing, isTrue);
      expect(screen.popAfterSave, isTrue);
    },
  );

  for (final tapPoster in [true, false]) {
    testWidgets(
      'background tap stays on Explore, ${tapPoster ? 'poster' : 'title'} opens detail',
      (tester) async {
        final observer = _RouteObserver();
        await _pumpSection(
          tester,
          PageResponse.fromList([
            ProgramModel.fromJson({
              'id': 1,
              'title': '첫 추천',
              'thumbnailUrl': 'https://example.test/poster.png',
            }),
          ]),
          observer: observer,
        );

        final pager = tester.getRect(find.byType(PageView));
        await tester.tapAt(pager.topLeft + const Offset(12, 35));
        await tester.pumpAndSettle();
        expect(observer.detailPushes, 0);

        final poster = find.byWidgetPredicate(
          (widget) => widget is Image && widget.fit == BoxFit.contain,
        );
        expect(poster, findsOneWidget);
        final posterRect = tester.getRect(poster);
        expect(posterRect.width, closeTo(160, 0.1));
        expect(posterRect.height, closeTo(160 * 4 / 3, 0.1));
        expect(posterRect.top - pager.top, closeTo(56, 0.1));
        expect(posterRect.center.dx, closeTo(pager.center.dx, 0.1));
        await tester.tap(tapPoster ? poster : find.text('첫 추천'));
        expect(observer.detailPushes, 1);
      },
    );
  }

  testWidgets('preference changes refresh recommendations without throwing', (
    tester,
  ) async {
    final preferences = UserPreferenceStore.instance;
    addTearDown(preferences.clear);
    var loads = 0;
    final empty = PageResponse<ProgramModel>.fromList([]);
    await _pumpSection(
      tester,
      empty,
      loadPrograms: () async => ++loads == 1
          ? empty
          : PageResponse.fromList([
              ProgramModel.fromJson({'id': 1, 'title': '갱신된 추천'}),
            ]),
    );

    preferences.updateKeywords(['회귀 테스트 취향']);
    await tester.pumpAndSettle();

    expect(loads, 2);
    expect(find.text('갱신된 추천'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'keeps the card frame and counter fixed while content follows the swipe',
    (tester) async {
      await _pumpSection(
        tester,
        PageResponse.fromList([
          ProgramModel.fromJson({'id': 1, 'title': '첫 추천'}),
          ProgramModel.fromJson({'id': 2, 'title': '다음 추천'}),
        ]),
      );

      final pager = find.byType(PageView);
      final frame = find.ancestor(of: pager, matching: find.byType(ClipRRect));
      final frameRect = tester.getRect(frame);
      final firstTitle = find.text('첫 추천');
      final initialTitleX = tester.getTopLeft(firstTitle).dx;
      final counterCenter = tester.getCenter(find.text('1/2'));
      final gesture = await tester.startGesture(
        frameRect.topLeft + const Offset(320, 35),
      );
      await gesture.moveBy(const Offset(-20, 0));
      await gesture.moveBy(const Offset(-100, 0));
      await tester.pump();

      expect(tester.getRect(frame), frameRect);
      expect(tester.getTopLeft(firstTitle).dx, lessThan(initialTitleX));
      expect(tester.getCenter(find.text('1/2')), counterCenter);

      await gesture.moveBy(const Offset(-150, 0));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.getCenter(find.text('2/2')), counterCenter);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'previews up to eight and opens the full taste list from the summary',
    (tester) async {
      final programs = List.generate(
        9,
        (index) =>
            ProgramModel.fromJson({'id': index, 'title': '추천 ${index + 1}'}),
      );
      final observer = _RouteObserver();
      await _pumpSection(
        tester,
        PageResponse(
          content: programs,
          page: 0,
          size: 8,
          totalElements: 21,
          totalPages: 3,
          first: true,
          last: false,
          hasPrevious: false,
          hasNext: true,
        ),
        observer: observer,
      );

      expect(find.text('내 취향 모아보기'), findsOneWidget);
      expect(find.text('전체보기'), findsOneWidget);
      expect(find.text('1/8'), findsOneWidget);
      for (var index = 2; index <= 8; index++) {
        await tester.drag(find.byType(PageView), const Offset(-300, 0));
        await tester.pumpAndSettle();
        expect(find.text('$index/8'), findsOneWidget);
      }
      await tester.drag(find.byType(PageView), const Offset(-300, 0));
      await tester.pumpAndSettle();
      final summary = find.text('내 취향 프로그램 21개 전체보기');
      expect(summary, findsOneWidget);
      expect(find.text('8/8'), findsNothing);
      expect(find.text('추천 9'), findsNothing);
      await tester.tap(summary);
      final screen = observer.lastRoute!.builder(tester.element(summary));
      expect((screen as SeeMoreScreen).type, SeeMoreType.myTaste);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('does not display a carousel or summary for an empty response', (
    tester,
  ) async {
    await _pumpSection(tester, PageResponse.fromList([]));

    expect(find.text('아직 추천 프로그램이 없어요.'), findsOneWidget);
    expect(find.byType(PageView), findsNothing);
  });
}
