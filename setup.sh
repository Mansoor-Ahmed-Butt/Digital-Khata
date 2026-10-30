#!/usr/bin/env bash
# One-time setup: generates the Android/iOS folders, applies native settings,
# fetches packages, then runs the static checks and the tests.
set -euo pipefail
cd "$(dirname "$0")"

command -v flutter >/dev/null || { echo "Flutter SDK not found on PATH"; exit 1; }

# `flutter create` must not touch our code.
tmp="$(mktemp -d)"
cp -r lib "$tmp/lib"; cp pubspec.yaml "$tmp/pubspec.yaml"; cp -r test "$tmp/test"
flutter create --org com.hexovate --project-name digital_khata --platforms android,ios .
rm -rf lib test && cp -r "$tmp/lib" lib && cp -r "$tmp/test" test && cp "$tmp/pubspec.yaml" pubspec.yaml

python3 tool/patch_platforms.py
flutter pub get
dart format lib test >/dev/null
flutter analyze
flutter test
echo "Done. Run with: flutter run"
