#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIGURATION="${CONFIGURATION:-release}"
UNIVERSAL="${UNIVERSAL:-1}"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"
APP_DIR="$ROOT_DIR/build/MacPad Pro.app"
BINARY_PATH=".build/$CONFIGURATION/MacPadPro"
SCRIPT_RUNNER_PATH=".build/$CONFIGURATION/MacPadProScriptRunner"
STAGE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/macpad-pro-build.XXXXXX")"
STAGED_APP="$STAGE_DIR/MacPad Pro.app"
CONTENTS_DIR="$STAGED_APP/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

cleanup() {
  rm -rf "$STAGE_DIR"
}
trap cleanup EXIT

cd "$ROOT_DIR"
if [[ "$CONFIGURATION" == "release" && "$UNIVERSAL" == "1" ]]; then
  swift build -c "$CONFIGURATION" --arch arm64 --arch x86_64
  BINARY_PATH=".build/apple/Products/Release/MacPadPro"
  SCRIPT_RUNNER_PATH=".build/apple/Products/Release/MacPadProScriptRunner"
else
  swift build -c "$CONFIGURATION"
fi

mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$BINARY_PATH" "$MACOS_DIR/MacPadPro"
cp "$SCRIPT_RUNNER_PATH" "$MACOS_DIR/MacPadProScriptRunner"
chmod +x "$MACOS_DIR/MacPadPro" "$MACOS_DIR/MacPadProScriptRunner"
cp "Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
"$ROOT_DIR/scripts/create-app-icon.sh" "$ROOT_DIR/Resources/MacPadLogo.png" "$RESOURCES_DIR/AppIcon.icns"
/usr/bin/xattr -cr "$STAGED_APP"
if [[ "$CODESIGN_IDENTITY" == "-" ]]; then
  /usr/bin/codesign --force --deep --sign - "$STAGED_APP" >/dev/null
else
  /usr/bin/codesign --force --deep --options runtime --timestamp --sign "$CODESIGN_IDENTITY" "$STAGED_APP" >/dev/null
fi

rm -rf "$APP_DIR"
mkdir -p "$(dirname "$APP_DIR")"
/usr/bin/ditto "$STAGED_APP" "$APP_DIR"

echo "Built $APP_DIR"
