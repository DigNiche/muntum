import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/models/curation_model.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/mypage/curator/curation_write_screen.dart';
import 'package:muntum/services/program_service.dart';

void main() {
  testWidgets('linked program title replaces the submitted placeholder', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final programs = _LinkedProgramService();
    final curation = CurationModel.fromJson({
      'id': 'curation-id',
      'programId': 'program-id',
      'submittedProgramTitle': '테스트 수정',
      'submittedPlace': '장소',
      'tagline': '한줄소개',
      'content': '소개글',
      'images': const [],
      'status': 'CHANGES_REQUESTED',
    });
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (_, _) => MaterialApp(
          home: CurationWriteScreen(
            initialCuration: curation,
            programService: programs,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(programs.loadedId, 'program-id');
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      '성률 개인전 [Cloud 9]',
    );
  });
}

class _LinkedProgramService extends ProgramService {
  String? loadedId;

  @override
  Future<ProgramModel> fetchProgram(
    String id, {
    bool authorized = false,
  }) async {
    loadedId = id;
    return ProgramModel.fromJson({
      'id': id,
      'title': '성률 개인전 [Cloud 9]',
      'venueName': '장소',
      'programType': 'EXHIBITION',
    });
  }
}
