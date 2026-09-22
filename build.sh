#!/usr/bin/env bash
# Build SunrisePomodoro and assemble a menu-bar-only .app bundle.
set -euo pipefail
cd "$(dirname "$0")"

CONFIG="${1:-release}"
APP="dist/Sunrise Pomodoro.app"

echo "==> swift build -c $CONFIG"
swift build -c "$CONFIG"

BIN=".build/$CONFIG/SunrisePomodoro"

echo "==> assembling $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/SunrisePomodoro"
cp Info.plist "$APP/Contents/Info.plist"
[ -f AppIcon.icns ] && cp AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

# Ad-hoc sign so notifications work and Gatekeeper is happy locally.
codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || true

echo "==> built: $APP"
echo "    run with:  open \"$APP\""
