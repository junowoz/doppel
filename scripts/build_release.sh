#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Doppel"
UPDATER_NAME="DoppelUpdater"
BUNDLE_ID="com.junowoz.doppel"
UPDATER_BUNDLE_ID="com.junowoz.doppel.updater"
VERSION="${VERSION:-0.1.2}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_HELPERS="$APP_CONTENTS/Library/Helpers"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
UPDATER_BUNDLE="$APP_HELPERS/$UPDATER_NAME.app"
UPDATER_CONTENTS="$UPDATER_BUNDLE/Contents"
UPDATER_MACOS="$UPDATER_CONTENTS/MacOS"
UPDATER_BINARY="$UPDATER_MACOS/$UPDATER_NAME"
UPDATER_INFO_PLIST="$UPDATER_CONTENTS/Info.plist"
ICON_FILE="$ROOT_DIR/DoppelApp/Resources/Doppel.icns"
ENTITLEMENTS="$ROOT_DIR/DoppelApp/Resources/Doppel.entitlements"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"

cd "$ROOT_DIR"

swift test
swift build -c release --arch arm64 --product "$APP_NAME"
swift build -c release --arch arm64 --product "$UPDATER_NAME"

BUILD_BINARY="$(swift build -c release --arch arm64 --show-bin-path)/$APP_NAME"
UPDATER_BUILD_BINARY="$(swift build -c release --arch arm64 --show-bin-path)/$UPDATER_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES" "$UPDATER_MACOS"
cp "$BUILD_BINARY" "$APP_BINARY"
cp "$UPDATER_BUILD_BINARY" "$UPDATER_BINARY"
cp "$ICON_FILE" "$APP_RESOURCES/Doppel.icns"
chmod +x "$APP_BINARY"
chmod +x "$UPDATER_BINARY"

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

cat >"$UPDATER_INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$UPDATER_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$UPDATER_BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>Doppel Updater</string>
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
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

ARCHS="$(lipo -archs "$APP_BINARY")"
if [[ "$ARCHS" != "arm64" ]]; then
  echo "Expected an Apple Silicon-only arm64 binary, got: $ARCHS" >&2
  exit 1
fi
UPDATER_ARCHS="$(lipo -archs "$UPDATER_BINARY")"
if [[ "$UPDATER_ARCHS" != "arm64" ]]; then
  echo "Expected an Apple Silicon-only updater binary, got: $UPDATER_ARCHS" >&2
  exit 1
fi

codesign --force --sign "$CODESIGN_IDENTITY" --identifier "$UPDATER_BUNDLE_ID" "$UPDATER_BUNDLE"
codesign --force --sign "$CODESIGN_IDENTITY" --identifier "$BUNDLE_ID" --entitlements "$ENTITLEMENTS" "$APP_BUNDLE"
codesign --verify --deep --strict "$APP_BUNDLE"

ditto -c -k --norsrc --noextattr --keepParent "$APP_BUNDLE" "$DIST_DIR/$APP_NAME.app.zip"
shasum -a 256 "$DIST_DIR/$APP_NAME.app.zip" > "$DIST_DIR/$APP_NAME.app.zip.sha256"

echo "Built $APP_BUNDLE"
