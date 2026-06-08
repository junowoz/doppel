#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Doppel"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
DMG_PATH="$DIST_DIR/$APP_NAME.dmg"

if [[ ! -d "$APP_BUNDLE" ]]; then
  "$ROOT_DIR/scripts/build_release.sh"
fi

rm -f "$DMG_PATH"
hdiutil create -volname "$APP_NAME" -srcfolder "$APP_BUNDLE" -ov -format UDZO "$DMG_PATH"
shasum -a 256 "$DMG_PATH" > "$DMG_PATH.sha256"

echo "Packaged $DMG_PATH"
