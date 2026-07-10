#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -z "${VERSION:-}" ]]; then
  VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$ROOT_DIR/Resources/Info.plist")"
fi
APP_DIR="$ROOT_DIR/build/MacPad Pro.app"
ZIP_PATH="$ROOT_DIR/dist/MacPadPro-${VERSION}-macOS-universal.zip"

cd "$ROOT_DIR"

"$ROOT_DIR/scripts/verify-public-repo.sh"
"$ROOT_DIR/scripts/package-release.sh"
/usr/bin/codesign --verify --deep --verbose=2 "$APP_DIR"
test -d "$APP_DIR"
test -f "$ZIP_PATH"

echo "Verified $APP_DIR"
echo "Verified $ZIP_PATH"
