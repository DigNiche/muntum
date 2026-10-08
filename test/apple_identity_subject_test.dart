import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/utils/apple_identity_subject.dart';
import 'package:muntum/utils/apple_identity_diagnostics.dart';

void main() {
  String token(Object payload) =>
      'header.${base64Url.encode(utf8.encode(jsonEncode(payload))).replaceAll('=', '')}.signature';

  test('extracts only sub from the exact identity token payload', () {
    expect(
      appleIdentitySubject(
        token({'sub': '001234.test-sub', 'email': 'private'}),
      ),
      '001234.test-sub',
    );
  });

  test('malformed tokens and missing or invalid subjects do not throw', () {
    for (final value in [
      '',
      'not-a-token',
      'header.%%%.signature',
      token({'email': 'private'}),
      token({'sub': 123}),
      token({'sub': ''}),
      token(['unexpected']),
    ]) {
      expect(appleIdentitySubject(value), isNull);
    }
  });

  test('extracts sub, aud and email without retaining the token', () {
    final result = appleIdentityDiagnostics(
      token({
        'sub': 'test-sub',
        'aud': 'co.digniche.muntum',
        'email': 'test@example.com',
        'nonce': 'not-for-logging',
      }),
    )!;
    expect(result.sub, 'test-sub');
    expect(result.aud, 'co.digniche.muntum');
    expect(result.email, 'test@example.com');
  });

  test('missing claims stay null and malformed tokens do not throw', () {
    final result = appleIdentityDiagnostics(token({'sub': 'test-sub'}))!;
    expect(result.aud, isNull);
    expect(result.email, isNull);
    final invalid = appleIdentityDiagnostics(token({'aud': 123, 'email': ''}))!;
    expect(invalid.aud, isNull);
    expect(invalid.email, isNull);
    expect(appleIdentityDiagnostics('invalid-token'), isNull);
  });
}
