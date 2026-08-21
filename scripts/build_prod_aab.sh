#!/usr/bin/env bash
# Build a Play Store–ready Android App Bundle (prod flavor, release signing).
# Prerequisites:
#   - android/key.properties (from key.properties.example)
#   - android/upload-keystore.jks (or path in key.properties storeFile)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ ! -f android/key.properties ]]; then
  echo "error: missing android/key.properties" >&2
  echo "  cp android/key.properties.example android/key.properties" >&2
  echo "  then create the keystore — see docs/STORE_RELEASE_CHECKLIST.md" >&2
  exit 1
fi

STORE_FILE="$(awk -F= '/^storeFile=/ {print $2}' android/key.properties | tr -d '\r')"
if [[ -z "$STORE_FILE" ]]; then
  echo "error: storeFile missing in android/key.properties" >&2
  exit 1
fi
if [[ ! -f "android/$STORE_FILE" ]]; then
  echo "error: keystore not found at android/$STORE_FILE" >&2
  exit 1
fi

echo "Building prod release AAB (applicationId com.mpsec.mpsecnet)..."
flutter build appbundle \
  --release \
  --flavor prod \
  --dart-define=APP_FLAVOR=prod

AAB="build/app/outputs/bundle/prodRelease/app-prod-release.aab"
echo "Done: $AAB"
ls -lh "$AAB"
