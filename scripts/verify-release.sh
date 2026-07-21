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

privacy_pattern="f""bauer|F""rank|/""Users/|192\.168\.[0-9]{1,3}\.[0-9]{1,3}|10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[0-1])\.[0-9]{1,3}\.[0-9]{1,3}|[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}|sk-""proj|sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9_]{20,}|gho_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{20,}|xox[baprs]-[A-Za-z0-9-]{20,}|AIza[A-Za-z0-9_-]{20,}|BEGIN [A-Z ]*PRIVATE KEY"
for executable in "$APP_DIR/Contents/MacOS/MacPadPro" "$APP_DIR/Contents/MacOS/MacPadProScriptRunner"; do
  if /usr/bin/strings "$executable" | /usr/bin/grep -Eq "$privacy_pattern"; then
    echo "Release executable contains private information or secret-like values: $executable" >&2
    exit 1
  fi
done

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
