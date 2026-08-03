import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/services/update_service.dart';

void main() {
  group('app update policy', () {
    test('Android uses only build numbers', () {
      final installed = AppReleaseVersion.parse('9.0.0', build: 4);
      final latest = AppReleaseVersion.parse('1.0.0', build: 5);

      expect(
        AppUpdatePolicy.isOutdated(
          platform: TargetPlatform.android,
          installed: installed,
          target: latest,
        ),
        isTrue,
      );
    });

    test('Android ignores a higher version name when its build is newer', () {
      final installed = AppReleaseVersion.parse('1.0.0', build: 6);
      final latest = AppReleaseVersion.parse('9.0.0', build: 5);

      expect(
        AppUpdatePolicy.isOutdated(
          platform: TargetPlatform.android,
          installed: installed,
          target: latest,
        ),
        isFalse,
      );
    });

    test('iOS uses only semantic versions', () {
      final installed = AppReleaseVersion.parse('1.0.7', build: 100);
      final latest = AppReleaseVersion.parse('1.0.8', build: 1);

      expect(
        AppUpdatePolicy.isOutdated(
          platform: TargetPlatform.iOS,
          installed: installed,
          target: latest,
        ),
        isTrue,
      );
    });

    test('iOS ignores build differences in the same version', () {
      final installed = AppReleaseVersion.parse('1.0.8', build: 1);
      final latest = AppReleaseVersion.parse('1.0.8', build: 999);

      expect(
        AppUpdatePolicy.isOutdated(
          platform: TargetPlatform.iOS,
          installed: installed,
          target: latest,
        ),
        isFalse,
      );
    });
  });
}
