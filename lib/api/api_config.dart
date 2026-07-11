import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static const defaultBaseUrl = 'https://api.muntum.work';
  static const _dartDefineBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    String envBaseUrl = '';
    try {
      envBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
    } catch (_) {
      envBaseUrl = '';
    }
    final value = _dartDefineBaseUrl.isNotEmpty
        ? _dartDefineBaseUrl
        : envBaseUrl.isNotEmpty
        ? envBaseUrl
        : defaultBaseUrl;
    return value.trim().replaceFirst(RegExp(r'/$'), '');
  }

  static bool get hasBaseUrl => baseUrl.isNotEmpty;
}
