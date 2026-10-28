#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
APP="$STAGE/var/jb/Applications/DuoFaceMapLog.app"
mkdir -p "$APP" "$STAGE/DEBIAN" "$ROOT/packages"
xcrun --sdk iphoneos clang -target arm64-apple-ios16.0 -isysroot "$SDK" \
  -fobjc-arc -O2 -Werror -framework UIKit -framework Foundation \
  -o "$APP/DFMapOwnerExport" "$ROOT/main.m"
cp "$ROOT/Info.plist" "$APP/Info.plist"
ldid -S"$ROOT/entitlements.plist" "$APP/DFMapOwnerExport"
cp "$ROOT/control" "$STAGE/DEBIAN/control"
cp "$ROOT/postinst" "$ROOT/prerm" "$STAGE/DEBIAN/"
chmod 0755 "$STAGE/DEBIAN/postinst" "$STAGE/DEBIAN/prerm"
plutil -lint "$APP/Info.plist"
dpkg-deb --build "$STAGE" "$ROOT/packages/com.duoface.carplay.mapownerexport_0.0.1~jsonl1_iphoneos-arm64.deb"
