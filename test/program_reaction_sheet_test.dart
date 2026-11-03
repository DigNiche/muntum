import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/api/api_client.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/program_reaction.dart';
import 'package:muntum/screens/program_detail/components/program_attendance_prompt.dart';
import 'package:muntum/screens/program_detail/components/program_reaction_sheet.dart';
import 'package:muntum/services/program_reaction_service.dart';

void main() {
  for (final asset in ['thumb_up_filled.svg', 'thumb_down_filled.svg']) {
    testWidgets('$asset renders opaque static white pixels', (tester) async {
      await tester.runAsync(() async {
        final picture = await vg.loadPicture(
          SvgAssetLoader('assets/icons/$asset'),
          null,
        );
        final image = await picture.picture.toImage(18, 18);
        final bytes = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final alphas = List.generate(
          bytes.lengthInBytes ~/ 4,
          (index) => bytes.getUint8(index * 4 + 3),
        );
        expect(alphas.reduce((a, b) => a > b ? a : b), 255);
        final opaque = alphas.indexOf(255) * 4;
        expect(
          List.generate(4, (channel) => bytes.getUint8(opaque + channel)),
          [255, 255, 255, 255],
        );
        expect(alphas, contains(0));
        image.dispose();
        picture.picture.dispose();
      });
      expect(tester.takeException(), isNull);
    });
  }
  double glyphCenter(WidgetTester tester, String label) {
    final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
    final boxes = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: label.length),
    );
    final bounds = boxes
        .map((box) => box.toRect())
        .reduce((a, b) => a.expandToInclude(b));
    return paragraph.localToGlobal(bounds.center).dx;
  }

  for (final size in [
    const Size(390, 844),
    const Size(430, 932),
    const Size(1024, 1366),
  ]) {
    for (final reaction in [
      null,
      ProgramReaction.like,
      ProgramReaction.dislike,
    ]) {
      testWidgets('detail circle gap is 20.w at $size reaction=$reaction', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          ScreenUtilPlusInit(
            designSize: const Size(390, 844),
            builder: (_, _) => MaterialApp(
              home: Scaffold(
                body: ProgramAttendancePrompt(
                  programId: 'program-id',
                  initialReaction: reaction,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        Rect circle(String key) => tester.getRect(
          find.descendant(
            of: find.byKey(ValueKey(key)),
            matching: find.byType(AnimatedContainer),
          ),
        );
        final like = circle('detail-like');
        final dislike = circle('detail-dislike');
        expect(dislike.left - like.right, closeTo(20.w, .01));
        expect(like.width, closeTo(48.r, .01));
        expect(dislike.width, closeTo(48.r, .01));
        expect(
          (like.center.dx + dislike.center.dx) / 2,
          closeTo(size.width / 2, .01),
        );
        if (reaction != null) {
          final text = find.text(
            reaction == ProgramReaction.like ? '좋았어요!' : '아쉬웠어요',
          );
          expect(text, findsOneWidget);
          expect(
            glyphCenter(
              tester,
              reaction == ProgramReaction.like ? '좋았어요!' : '아쉬웠어요',
            ),
            closeTo(
              reaction == ProgramReaction.like
                  ? like.center.dx
                  : dislike.center.dx,
              .01,
            ),
          );
          expect(
            tester.getCenter(text).dx,
            closeTo(
              reaction == ProgramReaction.like
                  ? like.center.dx
                  : dislike.center.dx,
              .01,
            ),
          );
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
  Future<void> openSheet(
    WidgetTester tester,
    _ReactionClient client, {
    ProgramReaction? reaction,
    String? comment,
  }) async {
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(home: child),
        child: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showProgramReactionSheet(
                context: context,
                programId: 'program-id',
                initialReaction: reaction,
                initialComment: comment,
                service: ProgramReactionService(client: client),
              ),
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
  }

  for (final size in [
    const Size(390, 844),
    const Size(430, 932),
    const Size(1024, 1366),
  ]) {
    for (final reaction in [
      null,
      ProgramReaction.like,
      ProgramReaction.dislike,
    ]) {
      testWidgets('sheet circle gap is 20.w at $size reaction=$reaction', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await openSheet(tester, _ReactionClient(), reaction: reaction);
        void expectGap() {
          final like = tester.getRect(
            find.byKey(const ValueKey('sheet-like-circle')),
          );
          final dislike = tester.getRect(
            find.byKey(const ValueKey('sheet-dislike-circle')),
          );
          expect(dislike.left - like.right, closeTo(20.w, .01));
          expect(like.width, closeTo(44.r, .01));
          expect(dislike.width, closeTo(44.r, .01));
          expect(
            (like.center.dx + dislike.center.dx) / 2,
            closeTo(size.width / 2, .01),
          );
        }

        expectGap();
        await tester.tap(find.byKey(const ValueKey('sheet-dislike')));
        await tester.pumpAndSettle();
        expectGap();
        expect(
          glyphCenter(tester, '아쉬웠어요'),
          closeTo(
            tester
                .getCenter(find.byKey(const ValueKey('sheet-dislike-circle')))
                .dx,
            .01,
          ),
        );
        expect(
          tester.getCenter(find.text('아쉬웠어요')).dx,
          closeTo(
            tester
                .getCenter(find.byKey(const ValueKey('sheet-dislike-circle')))
                .dx,
            .01,
          ),
        );
        await tester.tap(find.byKey(const ValueKey('sheet-like')));
        await tester.pumpAndSettle();
        expectGap();
        expect(
          glyphCenter(tester, '좋았어요!'),
          closeTo(
            tester
                .getCenter(find.byKey(const ValueKey('sheet-like-circle')))
                .dx,
            .01,
          ),
        );
        expect(
          tester.getCenter(find.text('좋았어요!')).dx,
          closeTo(
            tester
                .getCenter(find.byKey(const ValueKey('sheet-like-circle')))
                .dx,
            .01,
          ),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('record sheet uses Title4 and Button2 design tokens', (
    tester,
  ) async {
    await openSheet(tester, _ReactionClient(), reaction: ProgramReaction.like);
    expect(
      tester.widget<Text>(find.text('기록 남기기')).style,
      AppTypography.title4.copyWith(color: AppColors.gray900),
    );
    expect(
      tester.widget<Text>(find.text('기록 삭제')).style,
      AppTypography.button2.copyWith(color: AppColors.gray500),
    );
    for (final key in ['sheet-like', 'sheet-dislike']) {
      final icon = tester.widget<SvgPicture>(
        find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(SvgPicture),
        ),
      );
      expect(
        icon.colorFilter,
        const ColorFilter.mode(AppColors.white, BlendMode.srcIn),
      );
    }
  });

  testWidgets('cancel keeps the saved record unchanged', (tester) async {
    final client = _ReactionClient();
    await openSheet(
      tester,
      client,
      reaction: ProgramReaction.like,
      comment: '원래 코멘트',
    );
    expect(
      tester.widget<BottomSheet>(find.byType(BottomSheet)).backgroundColor,
      AppColors.white,
    );
    expect(
      tester
          .widget<ButtonSolid>(
            find.byKey(const ValueKey('cancel-visit-record')),
          )
          .boxColor,
      AppColors.white,
    );
    expect(
      tester
          .widget<ButtonSolid>(find.byKey(const ValueKey('save-visit-record')))
          .boxColor,
      AppColors.black,
    );
    expect(find.text('원래 코멘트'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('sheet-dislike')));
    await tester.tap(find.byKey(const ValueKey('cancel-visit-record')));
    await tester.pumpAndSettle();
    expect(client.requests, isEmpty);
  });

  testWidgets('save sends selected reaction and optional comment', (
    tester,
  ) async {
    final client = _ReactionClient();
    await openSheet(tester, client);
    await tester.tap(find.byKey(const ValueKey('sheet-like')));
    await tester.enterText(
      find.byKey(const ValueKey('visit-comment-input')),
      '좋았던 공간',
    );
    await tester.tap(find.byKey(const ValueKey('save-visit-record')));
    await tester.pumpAndSettle();
    expect(client.requests.single, {
      'reactionState': 'LIKE',
      'comment': '좋았던 공간',
    });
  });

  testWidgets('delete sends NONE without a comment', (tester) async {
    final client = _ReactionClient();
    await openSheet(
      tester,
      client,
      reaction: ProgramReaction.dislike,
      comment: '아쉬웠어요',
    );
    await tester.tap(find.byKey(const ValueKey('delete-visit-record')));
    await tester.pumpAndSettle();
    expect(client.requests.single, {'reactionState': 'NONE'});
  });

  testWidgets('detail reaction opens an editor instead of saving immediately', (
    tester,
  ) async {
    final client = _ReactionClient();
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(home: Scaffold(body: child)),
        child: ProgramAttendancePrompt(
          programId: 'program-id',
          initialReaction: null,
          service: ProgramReactionService(client: client),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('detail-like')));
    await tester.pumpAndSettle();
    expect(client.requests, isEmpty);
    expect(find.text('기록 남기기'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('save-visit-record')));
    await tester.pumpAndSettle();
    expect(client.requests.single, {'reactionState': 'LIKE', 'comment': ''});
  });
}

class _ReactionClient extends ApiClient {
  final List<Map<String, dynamic>> requests = [];

  @override
  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    bool authorized = false,
  }) async {
    requests.add(body!);
    return {
      'data': {
        'myReaction': body['reactionState'] == 'NONE'
            ? null
            : body['reactionState'],
        'myComment': body['reactionState'] == 'NONE' ? null : body['comment'],
      },
    };
  }
}
