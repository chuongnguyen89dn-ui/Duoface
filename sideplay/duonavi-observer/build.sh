#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
APP="$STAGE/var/jb/Applications/DuoNaviObserver.app"
DYLIBS="$STAGE/var/jb/Library/MobileSubstrate/DynamicLibraries"
mkdir -p "$APP" "$DYLIBS" "$STAGE/DEBIAN" "$ROOT/packages"
xcrun --sdk iphoneos clang -target arm64-apple-ios16.0 -isysroot "$SDK" \
  -fobjc-arc -fblocks -O2 -Wall -Wextra -Werror -Wno-deprecated-declarations \
  -dynamiclib -framework Foundation -framework UIKit \
  -o "$DYLIBS/DuoNaviObserver.dylib" "$ROOT/Observer.m"
xcrun --sdk iphoneos clang -target arm64-apple-ios16.0 -isysroot "$SDK" \
  -fobjc-arc -fblocks -O2 -Wall -Wextra -Werror -Wno-deprecated-declarations \
  -framework Foundation -framework UIKit \
  -o "$APP/DNObserverExport" "$ROOT/ExportApp.m"
cp "$ROOT/Observer.plist" "$DYLIBS/DuoNaviObserver.plist"
cp "$ROOT/Info.plist" "$APP/Info.plist"
ldid -S "$DYLIBS/DuoNaviObserver.dylib"
ldid -S"$ROOT/entitlements.plist" "$APP/DNObserverExport"
cp "$ROOT/control" "$STAGE/DEBIAN/control"
cp "$ROOT/postinst" "$ROOT/prerm" "$STAGE/DEBIAN/"
chmod 0755 "$STAGE/DEBIAN/postinst" "$STAGE/DEBIAN/prerm"
plutil -lint "$APP/Info.plist" "$DYLIBS/DuoNaviObserver.plist"
OUT="$ROOT/packages/com.duoface.qa.duonaviobserver_0.0.2~dockabi1_iphoneos-arm64.deb"
dpkg-deb --build "$STAGE" "$OUT"
test -s "$OUT"
echo "SIGNED_DUONAVI_OBSERVER=$OUT"
