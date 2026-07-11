#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/build/MacPad Pro.app"
BINARY_PATH="$APP_DIR/Contents/MacOS/MacPadPro"
INFO_PLIST="$APP_DIR/Contents/Info.plist"

fail() {
  echo "Smoke verification failed: $1" >&2
  exit 1
}

test -d "$APP_DIR" || fail "app bundle is missing at $APP_DIR"
test -x "$BINARY_PATH" || fail "app executable is missing or not executable"
test -f "$INFO_PLIST" || fail "Info.plist is missing from app bundle"

bundle_name="$(/usr/libexec/PlistBuddy -c 'Print CFBundleName' "$INFO_PLIST")"
bundle_identifier="$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$INFO_PLIST")"
short_version="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$INFO_PLIST")"

[[ "$bundle_name" == "MacPad Pro" ]] || fail "unexpected bundle name: $bundle_name"
[[ "$bundle_identifier" == "local.macpadpro.app" ]] || fail "unexpected bundle identifier: $bundle_identifier"
[[ -n "$short_version" ]] || fail "empty bundle short version"

swift run MacPadProRepoCheck "$ROOT_DIR"
/usr/bin/codesign --verify --deep --verbose=2 "$APP_DIR"

echo "Smoke verification passed"
