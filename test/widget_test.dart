import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/api/api_client.dart';
import 'package:muntum/api/api_config.dart';
import 'package:muntum/api/api_endpoints.dart';
import 'package:muntum/components/cards/horizontal.dart';
import 'package:muntum/components/update_dialog.dart';
import 'package:muntum/data/report_place_search_repository.dart';
import 'package:muntum/models/auth_models.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/models/program_reaction.dart';
import 'package:muntum/models/report_model.dart';
import 'package:muntum/screens/home/components/two_row_horizontal_card_carousel.dart';
import 'package:muntum/screens/map/map_clustering.dart';
import 'package:muntum/screens/mypage/components/report_form_field.dart';
import 'package:muntum/screens/mypage/report_submit_screen.dart';
import 'package:muntum/screens/onboarding/sign_up_screens/sign_up.dart';
import 'package:muntum/services/auth_service.dart';
import 'package:muntum/screens/program_detail/components/program_information_section.dart';
import 'package:muntum/services/program_service.dart';
import 'package:muntum/services/program_reaction_service.dart';
import 'package:muntum/services/update_service.dart';
import 'package:muntum/stores/program_scrap_store.dart';
import 'package:muntum/stores/user_preference_store.dart';
import 'package:muntum/utils/program_keyword_match.dart';
import 'package:muntum/utils/program_query.dart';

