#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="Doppel"
UPDATER_NAME="DoppelUpdater"
BUNDLE_ID="com.junowoz.doppel"
UPDATER_BUNDLE_ID="com.junowoz.doppel.updater"
VERSION="0.1.2"
MIN_SYSTEM_VERSION="14.0"

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

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

swift build --arch arm64 --product "$APP_NAME"
swift build --arch arm64 --product "$UPDATER_NAME"
BUILD_BINARY="$(swift build --arch arm64 --show-bin-path)/$APP_NAME"
UPDATER_BUILD_BINARY="$(swift build --arch arm64 --show-bin-path)/$UPDATER_NAME"

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
  <string>$MIN_SYSTEM_VERSION</string>
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
  <string>$MIN_SYSTEM_VERSION</string>
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

codesign --force --sign - --identifier "$UPDATER_BUNDLE_ID" "$UPDATER_BUNDLE" >/dev/null
codesign --force --sign - --identifier "$BUNDLE_ID" --entitlements "$ENTITLEMENTS" "$APP_BUNDLE" >/dev/null

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
