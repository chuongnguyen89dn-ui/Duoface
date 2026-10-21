#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"
SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
APP="$TMP/var/jb/Applications/DuoFaceNativeHost.app"
mkdir -p "$APP" "$TMP/DEBIAN" "$ROOT/packages" "$TMP/var/jb/Library/MobileSubstrate/DynamicLibraries"
xcrun --sdk iphoneos clang -target arm64-apple-ios16.0 -isysroot "$SDK" \
  -fobjc-arc -O2 -Wall -Wextra -Werror -Wno-deprecated-declarations \
  -framework UIKit -framework CarPlay -framework Foundation -framework QuartzCore -framework CoreGraphics \
  -o "$APP/DuoFaceNativeHost" main.m DFNativeHostAppDelegate.m DFNative12BasicController.m DFNativeHostRootController.m \
  DFNativeHostSurfaceView.m ../mytweak-independent-v1a/prototype/MTCPBridgeContract.m
# Separate SpringBoard input receiver: no implicit overlay at jailbreak startup.
DYLIB="$TMP/var/jb/Library/MobileSubstrate/DynamicLibraries/DFTouchOwnerProbe.dylib"
xcrun --sdk iphoneos clang -dynamiclib -target arm64-apple-ios16.0 -isysroot "$SDK" \
  -fobjc-arc -O2 -Wall -Wextra -Werror -Wno-deprecated-declarations \
  -framework UIKit -framework Foundation -framework QuartzCore -framework CoreGraphics \
  -o "$DYLIB" DFTouchOwnerProbe.m
cp DFTouchOwnerProbe.plist "$TMP/var/jb/Library/MobileSubstrate/DynamicLibraries/DFTouchOwnerProbe.plist"
ldid -S "$DYLIB"
cp Info.plist "$APP/Info.plist"
ldid -Sentitlements.plist "$APP/DuoFaceNativeHost"
plutil -lint "$APP/Info.plist"
cp control "$TMP/DEBIAN/control"
cp postinst postrm "$TMP/DEBIAN/"
chmod 0755 "$TMP/DEBIAN/postinst" "$TMP/DEBIAN/postrm"
# Only uicache app registration; no respring or CarPlay runtime state changes.
OUT="$ROOT/packages/com.duoface.carplay.nativescenehost_0.0.9~gesturerelay1_iphoneos-arm64.deb"
dpkg-deb --build "$TMP" "$OUT"
echo "BUILT=$OUT"
