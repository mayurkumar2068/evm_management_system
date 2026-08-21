#!/usr/bin/env bash
# Build an App Store / TestFlight IPA (prod flavor).
# Prerequisites on this Mac:
#   - Xcode with signing team selected for Runner (Automatic Signing)
#   - Valid Apple Distribution cert + App Store provisioning for com.mpsec.mpsecnet
# Optional:
#   - ios/ExportOptions.plist (copy from ExportOptions.plist.example and set teamID)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

EXPORT_ARGS=()
if [[ -f ios/ExportOptions.plist ]]; then
  EXPORT_ARGS+=(--export-options-plist=ios/ExportOptions.plist)
fi

echo "Building prod release IPA (bundle id com.mpsec.mpsecnet)..."
flutter build ipa \
  --release \
  --flavor prod \
  --dart-define=APP_FLAVOR=prod \
  "${EXPORT_ARGS[@]}"

echo "IPA output under: build/ios/ipa/"
ls -lh build/ios/ipa/ 2>/dev/null || true
