import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/api/api_client.dart';
import 'package:muntum/api/api_exception.dart';
import 'package:muntum/components/curation_like_bar.dart';
import 'package:muntum/models/admin_curation_model.dart';
import 'package:muntum/models/curation_model.dart';
import 'package:muntum/models/curation_like_model.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/mypage/curator/curation_detail_screen.dart';
import 'package:muntum/screens/program_detail/components/program_curations_section.dart';
import 'package:muntum/services/curation_service.dart';
import 'package:muntum/stores/auth_state.dart';

void main() {
  setUp(
    () =>
        AuthState.instance.replace(accessToken: 'test-token', role: 'AUDIENCE'),
  );
  tearDown(AuthState.instance.clear);

  test(
    'public, own and admin models preserve nested likes and detail merges',
    () {
      final json = <String, dynamic>{
        'id': 'note',
        'like': {'count': 12, 'liked': true},
      };
      final public = PublicCurationModel.fromJson(json);
      final own = CurationModel.fromJson(json);
      final admin = AdminCurationModel.fromJson(json);
      final program = ProgramModel.fromJson({
        'curations': [json],
      });
      for (final like in [
        public.like,
        own.like,
        admin.curation.like,
        program.curations.single.like,
      ]) {
        expect(like.toJson(), {'count': 12, 'liked': true});
      }
      expect(
        PublicCurationModel.fromJson({}).mergeDetails(public).like.count,
        12,
      );
      expect(CurationModel.fromJson({}).mergeDetails(own).like.liked, isTrue);
      expect(PublicCurationModel.fromJson({}).like.toJson(), {
        'count': 0,
        'liked': false,
      });
      expect(CurationModel.fromJson({}).like.count, 0);
    },
  );

  test(
    'authenticated public queries attach authorization, guests do not',
    () async {
      final client = _LikeClient();
      final service = CurationService(client: client);
      await service.fetchProgramCurations('program');
      await service.fetchProgramCurationDetail('program', 'note');
      expect(client.authorizations, [true, true]);
      AuthState.instance.clear();
      await service.fetchProgramCurations('program');
      await service.fetchProgramCurationDetail('program', 'note');
      expect(client.authorizations, [true, true, false, false]);
    },
  );

  test(
    'PUT and DELETE use bodyless authorized like endpoint and parse response',
    () async {
      final client = _LikeClient();
      final service = CurationService(client: client);
      expect((await service.setLiked('note', liked: true)).toJson(), {
        'count': 13,
        'liked': true,
      });
      expect((await service.setLiked('note', liked: false)).toJson(), {
        'count': 12,
        'liked': false,
      });
      expect(client.mutations, [
        'PUT /api/v1/curations/note/like',
        'DELETE /api/v1/curations/note/like',
      ]);
      expect(client.authorizations, [true, true]);
    },
  );

  Future<void> show(
    WidgetTester tester,
    _LikeService service, {
    bool available = true,
    CurationLikeModel initial = const CurationLikeModel(count: 12),
    Future<CurationLikeModel> Function()? reload,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = FakeViewPadding(bottom: 34);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (_, _) => MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [SizedBox(height: 1800, child: Text('본문'))],
            ),
            bottomNavigationBar: CurationLikeBar(
              curationId: 'note',
              initialLike: initial,
              service: service,
              available: available,
              reload: reload ?? () async => const CurationLikeModel(count: 20),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final button = find.byKey(const ValueKey('curation-like-button'));

  for (final page in ['public', 'direct_public', 'own', 'unpublished']) {
    testWidgets('$page detail shows likes only for the program-detail entry', (
      tester,
    ) async {
      AuthState.instance.replace(accessToken: 'test-token', role: 'CURATOR');
      final service = _LikeService()..published = page != 'unpublished';
      // Initialize the same viewport as the isolated footer tests.
      await show(tester, service);
      await tester.pumpWidget(
        ScreenUtilPlusInit(
          designSize: const Size(390, 844),
          builder: (_, _) => MaterialApp(
            home: ['public', 'direct_public'].contains(page)
                ? PublicCurationDetailScreen(
                    programId: 'program',
                    programTitle: '프로그램',
                    summary: PublicCurationModel.fromJson({'id': 'note'}),
                    service: service,
                    showLikeBar: page == 'public',
                  )
                : CurationDetailScreen(
                    curation: service.note,
                    service: service,
                  ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (page == 'public') {
        expect(find.byKey(const ValueKey('curation-like-bar')), findsOneWidget);
        expect(find.text('12'), findsOneWidget);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(service.intents, [true]);
      } else {
        expect(find.byKey(const ValueKey('curation-like-bar')), findsNothing);
        expect(button, findsNothing);
        expect(service.intents, isEmpty);
      }
      expect(tester.takeException(), isNull);
    });
  }
  String icon(WidgetTester tester) =>
      (tester
                  .widget<SvgPicture>(
                    find.descendant(
                      of: button,
                      matching: find.byType(SvgPicture),
                    ),
                  )
                  .bytesLoader
              as SvgAssetLoader)
          .assetName;

  testWidgets(
    'footer is 84 high, stays fixed, updates count and both heart assets',
    (tester) async {
      final service = _LikeService();
      await show(tester, service);
      final footer = find.byKey(const ValueKey('curation-like-bar'));
      final before = tester.getRect(footer);
      expect(before.height, closeTo(84, 1));
      expect(icon(tester), endsWith('heart_unfilled.svg'));
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(tester.getRect(footer), before);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('13'), findsOneWidget);
      expect(icon(tester), endsWith('heart_filled.svg'));
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('12'), findsOneWidget);
      expect(icon(tester), endsWith('heart_unfilled.svg'));
      expect(service.intents, [true, false]);
    },
  );

  testWidgets(
    'rapid taps send only one request and do not optimistically change count',
    (tester) async {
      final pending = Completer<CurationLikeModel>();
      final service = _LikeService()..pending = pending;
      await show(tester, service);
      await tester.tap(button);
      await tester.tap(button);
      expect(service.intents, [true]);
      expect(find.text('12'), findsOneWidget);
      pending.complete(const CurationLikeModel(count: 99, liked: true));
      await tester.pumpAndSettle();
      expect(find.text('99'), findsOneWidget);
    },
  );

  for (final role in ['CURATOR', 'MANAGER', 'GUEST']) {
    testWidgets('$role respects role and login permissions', (tester) async {
      AuthState.instance.replace(
        accessToken: role == 'GUEST' ? null : 'test',
        role: role,
      );
      final service = _LikeService();
      await show(tester, service);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(service.intents.length, role == 'CURATOR' ? 1 : 0);
      if (role == 'GUEST') {
        expect(find.text('로그인 후 좋아요를 누를 수 있어요.'), findsOneWidget);
      }
    });
  }

  testWidgets('unpublished/loading footer is read-only', (tester) async {
    final service = _LikeService();
    await show(tester, service, available: false);
    await tester.tap(button);
    expect(service.intents, isEmpty);
  });

  for (final code in [
    'CU001',
    'CUL001',
    'CUL002',
    'CUL003',
    'A005',
    'A008',
    'G004',
    'CUL004',
  ]) {
    testWidgets('$code failure keeps server count and bounds retries', (
      tester,
    ) async {
      final service = _LikeService()
        ..error = ApiException(
          code: code,
          statusCode: code == 'A008' ? 401 : 409,
          message: '실패',
        );
      await show(
        tester,
        service,
        reload: () async => const CurationLikeModel(count: 12),
      );
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('12'), findsOneWidget);
      expect(icon(tester), endsWith('heart_unfilled.svg'));
      expect(service.intents.length, ['G004', 'CUL004'].contains(code) ? 2 : 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('network failure preserves count and permits retry', (
    tester,
  ) async {
    final service = _LikeService()..error = Exception('offline');
    await show(tester, service);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('12'), findsOneWidget);
    service.error = null;
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('13'), findsOneWidget);
  });

  testWidgets(
    'CUL004 refreshes before retry without reversing original intent',
    (tester) async {
      final service = _LikeService()
        ..error = const ApiException(code: 'CUL004', message: '상태 변경');
      var reloads = 0;
      await show(
        tester,
        service,
        reload: () async {
          reloads++;
          service.error = null;
          return const CurationLikeModel(count: 20, liked: true);
        },
      );
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(reloads, 1);
      expect(service.intents, [true, true]);
      expect(find.text('13'), findsOneWidget);
    },
  );

  testWidgets('a failed CUL004 requery does not resend mutation', (
    tester,
  ) async {
    final service = _LikeService()
      ..error = const ApiException(code: 'CUL004', message: '상태 변경');
    await show(
      tester,
      service,
      reload: () async =>
          throw const ApiException(code: 'CU001', message: '삭제'),
    );
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(service.intents, [true]);
    await tester.tap(button);
    expect(service.intents, [true]);
  });

  testWidgets(
    'G004 resends the same DELETE and accepts its authoritative count',
    (tester) async {
      final service = _LikeService()
        ..error = const ApiException(
          code: 'G004',
          statusCode: 503,
          message: '잠금 대기',
        )
        ..failuresRemaining = 1;
      await show(
        tester,
        service,
        initial: const CurationLikeModel(count: 13, liked: true),
      );
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(service.intents, [false, false]);
      expect(find.text('12'), findsOneWidget);
      expect(icon(tester), endsWith('heart_unfilled.svg'));
    },
  );

  testWidgets('zero likes are visible rather than hiding the count', (
    tester,
  ) async {
    await show(tester, _LikeService(), initial: const CurationLikeModel());
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('late response after leaving the page is safely discarded', (
    tester,
  ) async {
    final pending = Completer<CurationLikeModel>();
    final service = _LikeService()..pending = pending;
    await show(tester, service);
    await tester.tap(button);
    await tester.pumpWidget(const SizedBox());
    pending.complete(const CurationLikeModel(count: 13, liked: true));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('token refresh does not discard a successful like response', (
    tester,
  ) async {
    final pending = Completer<CurationLikeModel>();
    await show(tester, _LikeService()..pending = pending);
    await tester.tap(button);
    AuthState.instance.update(accessToken: 'refreshed-test-token');
    pending.complete(const CurationLikeModel(count: 13, liked: true));
    await tester.pumpAndSettle();
    expect(find.text('13'), findsOneWidget);
  });
}

class _LikeService extends CurationService {
  final intents = <bool>[];
  Object? error;
  int? failuresRemaining;
  Completer<CurationLikeModel>? pending;
  bool published = true;

  CurationModel get note => CurationModel.fromJson({
    'id': 'note',
    'programId': 'program',
    'status': 'APPROVED',
    'publicationStatus': published ? 'PUBLISHED' : 'UNPUBLISHED',
    'content': '큐레이션 본문',
    'like': {'count': 12, 'liked': false},
  });

  @override
  Future<CurationModel> fetchMyDetail(String id) async => note;

  @override
  Future<PublicCurationModel> fetchProgramCurationDetail(
    String programId,
    String id,
  ) async => PublicCurationModel.fromJson({
    'id': id,
    'programId': programId,
    'content': '본문',
    'like': {'count': 12, 'liked': false},
  });

  @override
  Future<CurationLikeModel> setLiked(String id, {required bool liked}) async {
    intents.add(liked);
    if (error != null &&
        (failuresRemaining == null || failuresRemaining! > 0)) {
      if (failuresRemaining != null) failuresRemaining = failuresRemaining! - 1;
      throw error!;
    }
    if (pending != null) return pending!.future;
    return CurationLikeModel(count: liked ? 13 : 12, liked: liked);
  }
}

class _LikeClient extends ApiClient {
  final authorizations = <bool>[];
  final mutations = <String>[];

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authorized = false,
  }) async {
    authorizations.add(authorized);
    return {
      'data': path.endsWith('/curations')
          ? <String, dynamic>{'content': []}
          : <String, dynamic>{},
    };
  }

  @override
  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    bool authorized = false,
  }) async {
    authorizations.add(authorized);
    mutations.add('PUT $path');
    expect(body, isNull);
    return {
      'data': {'count': 13, 'liked': true},
    };
  }

  @override
  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authorized = false,
  }) async {
    authorizations.add(authorized);
    mutations.add('DELETE $path');
    return {
      'data': {'count': 12, 'liked': false},
    };
  }
}
