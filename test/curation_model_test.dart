import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/api/api_config.dart';
import 'package:muntum/models/curation_model.dart';

void main() {
  test('revised pending curation uses retained change-request reason', () {
    final first = CurationModel.fromJson({
      'status': 'PENDING',
      'createdAt': '2026-09-01T10:00:00',
      'updatedAt': '2026-09-02T10:00:00',
    });
    final revised = CurationModel.fromJson({
      'status': 'PENDING',
      'changeRequestReason': '내용을 수정해 주세요.',
    });
    expect(first.isRevisedPending, isFalse);
    expect(revised.isRevisedPending, isTrue);
  });

  test('public curation parses author and normalized thumbnail', () {
    final curation = PublicCurationModel.fromJson({
      'id': 'curation-id',
      'curator': {'nickname': '문틈 큐레이터'},
      'tagline': '한줄소개',
      'thumbnailUrl': '/uploads/note.jpg',
    });
    expect(curation.curatorName, '문틈 큐레이터');
    expect(curation.thumbnailUrl, '${ApiConfig.baseUrl}/uploads/note.jpg');
    final detail = PublicCurationModel.fromJson({
      'id': 'curation-id',
      'content': '상세 본문',
    });
    final merged = curation.mergeDetails(detail);
    expect(merged.thumbnailUrl, curation.thumbnailUrl);
    expect(merged.content, '상세 본문');
  });

  test('public curation keeps an optional creation date from detail', () {
    final summary = PublicCurationModel.fromJson({
      'id': 'note-id',
      'createdAt': '2026-12-12T10:00:00',
    });
    final detail = PublicCurationModel.fromJson({'id': 'note-id'});
    expect(summary.mergeDetails(detail).formattedCreatedAt, '26.12.12');
    expect(detail.formattedCreatedAt, isEmpty);
  });

  test('curation image URLs are usable by Image.network', () {
    String parse(String url) =>
        CurationImageModel.fromJson({'id': '1', 'imageUrl': url}).imageUrl;

    expect(
      parse('https://cdn.example.com/image.jpg'),
      'https://cdn.example.com/image.jpg',
    );
    expect(
      parse('cdn.example.com/image.jpg'),
      'https://cdn.example.com/image.jpg',
    );
    expect(
      parse('//cdn.example.com/image.jpg'),
      'https://cdn.example.com/image.jpg',
    );
    expect(
      parse('/uploads/image.jpg'),
      '${ApiConfig.baseUrl}/uploads/image.jpg',
    );
    expect(
      parse('uploads/image.jpg'),
      '${ApiConfig.baseUrl}/uploads/image.jpg',
    );
  });
}
