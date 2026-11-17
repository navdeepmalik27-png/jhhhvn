#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

echo "=== Come On: Building Android APK ==="
if ! command -v flutter >/dev/null 2>&1; then
  echo "Error: Flutter SDK is not installed or not on PATH." >&2
  exit 1
fi

flutter create --empty --platforms=android .
flutter pub get
flutter build apk --release

echo "Done! Android APK: build/app/outputs/flutter-apk/app-release.apk"
