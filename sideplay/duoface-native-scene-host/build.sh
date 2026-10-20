#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"
SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
APP="$TMP/var/jb/Applications/DuoFaceNativeHost.app"
mkdir -p "$APP" "$TMP/DEBIAN" "$ROOT/packages"
xcrun --sdk iphoneos clang -target arm64-apple-ios16.0 -isysroot "$SDK" \
  -fobjc-arc -O2 -Wall -Wextra -Werror -Wno-deprecated-declarations \
  -framework UIKit -framework Foundation -framework CarPlay \
  -o "$APP/DuoFaceNativeHost" main.m DFNativeHostAppDelegate.m DFNativeHostRootController.m
cp Info.plist "$APP/Info.plist"
ldid -Sentitlements.plist "$APP/DuoFaceNativeHost"
plutil -lint "$APP/Info.plist"
cp control "$TMP/DEBIAN/control"
# Intentionally no postinst/prerm, no respring, no LS cache modification.
OUT="$ROOT/packages/com.duoface.carplay.nativescenehost_0.0.2~template1_iphoneos-arm64.deb"
dpkg-deb --build "$TMP" "$OUT"
echo "BUILT=$OUT"
