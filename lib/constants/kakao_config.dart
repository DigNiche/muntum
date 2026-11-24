import 'package:flutter_dotenv/flutter_dotenv.dart';

class KakaoConfig {
  const KakaoConfig._();

  // The ignored .env also configures the native callback schemes.
  static String get nativeAppKey => dotenv.isInitialized
      ? (dotenv.env['KAKAO_NATIVE_APP_KEY'] ?? '').trim()
      : '';

  static bool get isConfigured =>
      RegExp(r'^[0-9a-fA-F]{32}$').hasMatch(nativeAppKey);
}
