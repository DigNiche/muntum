import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/api/api_response.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/models/program_reaction.dart';
import 'package:muntum/screens/bookmark/components/went_to_records_view.dart';
import 'package:muntum/screens/program_detail/program_detail_screen.dart';
import 'package:muntum/services/program_reaction_service.dart';

void main() {
  Future<void> pumpRecords(
    WidgetTester tester,
    _ReactionService service,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (_, child) => MaterialApp(home: Scaffold(body: child)),
        child: WentToRecordsView(service: service),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final reaction in ProgramReaction.values) {
    for (final target in ['reaction', 'comment']) {
      testWidgets('$reaction $target whitespace opens the record editor', (
        tester,
      ) async {
        await pumpRecords(tester, _ReactionService()..reaction = reaction);
        final area = tester.getRect(
          find.byKey(ValueKey('edit-visit-$target-program-id')),
        );
        final text = tester.getRect(
          target == 'comment'
              ? find.byKey(const ValueKey('visit-comment-text-program-id'))
              : find.text(reaction == ProgramReaction.like ? '좋았어요' : '아쉬웠어요'),
        );
        final whitespace = Offset(area.right - 2, text.center.dy);
        expect(whitespace.dx, greaterThan(text.right));
        await tester.tapAt(whitespace);
        await tester.pumpAndSettle();
        expect(find.text('기록 남기기'), findsOneWidget);
        expect(find.byType(ProgramDetailScreen), findsNothing);
        expect(
          tester
              .widget<TextField>(
                find.byKey(const ValueKey('visit-comment-input')),
              )
              .controller!
              .text,
          '첫 기록',
        );
      });
    }

    for (final target in ['title', 'image']) {
      testWidgets('$reaction $target opens only the program detail', (
        tester,
      ) async {
        await pumpRecords(tester, _ReactionService()..reaction = reaction);
        await tester.tap(
          find.byKey(ValueKey('visit-program-$target-program-id')),
        );
        await tester.pumpAndSettle();
        final detail = tester.widget<ProgramDetailScreen>(
          find.byType(ProgramDetailScreen),
        );
        expect(detail.program.id, 'program-id');
        expect(
          detail.entrySource,
          reaction == ProgramReaction.like ? 'went_to_like' : 'went_to_dislike',
        );
        expect(find.byKey(const ValueKey('visit-comment-input')), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    for (final target in ['reaction', 'comment', 'pencil']) {
      testWidgets('$reaction $target opens the existing editor, not detail', (
        tester,
      ) async {
        final service = _ReactionService()..reaction = reaction;
        await pumpRecords(tester, service);
        final key = switch (target) {
          'reaction' => 'edit-visit-reaction-program-id',
          'comment' => 'visit-comment-text-program-id',
          _ => 'edit-visit-record-program-id',
        };
        await tester.tap(find.byKey(ValueKey(key)));
        await tester.pumpAndSettle();
        expect(find.text('기록 남기기'), findsOneWidget);
        expect(find.byType(ProgramDetailScreen), findsNothing);
        final input = tester.widget<TextField>(
          find.byKey(const ValueKey('visit-comment-input')),
        );
        expect(input.controller!.text, '첫 기록');

        await tester.enterText(
          find.byKey(const ValueKey('visit-comment-input')),
          '내용으로 수정한 기록',
        );
        await tester.tap(find.byKey(const ValueKey('save-visit-record')));
        await tester.pumpAndSettle();
        expect(service.lastComment, '내용으로 수정한 기록');
        expect(find.text('내용으로 수정한 기록'), findsOneWidget);
        expect(find.byType(ProgramDetailScreen), findsNothing);
      });
    }
  }

  testWidgets('the card background does not open detail or the editor', (
    tester,
  ) async {
    await pumpRecords(tester, _ReactionService());
    final card = tester.getRect(
      find.byKey(const ValueKey('visit-record-body-program-id')),
    );
    await tester.tapAt(card.topLeft + const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(find.byType(ProgramDetailScreen), findsNothing);
    expect(find.byKey(const ValueKey('visit-comment-input')), findsNothing);
  });

  testWidgets('vault shows my comment and opens the shared record editor', (
    tester,
  ) async {
    final service = _ReactionService();
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(home: Scaffold(body: child)),
        child: WentToRecordsView(service: service),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('좋았어요'), findsOneWidget);
    expect(find.text('첫 기록'), findsOneWidget);
    expect(find.text('더보기'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('edit-visit-record-program-id')),
    );
    await tester.pumpAndSettle();
    expect(find.text('기록 남기기'), findsOneWidget);
    final like = tester.getRect(
      find.byKey(const ValueKey('sheet-like-circle')),
    );
    final dislike = tester.getRect(
      find.byKey(const ValueKey('sheet-dislike-circle')),
    );
    expect(dislike.left - like.right, closeTo(20.w, .01));
    expect(find.text('첫 기록'), findsNWidgets(2));

    await tester.enterText(
      find.byKey(const ValueKey('visit-comment-input')),
      '수정한 기록',
    );
    await tester.tap(find.byKey(const ValueKey('save-visit-record')));
    await tester.pumpAndSettle();
    expect(service.lastComment, '수정한 기록');
    expect(find.text('수정한 기록'), findsOneWidget);
  });

  testWidgets(
    'long visit comment expands and collapses without opening a program',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = _ReactionService()
        ..comment = List.generate(
          6,
          (index) => '기억에 남는 내용 ${index + 1}',
        ).join('\n');
      await tester.pumpWidget(
        ScreenUtilPlusInit(
          designSize: const Size(390, 844),
          builder: (_, child) => MaterialApp(home: Scaffold(body: child)),
          child: WentToRecordsView(service: service),
        ),
      );
      await tester.pumpAndSettle();
      final comment = find.byKey(
        const ValueKey('visit-comment-text-program-id'),
      );
      final collapsedHeight = tester.getSize(comment).height;
      expect(find.text('더보기'), findsOneWidget);
      await tester.tap(find.text('더보기'));
      await tester.pumpAndSettle();
      expect(find.text('접기'), findsOneWidget);
      expect(tester.getSize(comment).height, greaterThan(collapsedHeight));
      await tester.tap(find.text('접기'));
      await tester.pumpAndSettle();
      expect(tester.getSize(comment).height, collapsedHeight);
      expect(find.byType(ProgramDetailScreen), findsNothing);
      expect(find.byKey(const ValueKey('visit-comment-input')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

class _ReactionService extends ProgramReactionService {
  ProgramReaction reaction = ProgramReaction.like;
  String comment = '첫 기록';
  String? lastComment;

  @override
  Future<PageResponse<ProgramModel>> fetchMyPrograms({
    required ProgramReaction reaction,
    int page = 0,
    int size = 20,
  }) async {
    return PageResponse.fromList(
      reaction == this.reaction
          ? [
              ProgramModel.fromJson({'id': 'program-id', 'title': '전시'}),
            ]
          : <ProgramModel>[],
    );
  }

  @override
  Future<ProgramReactionSummary> fetchMyRecord(String programId) async {
    return ProgramReactionSummary(myReaction: reaction, myComment: comment);
  }

  @override
  Future<ProgramReactionRecord> updateReaction({
    required String programId,
    required ProgramReaction? reaction,
    String? comment,
  }) async {
    lastComment = comment;
    this.comment = comment ?? '';
    return ProgramReactionRecord(reaction: reaction, comment: comment);
  }
}
