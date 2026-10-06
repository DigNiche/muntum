import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/api/api_response.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/models/program_reaction.dart';
import 'package:muntum/screens/bookmark/components/went_to_records_view.dart';
import 'package:muntum/services/program_reaction_service.dart';

void main() {
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
      expect(tester.takeException(), isNull);
    },
  );
}

class _ReactionService extends ProgramReactionService {
  String comment = '첫 기록';
  String? lastComment;

  @override
  Future<PageResponse<ProgramModel>> fetchMyPrograms({
    required ProgramReaction reaction,
    int page = 0,
    int size = 20,
  }) async {
    return PageResponse.fromList(
      reaction == ProgramReaction.like
          ? [
              ProgramModel.fromJson({'id': 'program-id', 'title': '전시'}),
            ]
          : <ProgramModel>[],
    );
  }

  @override
  Future<ProgramReactionSummary> fetchMyRecord(String programId) async {
    return ProgramReactionSummary(
      myReaction: ProgramReaction.like,
      myComment: comment,
    );
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
