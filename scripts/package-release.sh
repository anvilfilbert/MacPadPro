#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${VERSION:-$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$ROOT_DIR/Resources/Info.plist")}"
APP_DIR="$ROOT_DIR/build/MacPad Pro.app"
DIST_DIR="$ROOT_DIR/dist"
ZIP_PATH="$DIST_DIR/MacPadPro-${VERSION}-macOS-universal.zip"
TMP_ZIP="$DIST_DIR/MacPadPro-${VERSION}-macOS-universal.zip.tmp"
CHECKSUM_PATH="$ZIP_PATH.sha256"
NOTARIZE="${NOTARIZE:-0}"

create_zip() {
  /bin/rm -f "$ZIP_PATH" "$TMP_ZIP"
  (
    cd "$ROOT_DIR/build"
    COPYFILE_DISABLE=1 /usr/bin/zip -qry "$TMP_ZIP" "MacPad Pro.app"
  )
  /bin/mv "$TMP_ZIP" "$ZIP_PATH"
  /usr/bin/shasum -a 256 "$ZIP_PATH" > "$CHECKSUM_PATH"
}

"$ROOT_DIR/scripts/build-app.sh"
mkdir -p "$DIST_DIR"
create_zip

if [[ "$NOTARIZE" == "1" ]]; then
  : "${APPLE_ID:?Set APPLE_ID for notarization}"
  : "${APPLE_TEAM_ID:?Set APPLE_TEAM_ID for notarization}"
  : "${APPLE_APP_SPECIFIC_PASSWORD:?Set APPLE_APP_SPECIFIC_PASSWORD for notarization}"
  /usr/bin/xcrun notarytool submit "$ZIP_PATH" \
    --apple-id "$APPLE_ID" \
    --team-id "$APPLE_TEAM_ID" \
    --password "$APPLE_APP_SPECIFIC_PASSWORD" \
    --wait
  /usr/bin/xcrun stapler staple "$APP_DIR"
  create_zip
fi

echo "Packaged $ZIP_PATH"
echo "Wrote $CHECKSUM_PATH"
