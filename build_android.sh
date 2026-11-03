#!/bin/bash
# Builds a release APK/AAB and keeps a version-labelled copy beside the original.
# Usage: bash build_android.sh [apk|appbundle] [--skip-clean]
# Use --skip-clean when an earlier iOS build must remain in build/.
set -euo pipefail

build_type="${1:-apk}"
case "$build_type" in
  apk|appbundle) ;;
  *)
    echo "사용법: bash build_android.sh [apk|appbundle] [--skip-clean]" >&2
    exit 1
    ;;
esac

if [[ $# -gt 2 || ( $# -eq 2 && "$2" != '--skip-clean' ) ]]; then
  echo "사용법: bash build_android.sh [apk|appbundle] [--skip-clean]" >&2
  exit 1
fi

cd "$(dirname "${BASH_SOURCE[0]}")"

app_version=$(awk '$1 == "version:" {print $2; exit}' pubspec.yaml)
if [[ ! "$app_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+$ ]]; then
  echo "pubspec.yaml의 version을 확인해주세요. 예: 1.1.4+21" >&2
  exit 1
fi

version_name="${app_version%+*}"
build_number="${app_version##*+}"

if [[ "${2:-}" != '--skip-clean' ]]; then
  flutter clean
fi
flutter pub get
flutter build "$build_type" --release

if [[ "$build_type" == 'apk' ]]; then
  output_dir='build/app/outputs/flutter-apk'
  extension='apk'
else
  output_dir='build/app/outputs/bundle/release'
  extension='aab'
fi

shared_file="$output_dir/muntum-$version_name($build_number).$extension"
cp "$output_dir/app-release.$extension" "$shared_file"
echo "공유용 파일: $PWD/$shared_file"
