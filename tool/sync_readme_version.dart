import 'dart:io';

void main() {
  final pubspecFile = File('pubspec.yaml');
  final readmeFile = File('README.md');

  if (!pubspecFile.existsSync() || !readmeFile.existsSync()) {
    stderr.writeln('프로젝트 루트에서 실행해 주세요.');
    exitCode = 1;
    return;
  }

  final versionMatch = RegExp(
    r'^version:\s*([^\s+]+)\+(\d+)\s*$',
    multiLine: true,
  ).firstMatch(pubspecFile.readAsStringSync());

  if (versionMatch == null) {
    stderr.writeln('pubspec.yaml에서 version을 찾을 수 없습니다.');
    exitCode = 1;
    return;
  }

  final versionName = versionMatch.group(1);
  final buildNumber = versionMatch.group(2);
  final versionText = '$versionName ($buildNumber)';
  final markerPattern = RegExp(r'<!-- APP_VERSION -->.*?<!-- /APP_VERSION -->');
  final readme = readmeFile.readAsStringSync();

  if (!markerPattern.hasMatch(readme)) {
    stderr.writeln('README.md에서 버전 마커를 찾을 수 없습니다.');
    exitCode = 1;
    return;
  }

  final updated = readme.replaceFirst(
    markerPattern,
    '<!-- APP_VERSION -->$versionText<!-- /APP_VERSION -->',
  );

  if (updated != readme) {
    readmeFile.writeAsStringSync(updated);
    stdout.writeln('README 버전을 $versionText로 업데이트했습니다.');
  }
}
