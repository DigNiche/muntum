import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/api/api_response.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/program_detail/components/recommended_programs_section.dart';
import 'package:muntum/services/program_service.dart';

void main() {
  final source = _program('source', ['shared']);
  final matching = _program('matching', ['shared']);
  final fallback = _program('fallback', ['different']);

  test('related API fallback is not shown as a same-keyword program', () async {
    final service = _RelatedService([matching, fallback, source]);

    final results = await service.fetchSameKeywordPrograms(source);

    expect(service.requestedId, 'source');
    expect(service.requestedSize, 3);
    expect(results.map((program) => program.id), ['matching']);
  });

  test(
    'programs with no keywords do not request unrelated fallbacks',
    () async {
      final service = _RelatedService([fallback]);
      expect(
        await service.fetchSameKeywordPrograms(_program('empty', [])),
        isEmpty,
      );
      expect(service.requestedId, isNull);
    },
  );

  testWidgets('empty same-keyword results hide the heading', (tester) async {
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(
          home: Scaffold(
            body: RecommendedProgramsSection(
              programsFuture: Future.value(const []),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('같은 키워드의 프로그램'), findsNothing);
  });

  testWidgets('matching results use the same-keyword heading', (tester) async {
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(
          home: Scaffold(
            body: RecommendedProgramsSection(
              programsFuture: Future.value([matching]),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('같은 키워드의 프로그램'), findsOneWidget);
    expect(find.text('🔥인기있는'), findsNothing);
  });
}

ProgramModel _program(String id, List<String> keywordIds) =>
    ProgramModel.fromJson({
      'id': id,
      'title': id,
      'keywords': [
        for (final keywordId in keywordIds)
          {'id': keywordId, 'name': keywordId},
      ],
    });

class _RelatedService extends ProgramService {
  _RelatedService(this.programs);

  final List<ProgramModel> programs;
  String? requestedId;
  int? requestedSize;

  @override
  Future<PageResponse<ProgramModel>> fetchRelatedPrograms(
    String programId, {
    int page = 0,
    int size = 3,
  }) async {
    requestedId = programId;
    requestedSize = size;
    return PageResponse.fromList(programs);
  }
}
