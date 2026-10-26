import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/models/curation_model.dart';
import 'package:muntum/models/report_model.dart';
import 'package:muntum/screens/mypage/common/report_place_search_screen.dart';
import 'package:muntum/screens/mypage/curator/curation_write_screen.dart';
import 'package:muntum/services/curation_service.dart';

void main() {
  Finder formScroll() => find
      .descendant(
        of: find.byType(ListView).first,
        matching: find.byType(Scrollable),
      )
      .first;
  Future<void> open(
    WidgetTester tester,
    _Service service, {
    CurationModel? initial,
  }) async {
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
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => CurationWriteScreen(
                      service: service,
                      initialCuration: initial,
                    ),
                  ),
                ),
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
  }

  Future<void> enter(WidgetTester tester, int index, String text) async {
    await tester.drag(find.byType(ListView).first, const Offset(0, 1600));
    await tester.pumpAndSettle();
    final field = find.byType(TextField).at(index);
    await tester.ensureVisible(field);
    await tester.enterText(field, text);
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
  }

  Future<ButtonSolid> button(WidgetTester tester, String text) async {
    await tester.scrollUntilVisible(
      find.text(text),
      200,
      scrollable: formScroll(),
    );
    final result = tester.widget<ButtonSolid>(
      find.byWidgetPredicate(
        (widget) => widget is ButtonSolid && widget.text == text,
      ),
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, 1600));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets(
    'new note submits without photos but still requires text and place',
    (tester) async {
      final service = _Service();
      await open(tester, service);
      expect((await button(tester, '작성완료')).onTap, isNull);
      await enter(tester, 0, '프로그램');
      await tester.ensureVisible(find.text('장소를 검색해주세요.'));
      await tester.tap(find.text('장소를 검색해주세요.'));
      await tester.pumpAndSettle();
      Navigator.of(
        tester.element(find.byType(ReportPlaceSearchScreen)),
      ).pop(const ReportPlace(name: '장소', address: '주소'));
      await tester.pumpAndSettle();
      await enter(tester, 1, '한줄소개');
      expect((await button(tester, '작성완료')).onTap, isNull);
      await enter(tester, 2, '본문');
      expect((await button(tester, '작성완료')).onTap, isNotNull);
      await tester.scrollUntilVisible(
        find.text('사진 (선택)'),
        200,
        scrollable: formScroll(),
      );
      expect(find.text('0/5'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('작성완료'),
        200,
        scrollable: formScroll(),
      );
      await tester.tap(find.text('작성완료'));
      await tester.pumpAndSettle();
      expect(service.submittedFiles, isEmpty);
      expect(service.savedContent, '본문');
      expect(find.text('소중한 글을 남겨주셔서\n감사합니다.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final withExistingImage in [false, true]) {
    testWidgets('text-only edit saves; existing image=$withExistingImage', (
      tester,
    ) async {
      final service = _Service();
      await open(
        tester,
        service,
        initial: CurationModel.fromJson({
          'id': 'note-id',
          'submittedProgramTitle': '프로그램',
          'submittedPlace': '장소',
          'tagline': '한줄소개',
          'content': '본문',
          'status': 'APPROVED',
          'images': withExistingImage
              ? [
                  {
                    'id': 'photo',
                    'imageUrl': 'https://example.com/existing.jpg',
                    'displayOrder': 0,
                  },
                ]
              : [],
        }),
      );
      expect((await button(tester, '수정완료')).onTap, isNull);
      await enter(tester, 2, '수정 본문');
      expect((await button(tester, '수정완료')).onTap, isNotNull);
      await tester.scrollUntilVisible(
        find.text('수정완료'),
        200,
        scrollable: formScroll(),
      );
      await tester.tap(find.text('수정완료'));
      await tester.pumpAndSettle();
      expect(service.updatedFiles, isEmpty);
      expect(service.savedContent, '수정 본문');
      expect(find.byType(CurationWriteScreen), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}

class _Service extends CurationService {
  List<String>? submittedFiles;
  List<String>? updatedFiles;
  String? savedContent;

  @override
  Future<CurationModel> submit({
    required String programTitle,
    required String place,
    required String tagline,
    required String content,
    List<String> imagePaths = const [],
  }) async {
    submittedFiles = imagePaths;
    savedContent = content;
    return CurationModel.fromJson({'id': 'note-id', 'images': []});
  }

  @override
  Future<CurationModel> update({
    required String id,
    required String programTitle,
    required String place,
    required String tagline,
    required String content,
    List<String> imagePaths = const [],
  }) async {
    updatedFiles = imagePaths;
    savedContent = content;
    return CurationModel.fromJson({'id': id, 'images': []});
  }
}
