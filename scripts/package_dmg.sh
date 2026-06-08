#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Doppel"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
DMG_PATH="$DIST_DIR/$APP_NAME.dmg"
DMG_ASSETS_DIR="$DIST_DIR/dmg-assets"
BACKGROUND_PNG="$DMG_ASSETS_DIR/background.png"
APPDMG_CONFIG="$DMG_ASSETS_DIR/appdmg.json"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"

if [[ ! -d "$APP_BUNDLE" ]]; then
  "$ROOT_DIR/scripts/build_release.sh"
fi

if ! command -v npx >/dev/null 2>&1; then
  echo "error: npx is required to package the DMG with a Finder install layout" >&2
  exit 1
fi

rm -rf "$DMG_ASSETS_DIR"
rm -f "$DMG_PATH" "$DMG_PATH.sha256"

cleanup() {
  rm -rf "$DMG_ASSETS_DIR"
}
trap cleanup EXIT

mkdir -p "$DMG_ASSETS_DIR"
swift "$ROOT_DIR/scripts/create_dmg_background.swift" "$BACKGROUND_PNG"

cat > "$APPDMG_CONFIG" <<JSON
{
  "title": "$APP_NAME",
  "icon": "$ROOT_DIR/DoppelApp/Resources/Doppel.icns",
  "background": "$BACKGROUND_PNG",
  "icon-size": 112,
  "window": {
    "position": { "x": 120, "y": 120 },
    "size": { "width": 640, "height": 400 }
  },
  "contents": [
    { "x": 130, "y": 205, "type": "file", "path": "$APP_BUNDLE" },
    { "x": 510, "y": 205, "type": "link", "path": "/Applications" }
  ],
  "format": "UDZO",
  "filesystem": "HFS+"
}
JSON

npm_config_cache="$DMG_ASSETS_DIR/npm-cache" \
npm_config_update_notifier=false \
  npx --yes appdmg@0.6.6 "$APPDMG_CONFIG" "$DMG_PATH"
codesign --force --sign "$CODESIGN_IDENTITY" "$DMG_PATH"
shasum -a 256 "$DMG_PATH" > "$DMG_PATH.sha256"
trap - EXIT
cleanup

echo "Packaged $DMG_PATH"
