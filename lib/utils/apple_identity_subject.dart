import 'dart:convert';

/// Reads only the subject for diagnostics. This does not verify the token;
/// authentication and signature verification remain the backend's responsibility.
String? appleIdentitySubject(String identityToken) {
  try {
    final parts = identityToken.split('.');
    if (parts.length != 3) return null;
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    if (payload is! Map<String, dynamic>) return null;
    final subject = payload['sub'];
    return subject is String && subject.isNotEmpty ? subject : null;
  } on FormatException {
    return null;
  }
}
