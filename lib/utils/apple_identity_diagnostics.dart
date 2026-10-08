import 'dart:convert';

class AppleIdentityDiagnostics {
  final String? sub;
  final String? aud;
  final String? email;

  const AppleIdentityDiagnostics({this.sub, this.aud, this.email});
}

/// Diagnostic decoding only; the backend must verify the token's signature.
AppleIdentityDiagnostics? appleIdentityDiagnostics(String identityToken) {
  try {
    final parts = identityToken.split('.');
    if (parts.length != 3) return null;
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    if (payload is! Map<String, dynamic>) return null;
    String? claim(String key) {
      final value = payload[key];
      return value is String && value.isNotEmpty ? value : null;
    }

    return AppleIdentityDiagnostics(
      sub: claim('sub'),
      aud: claim('aud'),
      email: claim('email'),
    );
  } on FormatException {
    return null;
  }
}