void main() {
  group('api config', () {
    test('uses the production API by default', () {
      expect(ApiConfig.baseUrl, 'https://api.muntum.work');
    });
  });

  testWidgets('recommended update dialog lets the user update later', (
    tester,
  ) async {
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(home: child),
        child: const _UpdateDialogTestHost(isRequired: false),
      ),
    );

    await tester.tap(find.text('업데이트 확인'));
    await tester.pumpAndSettle();

    expect(find.text('새로운 버전이 있어요'), findsOneWidget);
    expect(find.text('나중에'), findsOneWidget);
    expect(find.text('지금 업데이트'), findsOneWidget);
  });

  testWidgets('required update dialog hides the later action', (tester) async {
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(home: child),
        child: const _UpdateDialogTestHost(isRequired: true),
      ),
    );

    await tester.tap(find.text('업데이트 확인'));
    await tester.pumpAndSettle();

    expect(find.text('나중에'), findsNothing);
    expect(find.text('지금 업데이트'), findsOneWidget);
  });

  group('social login contract', () {
    test('uses the social login endpoint', () {
      expect(ApiEndpoints.socialLogin, '/api/v1/auth/social/login');
    });

    test('serializes every Apple verification field', () {
      const request = SocialLoginRequest(
        provider: SocialAuthProvider.apple,
        token: 'identity-token',
        authorizationCode: 'authorization-code',
        nonce: 'hashed-nonce',
      );

      expect(request.toJson(), {
        'provider': 'APPLE',
        'token': 'identity-token',
        'authorizationCode': 'authorization-code',
        'nonce': 'hashed-nonce',
      });
    });
  });

  group('signup email verification contract', () {
    test('uses the documented email verification endpoints', () {
      expect(ApiEndpoints.signupEmailSendCode, '/api/v1/auth/email/send-code');
      expect(
        ApiEndpoints.signupEmailVerifyCode,
        '/api/v1/auth/email/verify-code',
      );
    });

    test(
      'sends email, code, and signup token with the exact field names',
      () async {
        final client = _RecordingAuthApiClient();
        final service = AuthService(client: client);

        final timing = await service.requestSignupEmailCode('user@example.com');
        final verification = await service.verifySignupEmailCode(
          email: 'user@example.com',
          code: '482913',
        );
        await service.signup(
          email: 'user@example.com',
          password: 'Password!1',
          signupToken: verification.signupToken,
        );

        expect(timing.expiresIn, 300);
        expect(timing.resendAfter, 60);
        expect(client.calls[0], {
          'path': ApiEndpoints.signupEmailSendCode,
          'body': {'email': 'user@example.com'},
        });
        expect(client.calls[1], {
          'path': ApiEndpoints.signupEmailVerifyCode,
          'body': {'email': 'user@example.com', 'code': '482913'},
        });
        expect(client.calls[2]['path'], ApiEndpoints.signup);
        expect(
          client.calls[2]['body'],
          containsPair('signupToken', 'signup-token'),
        );
      },
    );
  });

  group('program status', () {
    test('uses only the ended response for the ended state', () {
      final endedProgram = ProgramModel.fromJson({
        'title': '종료 프로그램',
        'status': 'ACTIVE',
        'ended': true,
        'endDate': '2099-12-31',
      });
      final activeProgram = ProgramModel.fromJson({
        'title': '진행 프로그램',
        'status': 'ENDED',
        'ended': false,
        'endDate': '2020-01-01',
      });

      expect(endedProgram.isEnded, isTrue);
      expect(activeProgram.isEnded, isFalse);
    });

    test('parses the new program flag only when isNew is true', () {
      final newProgram = ProgramModel.fromJson({
        'title': '새 프로그램',
        'isNew': true,
      });
      final existingProgram = ProgramModel.fromJson({'title': '기존 프로그램'});

      expect(newProgram.isNew, isTrue);
      expect(existingProgram.isNew, isFalse);
    });
  });

  group('program reactions', () {
    test('parses reaction summary from a program detail response', () {
      final program = ProgramModel.fromJson({
        'id': 'reaction-program',
        'title': '반응 프로그램',
        'reaction': {'myReaction': 'LIKE', 'likeCount': 15, 'dislikeCount': 2},
      });

      expect(program.reaction.myReaction, ProgramReaction.like);
      expect(program.reaction.likeCount, 15);
      expect(program.reaction.dislikeCount, 2);
    });

    test('sends the final reaction state documented by the API', () async {
      final client = _ProgramReactionApiClient();
      final service = ProgramReactionService(client: client);

      final result = await service.updateReaction(
        programId: 'reaction-program',
        reaction: ProgramReaction.dislike,
      );

      expect(client.lastPath, ApiEndpoints.programReaction('reaction-program'));
      expect(client.lastBody, {'reactionState': 'DISLIKE'});
      expect(client.lastAuthorized, isTrue);
      expect(result, ProgramReaction.dislike);

      await service.updateReaction(
        programId: 'reaction-program',
        reaction: null,
      );
      expect(client.lastBody, {'reactionState': 'NONE'});
    });

    test('requests my reaction list with paging parameters', () async {
      final client = _ProgramReactionApiClient();
      final service = ProgramReactionService(client: client);

      final page = await service.fetchMyPrograms(
        reaction: ProgramReaction.like,
        page: 2,
        size: 20,
      );

      expect(client.lastPath, ApiEndpoints.myProgramReactions);
      expect(client.lastQueryParameters, {
        'reactionType': 'LIKE',
        'page': 2,
        'size': 20,
      });
      expect(client.lastAuthorized, isTrue);
      expect(page.content.single.id, 'reaction-program');
    });
  });

  group('program card details', () {
    test('fills a missing card period from the detail response', () async {
      final service = ProgramService(client: _MissingPeriodApiClient());

      final page = await service.fetchHotKeywordPrograms();

      expect(page.content.single.cardDateText, '26.01.01-상시');
    });
  });

  group('hot keyword program filters', () {
    test('sends programType and detail chip as separate parameters', () async {
      final client = _HotKeywordFilterApiClient();

      await ProgramService(client: client).fetchHotKeywordPrograms(
        programType: ProgramType.exhibition,
        chip: Filter.free,
        page: 1,
        size: 20,
      );

      expect(client.lastPath, ApiEndpoints.programsHotKeywords);
      expect(client.lastQueryParameters, {
        'programType': 'EXHIBITION',
        'chip': 'FREE',
        'topN': 5,
        'page': 1,
        'size': 20,
      });
    });

    test('can exclude ended programs from collection previews', () async {
      final client = _HotKeywordFilterApiClient();

      await ProgramService(client: client).fetchHotKeywordPrograms(
        programType: ProgramType.festival,
        includeEnded: false,
        size: 8,
      );

      expect(client.lastPath, ApiEndpoints.programsHotKeywords);
      expect(client.lastQueryParameters, {
        'programType': 'FAIR',
        'chip': null,
        'includeEnded': false,
        'topN': 5,
        'page': 0,
        'size': 8,
      });
    });
  });

  group('map API chip mapping', () {
    test('maps every map filter to the documented chip value', () {
      expect(Filter.nowHot.mapApiChip, 'HOT');
      expect(Filter.free.mapApiChip, 'FREE');
      expect(Filter.thisWeek.mapApiChip, 'THIS_WEEK');
      expect(Filter.noReservation.mapApiChip, 'NO_RESERVATION');
      expect(Filter.exhibition.mapApiChip, 'EXHIBITION');
      expect(Filter.show.mapApiChip, 'PERFORMANCE');
      expect(Filter.experience.mapApiChip, 'CLASS_EXPERIENCE');
      expect(Filter.festival.mapApiChip, 'FAIR');
    });
  });

  group('map clustering', () {
    test('spiderfies programs sharing the same coordinates', () {
      final controller = MapClusteringController();
      final programs = [
        _program(id: 'same-place-1', title: '같은 장소 프로그램 1'),
        _program(id: 'same-place-2', title: '같은 장소 프로그램 2'),
      ];
      String keyFor(ProgramModel program) => program.id;

      final clustered = controller.clusterPrograms(
        programs,
        18,
        keyFor: keyFor,
      );
      expect(clustered, hasLength(1));
      expect(clustered.single.programs, hasLength(2));
      expect(controller.shouldSpiderfy(programs), isTrue);

      controller.spiderfyPrograms(programs, keyFor: keyFor);
      final spiderfied = controller.clusterPrograms(
        programs,
        18.05,
        keyFor: keyFor,
      );
      final positions = controller.spiderfiedMarkerPositions(
        spiderfied,
        18.05,
        keyFor: keyFor,
      );

      expect(spiderfied, hasLength(2));
      expect(positions, hasLength(2));
      expect(positions['same-place-1'], isNot(positions['same-place-2']));
    });

    test('separates nearby programs when the map zooms in', () {
      final controller = MapClusteringController();
      final programs = [
        _program(id: 'nearby-1', title: '인접 프로그램 1'),
        _program(id: 'nearby-2', title: '인접 프로그램 2', latitude: 37.52368),
      ];
      String keyFor(ProgramModel program) => program.id;

      expect(
        controller.clusterPrograms(programs, 12.5, keyFor: keyFor),
        hasLength(1),
      );
      expect(
        controller.clusterPrograms(programs, 13.5, keyFor: keyFor),
        hasLength(2),
      );
    });

    test('reduces the cluster radius from the first zoom-in steps', () {
      final controller = MapClusteringController();

      expect(controller.thresholdMetersForZoom(11.4), 300);
      expect(controller.thresholdMetersForZoom(12.4), 100);
      expect(controller.thresholdMetersForZoom(12.5), 30);
      expect(controller.thresholdMetersForZoom(13.5), 10);
      expect(controller.thresholdMetersForZoom(14.5), 3);
      expect(controller.shouldAutomaticallySpiderfy(14.5), isFalse);
      expect(controller.shouldAutomaticallySpiderfy(16.5), isTrue);
    });

    test('spiderfies multiple same-place groups independently', () {
      final controller = MapClusteringController();
      final firstGroup = [
        _program(id: 'first-1', title: '첫 장소 1'),
        _program(id: 'first-2', title: '첫 장소 2'),
      ];
      final secondGroup = [
        _program(id: 'second-1', title: '둘째 장소 1', latitude: 37.5335),
        _program(id: 'second-2', title: '둘째 장소 2', latitude: 37.5335),
      ];
      final programs = [...firstGroup, ...secondGroup];
      String keyFor(ProgramModel program) => program.id;

      expect(controller.shouldAutomaticallySpiderfy(17), isTrue);
      controller.addSpiderfiedPrograms(firstGroup, keyFor: keyFor);
      controller.addSpiderfiedPrograms(secondGroup, keyFor: keyFor);

      final spiderfied = controller.clusterPrograms(
        programs,
        18.05,
        keyFor: keyFor,
      );
      final positions = controller.spiderfiedMarkerPositions(
        spiderfied,
        18.05,
        keyFor: keyFor,
      );

      expect(spiderfied, hasLength(4));
      expect(positions, hasLength(4));
      expect(positions['first-1']!.latitude, lessThan(37.53));
      expect(positions['second-1']!.latitude, greaterThan(37.53));
    });
  });

  group('program keyword match', () {
    test('calculates capped three-bar match level', () {
      final program = _program(
        id: '1',
        title: '용산 전시 클래스',
        keywords: ['그 순간에 몰입', '생생한 감각', '사진맛집'],
      );

      expect(
        programKeywordMatchCount(program, [
          '그 순간에 몰입',
          '생생한 감각',
          '사진맛집',
          '없는 키워드',
        ]),
        3,
      );
      expect(
        programKeywordMatchLevel(program, [
          '그 순간에 몰입',
          '생생한 감각',
          '사진맛집',
          '없는 키워드',
        ]),
        3,
      );
      expect(programKeywordMatchLevel(program, ['없는 키워드']), 0);
    });

    test('sorts programs with stronger keyword matches first', () {
      final programs = [
        _program(id: '1', title: '일반 공연', keywords: ['여운이 남는']),
        _program(
          id: '2',
          title: '추천 체험',
          keywords: ['내 손으로 만드는', '새로운 것 배우기', '여운이 남는'],
        ),
      ];

      final sorted = sortProgramsByKeywordMatch(programs, [
        '내 손으로 만드는',
        '새로운 것 배우기',
        '여운이 남는',
      ]);

      expect(sorted.first.title, '추천 체험');
    });
  });

  group('program query', () {
    final programs = [
      _program(
        id: '1',
        title: '용산 문화공간 체험',
        detail: '작가의 표현법을 배워요.',
        address: '서울 용산구 한강대로14길 35-29',
        keywords: ['직접 참여하기', '새로운 것 배우기'],
        filters: [Filter.free, Filter.thisWeek],
        phoneNumber: '02-123-1004',
        link: 'https://muntum.work/programs/1',
      ),
      _program(
        id: '2',
        title: '남산 공연',
        detail: '야외에서 즐기는 공연입니다.',
        address: '서울 중구 남산공원길',
        keywords: ['여운이 남는'],
        filters: [Filter.show],
      ),
    ];

    test('searches address and detail fields', () {
      expect(
        queryPrograms(programs, query: '한강대로14길').single.title,
        '용산 문화공간 체험',
      );
      expect(
        queryPrograms(programs, query: '작가의 표현법').single.title,
        '용산 문화공간 체험',
      );
    });

    test('requires every selected keyword', () {
      final result = queryPrograms(
        programs,
        keywords: ['직접 참여하기', '새로운 것 배우기'],
      );

      expect(result.map((program) => program.title), ['용산 문화공간 체험']);
    });

    test('requires every selected filter', () {
      final result = queryPrograms(
        programs,
        filters: {Filter.free, Filter.thisWeek},
      );

      expect(result.map((program) => program.title), ['용산 문화공간 체험']);
    });

    test('searches reservation, phone, and link parameters', () {
      expect(
        queryPrograms(programs, query: '예약없이 02-123-1004').single.title,
        '용산 문화공간 체험',
      );
      expect(
        queryPrograms(programs, query: 'programs/1').single.title,
        '용산 문화공간 체험',
      );
    });
  });

  group('real-data local stores', () {
    tearDown(() {
      ProgramScrapStore.instance.clear(notify: false);
      UserPreferenceStore.instance.clear();
    });

    test('keeps scrapped programs from real API models', () {
      final program = _program(id: 'program-1', title: '스크랩 프로그램');

      ProgramScrapStore.instance.setScrapped(program, true, notify: false);
      expect(ProgramScrapStore.instance.isScrapped(program), isTrue);
      expect(ProgramScrapStore.instance.scrappedPrograms, contains(program));

      ProgramScrapStore.instance.setScrapped(program, false, notify: false);
      expect(ProgramScrapStore.instance.scrappedPrograms, isEmpty);
    });

    test('keeps selected keywords from real API models', () {
      UserPreferenceStore.instance.updateKeywords(['전시', '체험', '공연']);
      expect(UserPreferenceStore.instance.selectedKeywords, contains('전시'));
      expect(UserPreferenceStore.instance.selectedKeywords.length, 3);
    });
  });

  group('report place search', () {
    const repository = _FakeReportPlaceSearchRepository();

    test('searches place names and addresses', () async {
      final stationResults = await repository.search('용산역');
      expect(stationResults.map((place) => place.name), contains('용산역사박물관'));

      final addressResults = await repository.search('한강대로14길');
      expect(addressResults.single.name, '용산역사박물관');

      final spacedAddressResults = await repository.search('원주시 중앙로');
      expect(
        spacedAddressResults.map((place) => place.name),
        contains('문틈박물관'),
      );
    });
  });

  testWidgets('report place field opens place search screen', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(home: child),
        child: const ReportSubmitScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ReportFormField).last);
    await tester.pumpAndSettle();

    expect(find.text('장소 검색'), findsOneWidget);
  });

  testWidgets('program address supports long press', (tester) async {
    var didLongPressAddress = false;
    final program = _program(id: 'address-copy', title: '주소 복사 프로그램');

    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(home: Scaffold(body: child)),
        child: ProgramInformationSection(
          program: program,
          onLongPressAddress: () => didLongPressAddress = true,
          onTapContact: (_) {},
        ),
      ),
    );

    await tester.longPress(find.text(program.location['address']!));

    expect(didLongPressAddress, isTrue);
  });

  testWidgets('horizontal card replaces overflowing keywords with a count', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final program = _program(
      id: 'keyword-overflow-program',
      title: '키워드 표시 테스트',
      keywords: const ['조용한', '도파민', '한 줄에 들어가지 않는 매우 긴 세 번째 키워드'],
    );

    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(home: child),
        child: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 350,
              child: HorizontalCard(program: program),
            ),
          ),
        ),
      ),
    );

    expect(find.text('조용한'), findsOneWidget);
    expect(find.text('도파민'), findsOneWidget);
    expect(find.text('한 줄에 들어가지 않는 매우 긴 세 번째 키워드'), findsNothing);
    expect(find.text('+1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('horizontal card shows all three keywords when they fit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final program = _program(
      id: 'three-keyword-program',
      title: '키워드 표시 테스트',
      keywords: const ['전시', '사진', '역사'],
    );

    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(home: child),
        child: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 350,
              child: HorizontalCard(program: program),
            ),
          ),
        ),
      ),
    );

    expect(find.text('전시'), findsOneWidget);
    expect(find.text('사진'), findsOneWidget);
    expect(find.text('역사'), findsOneWidget);
    expect(find.text('+1'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('two-row carousel scrolls both map-card rows together', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final programs = List.generate(
      4,
      (index) => _program(id: 'hot-program-$index', title: '인기 ${index + 1}'),
    );

    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(home: child),
        child: Scaffold(
          body: TwoRowHorizontalCardCarousel(
            programs: programs,
            entrySource: 'all_hot',
          ),
        ),
      ),
    );

    final beforeTop = tester.getTopLeft(find.text('인기 3'));
    final beforeBottom = tester.getTopLeft(find.text('인기 4'));
    expect(beforeTop.dx, closeTo(beforeBottom.dx, 0.01));

    await tester.drag(find.byType(GridView), const Offset(-200, 0));
    await tester.pumpAndSettle();

    final afterTop = tester.getTopLeft(find.text('인기 3'));
    final afterBottom = tester.getTopLeft(find.text('인기 4'));
    expect(afterTop.dx, closeTo(afterBottom.dx, 0.01));
    expect(afterTop.dx, lessThan(beforeTop.dx));
    expect(tester.takeException(), isNull);
  });

  testWidgets('sign-up UI moves from email verification to password setup', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(home: child),
        child: SignUpScreen(authService: _FakeSignupAuthService()),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'user@example.com');
    await tester.pump();
    await tester.tap(find.text('인증하기'));
    await tester.pump();

    expect(find.text('05:00'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));

    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.pump();
    await tester.tap(find.text('인증 확인'));
    await tester.pumpAndSettle();

    expect(find.text('비밀번호를\n설정해주세요'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('expired sign-up code resets when resend is tapped', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(home: child),
        child: SignUpScreen(authService: _FakeSignupAuthService()),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'user@example.com');
    await tester.pump();
    await tester.tap(find.text('인증하기'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.pump();
    await tester.pump(const Duration(minutes: 5));

    expect(find.text('00:00'), findsOneWidget);
    expect(find.text('인증 시간이 만료되었습니다. 재발송을 눌러주세요.'), findsOneWidget);

    await tester.tap(find.text('재발송'));
    await tester.pump();

    expect(find.text('05:00'), findsOneWidget);
    expect(find.text('인증 시간이 만료되었습니다. 재발송을 눌러주세요.'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _FakeSignupAuthService extends AuthService {
  @override
  Future<SignupEmailCodeResult> requestSignupEmailCode(String email) async {
    return const SignupEmailCodeResult(expiresIn: 300, resendAfter: 60);
  }

  @override
  Future<SignupEmailVerificationResult> verifySignupEmailCode({
    required String email,
    required String code,
  }) async {
    return const SignupEmailVerificationResult(signupToken: 'signup-token');
  }
}

class _RecordingAuthApiClient extends ApiClient {
  final List<Map<String, Object?>> calls = [];

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    bool authorized = false,
  }) async {
    calls.add({'path': path, 'body': body});
    return switch (path) {
      ApiEndpoints.signupEmailSendCode => {
        'message': '인증번호가 이메일로 발송되었습니다.',
        'data': {'expiresIn': 300, 'resendAfter': 60},
      },
      ApiEndpoints.signupEmailVerifyCode => {
        'message': '이메일 인증이 완료되었습니다.',
        'data': {'signupToken': 'signup-token'},
      },
      ApiEndpoints.signup => {
        'message': '회원가입이 완료되었습니다.',
        'data': {
          'userId': 'user-id',
          'email': 'user@example.com',
          'createdAt': '2026-08-05T00:00:00Z',
        },
      },
      _ => {'message': '', 'data': <String, dynamic>{}},
    };
  }
}

class _UpdateDialogTestHost extends StatelessWidget {
  final bool isRequired;

  const _UpdateDialogTestHost({required this.isRequired});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => showAppUpdateDialog(
            context: context,
            updateInfo: AppUpdateInfo(
              isRequired: isRequired,
              title: '새로운 버전이 있어요',
              message: '문틈의 최신 버전을 사용해보세요.',
              storeUrl: Uri.parse('https://example.com'),
              installedVersion: AppReleaseVersion.parse('1.0.8', build: 5),
              latestVersion: AppReleaseVersion.parse('1.0.9', build: 6),
            ),
            onUpdate: () async {},
          ),
          child: const Text('업데이트 확인'),
        ),
      ),
    );
  }
}

