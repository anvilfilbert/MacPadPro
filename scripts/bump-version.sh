#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INFO_PLIST="$ROOT_DIR/Resources/Info.plist"

if [[ $# -ne 2 ]]; then
  echo "Usage: scripts/bump-version.sh <short-version> <build-number>" >&2
  exit 2
fi

short_version="$1"
build_number="$2"

if ! [[ "$short_version" =~ ^[0-9]+[.][0-9]+[.][0-9]+$ ]]; then
  echo "Short version must use MAJOR.MINOR.PATCH, got: $short_version" >&2
  exit 2
fi

if ! [[ "$build_number" =~ ^[0-9]+$ ]]; then
  echo "Build number must be numeric, got: $build_number" >&2
  exit 2
fi

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $short_version" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $build_number" "$INFO_PLIST"

echo "Updated MacPad Pro version to $short_version ($build_number)"
