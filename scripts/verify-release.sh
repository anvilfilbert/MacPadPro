#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -z "${VERSION:-}" ]]; then
  VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$ROOT_DIR/Resources/Info.plist")"
fi
APP_DIR="$ROOT_DIR/build/MacPad Pro.app"
ZIP_PATH="$ROOT_DIR/dist/MacPadPro-${VERSION}-macOS-universal.zip"
CHECKSUM_PATH="$ZIP_PATH.sha256"

cd "$ROOT_DIR"

if /usr/bin/grep -q "\.testTarget" "$ROOT_DIR/Package.swift"; then
  swift test
else
  echo "No public test target; skipping swift test"
fi
"$ROOT_DIR/scripts/verify-public-repo.sh"
"$ROOT_DIR/scripts/package-release.sh"
/usr/bin/codesign --verify --deep --verbose=2 "$APP_DIR"
test -d "$APP_DIR"
test -f "$ZIP_PATH"
test -f "$CHECKSUM_PATH"
"$ROOT_DIR/scripts/verify-smoke.sh"

while IFS= read -r entry; do
  case "$entry" in
    "__MACOSX/"*|*"/__MACOSX/"*|"._"*|*"/._"*)
      echo "Release zip contains macOS metadata file: $entry" >&2
      exit 1
      ;;
    "MacPad Pro.app/"*)
      ;;
    *)
      echo "Release zip contains unexpected top-level entry: $entry" >&2
      exit 1
      ;;
  esac
done < <(/usr/bin/zipinfo -1 "$ZIP_PATH")

echo "Verified $APP_DIR"
echo "Verified $ZIP_PATH"