ProgramModel _program({
  required String id,
  required String title,
  String detail = '문화 프로그램 상세 설명',
  String address = '서울 용산구 한강대로14길 35-29',
  List<String> keywords = const ['전시'],
  List<Filter> filters = const [Filter.exhibition],
  String phoneNumber = '',
  String link = '',
  double latitude = 37.5235,
  double longitude = 126.9804,
}) {
  return ProgramModel(
    id: id,
    title: title,
    oneLineDescription: '$title 소개',
    detail: detail,
    images: const [],
    keywords: keywords,
    startEndDates: '26.07.01-상시',
    locationName: '용산역사박물관',
    location: {
      'address': address,
      'latitude': '$latitude',
      'longitude': '$longitude',
    },
    availableTime: '10:00-18:00',
    cost: filters.contains(Filter.free) ? '무료' : '유료',
    isReservationNeeded: false,
    phoneNumber: phoneNumber,
    link: link,
    filters: filters,
    isSpotlight: false,
    isOverThisMonth: false,
    isBookmark: false,
    startDate: '2026-07-01',
    endDate: '',
  );
}

class _FakeReportPlaceSearchRepository implements ReportPlaceSearchRepository {
  const _FakeReportPlaceSearchRepository();

  static const _places = [
    ReportPlace(name: '용산역사박물관', address: '서울 용산구 한강대로14길 35-29'),
    ReportPlace(name: '문틈박물관', address: '강원 원주시 중앙로 42'),
  ];

