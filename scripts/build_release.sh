#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Doppel"
BUNDLE_ID="com.junowoz.doppel"
VERSION="${VERSION:-0.1.1}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
ICON_FILE="$ROOT_DIR/DoppelApp/Resources/Doppel.icns"
ENTITLEMENTS="$ROOT_DIR/DoppelApp/Resources/Doppel.entitlements"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"

cd "$ROOT_DIR"

swift test
swift build -c release --arch arm64

BUILD_BINARY="$(swift build -c release --arch arm64 --show-bin-path)/$APP_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
cp "$ICON_FILE" "$APP_RESOURCES/Doppel.icns"
chmod +x "$APP_BINARY"

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundleIconFile</key>
  <string>Doppel</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>LSArchitecturePriority</key>
  <array>
    <string>arm64</string>
  </array>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

ARCHS="$(lipo -archs "$APP_BINARY")"
if [[ "$ARCHS" != "arm64" ]]; then
  echo "Expected an Apple Silicon-only arm64 binary, got: $ARCHS" >&2
  exit 1
fi

codesign --force --deep --sign "$CODESIGN_IDENTITY" --identifier "$BUNDLE_ID" --entitlements "$ENTITLEMENTS" "$APP_BUNDLE"
codesign --verify --deep --strict "$APP_BUNDLE"

ditto -c -k --keepParent "$APP_BUNDLE" "$DIST_DIR/$APP_NAME.app.zip"
shasum -a 256 "$DIST_DIR/$APP_NAME.app.zip" > "$DIST_DIR/$APP_NAME.app.zip.sha256"

echo "Built $APP_BUNDLE"
