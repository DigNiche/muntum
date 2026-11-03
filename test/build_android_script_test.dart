import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory sandbox;
  late File commandLog;

  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('muntum-build-script-');
    await File('build_android.sh').copy('${sandbox.path}/build_android.sh');
    await File(
      '${sandbox.path}/pubspec.yaml',
    ).writeAsString('version: 1.1.4+21\n');
    final bin = await Directory('${sandbox.path}/bin').create();
    commandLog = File('${sandbox.path}/commands.log');
    final flutter = File('${bin.path}/flutter');
    await flutter.writeAsString(r'''#!/bin/bash
set -eu
echo "$*" >> "$COMMAND_LOG"
if [[ "$*" == "${FAIL_COMMAND:-}" ]]; then exit 42; fi
if [[ "$*" == 'build apk --release' ]]; then
  mkdir -p build/app/outputs/flutter-apk
  printf 'apk artifact' > build/app/outputs/flutter-apk/app-release.apk
elif [[ "$*" == 'build appbundle --release' ]]; then
  mkdir -p build/app/outputs/bundle/release
  printf 'aab artifact' > build/app/outputs/bundle/release/app-release.aab
fi
''');
    await Process.run('chmod', ['+x', flutter.path]);
  });

  tearDown(() async => sandbox.delete(recursive: true));

  Future<ProcessResult> run(List<String> args, {String? failCommand}) =>
      Process.run(
        'bash',
        ['${sandbox.path}/build_android.sh', ...args],
        environment: {
          'PATH': '${sandbox.path}/bin:${Platform.environment['PATH']}',
          'COMMAND_LOG': commandLog.path,
          'FAIL_COMMAND': ?failCommand,
        },
      );

  for (final type in ['apk', 'appbundle']) {
    test(
      '$type preserves original and creates the version-labelled copy',
      () async {
        final result = await run([type]);
        expect(result.exitCode, 0, reason: '${result.stderr}');
        final folder = type == 'apk' ? 'flutter-apk' : 'bundle/release';
        final extension = type == 'apk' ? 'apk' : 'aab';
        final output = '${sandbox.path}/build/app/outputs/$folder';
        expect(
          await File('$output/muntum-1.1.4(21).$extension').readAsBytes(),
          await File('$output/app-release.$extension').readAsBytes(),
        );
        expect(await commandLog.readAsLines(), [
          'clean',
          'pub get',
          'build $type --release',
        ]);
      },
    );
  }

  test('defaults to APK', () async {
    expect((await run([])).exitCode, 0);
    expect(await commandLog.readAsLines(), [
      'clean',
      'pub get',
      'build apk --release',
    ]);
  });

  test('skip-clean preserves earlier iOS outputs', () async {
    expect((await run(['apk', '--skip-clean'])).exitCode, 0);
    expect(await commandLog.readAsLines(), ['pub get', 'build apk --release']);
  });

  test('rejects invalid arguments before invoking Flutter', () async {
    for (final args in [
      ['ios'],
      ['apk', '--wrong'],
      ['apk', '--skip-clean', 'extra'],
    ]) {
      expect((await run(args)).exitCode, isNot(0));
    }
    expect(commandLog.existsSync(), isFalse);
  });

  test('rejects missing build number before invoking Flutter', () async {
    await File(
      '${sandbox.path}/pubspec.yaml',
    ).writeAsString('version: 1.1.4\n');
    expect((await run(['apk'])).exitCode, isNot(0));
    expect(commandLog.existsSync(), isFalse);
  });

  for (final command in ['clean', 'pub get', 'build apk --release']) {
    test(
      'stops on $command failure without creating a shared artifact',
      () async {
        expect((await run(['apk'], failCommand: command)).exitCode, 42);
        expect(Directory('${sandbox.path}/build').existsSync(), isFalse);
      },
    );
  }
}