  @override
  Future<List<ReportPlace>> search(String query) async {
    final normalized = query.replaceAll(RegExp(r'\s+'), '');
    return _places
        .where(
          (place) =>
              place.name.replaceAll(RegExp(r'\s+'), '').contains(normalized) ||
              place.address.replaceAll(RegExp(r'\s+'), '').contains(normalized),
        )
        .toList();
  }
}

class _MissingPeriodApiClient extends ApiClient {
  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authorized = false,
  }) async {
    if (path == ApiEndpoints.programsHotKeywords) {
      return {
        'data': {
          'content': [
            {
              'id': 'open-ended-program',
              'title': '상시 프로그램',
              'status': 'ACTIVE',
              'startDate': null,
              'endDate': null,
            },
          ],
          'page': 0,
          'size': 20,
          'totalElements': 1,
          'totalPages': 1,
          'first': true,
          'last': true,
          'hasPrevious': false,
          'hasNext': false,
        },
      };
    }
    if (path == ApiEndpoints.program('open-ended-program')) {
      return {
        'data': {
          'id': 'open-ended-program',
          'title': '상시 프로그램',
          'status': 'ACTIVE',
          'startDate': null,
          'endDate': null,
          'operatingPeriodMeta': '2026.01.01',
        },
      };
    }
    throw StateError('Unexpected API path: $path');
  }
}

