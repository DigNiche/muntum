import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/utils/apple_identity_subject.dart';

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
}
