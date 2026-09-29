import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';

const supportedUploadImageExtensions = [
  '.jpg',
  '.jpeg',
  '.png',
  '.webp',
  '.gif',
];
const convertibleUploadImageExtensions = ['.heic', '.heif'];

const supportedUploadImageMessage = 'JPG, PNG, WEBP, GIF 또는 HEIC 이미지를 선택해주세요.';

class PreparedUploadImage {
  const PreparedUploadImage({required this.path, required this.isTemporary});

  final String path;
  final bool isTemporary;
}

typedef JpegImageConverter =
    Future<String?> Function(String sourcePath, String targetPath, int quality);

bool isSupportedUploadImagePath(String path) {
  final normalized = path.toLowerCase();
  return supportedUploadImageExtensions.any(normalized.endsWith);
}

bool isConvertibleUploadImagePath(String path) {
  final normalized = path.toLowerCase();
  return convertibleUploadImageExtensions.any(normalized.endsWith);
}

/// 서버가 받지 않는 HEIC/HEIF 이미지를 업로드 전에 JPEG로 변환한다.
/// 이미 지원되는 형식은 원본 경로를 그대로 사용한다.
Future<PreparedUploadImage> prepareImageForUpload(
  String sourcePath, {
  int quality = 88,
  JpegImageConverter? jpegConverter,
}) async {
  if (isSupportedUploadImagePath(sourcePath)) {
    return PreparedUploadImage(path: sourcePath, isTemporary: false);
  }
  if (!isConvertibleUploadImagePath(sourcePath)) {
    throw const FormatException(supportedUploadImageMessage);
  }

  final targetPath =
      '${Directory.systemTemp.path}/muntum_upload_'
      '${DateTime.now().microsecondsSinceEpoch}.jpg';
  final convertedPath = jpegConverter == null
      ? (await FlutterImageCompress.compressAndGetFile(
          sourcePath,
          targetPath,
          format: CompressFormat.jpeg,
          quality: quality,
          autoCorrectionAngle: true,
          keepExif: false,
        ))?.path
      : await jpegConverter(sourcePath, targetPath, quality);
  if (convertedPath == null) {
    throw const FormatException('이미지를 JPG로 변환하지 못했어요. 다른 이미지를 선택해주세요.');
  }
  return PreparedUploadImage(path: convertedPath, isTemporary: true);
}
