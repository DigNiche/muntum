import 'package:muntum/api/api_config.dart';

String normalizeImageUrl(String rawUrl) {
  final url = rawUrl.trim();
  if (url.isEmpty) return '';
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  if (url.startsWith('//')) return 'https:$url';
  if (url.startsWith('/')) return '${ApiConfig.baseUrl}$url';
  if (RegExp(r'^[\w-]+(?:\.[\w-]+)+(?:\:\d+)?(?:/|$)').hasMatch(url)) {
    return 'https://$url';
  }
  return '${ApiConfig.baseUrl}/$url';
}

String? normalizeOptionalImageUrl(Object? value) {
  final url = normalizeImageUrl(value?.toString() ?? '');
  return url.isEmpty ? null : url;
}
