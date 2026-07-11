#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${VERSION:-$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$ROOT_DIR/Resources/Info.plist")}"
APP_DIR="$ROOT_DIR/build/MacPad Pro.app"
DIST_DIR="$ROOT_DIR/dist"
ZIP_PATH="$DIST_DIR/MacPadPro-${VERSION}-macOS-universal.zip"
TMP_ZIP="$DIST_DIR/MacPadPro-${VERSION}-macOS-universal.zip.tmp"
CHECKSUM_PATH="$ZIP_PATH.sha256"

"$ROOT_DIR/scripts/build-app.sh"
mkdir -p "$DIST_DIR"
/bin/rm -f "$ZIP_PATH" "$TMP_ZIP"
(
  cd "$ROOT_DIR/build"
  COPYFILE_DISABLE=1 /usr/bin/zip -qry "$TMP_ZIP" "MacPad Pro.app"
)
/bin/mv "$TMP_ZIP" "$ZIP_PATH"
/usr/bin/shasum -a 256 "$ZIP_PATH" > "$CHECKSUM_PATH"

echo "Packaged $ZIP_PATH"
echo "Wrote $CHECKSUM_PATH"
