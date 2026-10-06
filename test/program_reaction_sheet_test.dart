import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/api/api_client.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/models/program_reaction.dart';
import 'package:muntum/screens/program_detail/components/program_attendance_prompt.dart';
import 'package:muntum/screens/program_detail/components/program_reaction_sheet.dart';
import 'package:muntum/services/program_reaction_service.dart';

void main() {
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