class _HotKeywordFilterApiClient extends ApiClient {
  String? lastPath;
  Map<String, dynamic>? lastQueryParameters;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authorized = false,
  }) async {
    lastPath = path;
    lastQueryParameters = queryParameters;
    return {
      'data': {
        'content': <Map<String, dynamic>>[],
        'page': queryParameters?['page'] ?? 0,
        'size': queryParameters?['size'] ?? 20,
        'totalElements': 0,
        'totalPages': 0,
        'first': true,
        'last': true,
        'hasPrevious': false,
        'hasNext': false,
      },
    };
  }
}

class _ProgramReactionApiClient extends ApiClient {
  String? lastPath;
  Map<String, dynamic>? lastBody;
  Map<String, dynamic>? lastQueryParameters;
  bool? lastAuthorized;

  @override
  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    bool authorized = false,
  }) async {
    lastPath = path;
    lastBody = body;
    lastAuthorized = authorized;
    return {
      'data': {
        'myReaction': body?['reactionState'] == 'NONE'
            ? null
            : body?['reactionState'],
      },
    };
  }

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authorized = false,
  }) async {
    lastPath = path;
    lastQueryParameters = queryParameters;
    lastAuthorized = authorized;
    return {
      'data': {
        'content': [
          {'id': 'reaction-program', 'title': '반응 프로그램'},
        ],
        'page': 2,
        'size': 20,
        'totalElements': 1,
        'totalPages': 3,
        'first': false,
        'last': true,
        'hasPrevious': true,
        'hasNext': false,
      },
    };
  }
}
