class ApiException implements Exception {
  final int? statusCode;
  final String? code;
  final String message;
  final Object? body;

  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.body,
  });

  @override
  String toString() {
    final status = statusCode == null ? '' : '[$statusCode] ';
    final errorCode = code == null ? '' : '($code) ';
    return '$status$errorCode$message';
  }
}
