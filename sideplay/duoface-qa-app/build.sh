#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"
SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
APP="$TMP/var/jb/Applications/DuoFaceQA.app"
mkdir -p "$APP" "$TMP/DEBIAN" "$ROOT/packages"
xcrun --sdk iphoneos clang -target arm64-apple-ios16.0 -isysroot "$SDK" \
    -fobjc-arc -O2 -Werror -Wno-deprecated-declarations \
    -framework UIKit -framework Foundation -framework QuartzCore \
    -o "$APP/DuoFaceQA" main.m DFQAAppDelegate.m DFQARootController.m
cp Info.plist "$APP/Info.plist"
swift tools/generate_icon.swift "$APP"
# ldid installed by CI, and app has no network/task_for_pid/LS private API rights.
ldid -Sentitlements.plist "$APP/DuoFaceQA"
cp control "$TMP/DEBIAN/control"
cp postinst prerm "$TMP/DEBIAN/"
chmod 0755 "$TMP/DEBIAN/postinst" "$TMP/DEBIAN/prerm"
plutil -lint "$APP/Info.plist"
xcrun codesign -d --entitlements :- "$APP/DuoFaceQA" > "$ROOT/packages/ENTITLEMENTS_VERIFIED.plist" 2>&1 || \
  ldid -e "$APP/DuoFaceQA" > "$ROOT/packages/ENTITLEMENTS_VERIFIED.plist"
OUT="$ROOT/packages/com.duoface.qa.controlapp_0.1.9~mapowner1_iphoneos-arm64.deb"
dpkg-deb --build "$TMP" "$OUT"
echo "BUILT=$OUT"
