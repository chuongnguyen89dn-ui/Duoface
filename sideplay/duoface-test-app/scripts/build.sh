#!/usr/bin/env bash
set -euo pipefail
# Build a real on-device UIKit app + SpringBoard-only command receiver,
# packaged as ONE Sileo app. No vendor code, no boot-time LS hooks.
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SRC"
: "${OUT_DIR:=$SRC/packages}"
command -v xcrun >/dev/null
command -v ldid >/dev/null
command -v dpkg-deb >/dev/null
SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
CLANG="$(xcrun --sdk iphoneos --find clang)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
PKG="$WORK/package"
APP="$PKG/var/jb/Applications/DuoFaceTest.app"
DYLIBDIR="$PKG/var/jb/Library/MobileSubstrate/DynamicLibraries"
mkdir -p "$APP" "$DYLIBDIR" "$PKG/DEBIAN" "$OUT_DIR"
CFLAGS=(-target arm64-apple-ios16.0 -isysroot "$SDK" -fobjc-arc -O2
  -Werror=implicit-function-declaration -framework Foundation
  -framework UIKit -framework CoreFoundation)
"$CLANG" "${CFLAGS[@]}" App/main.m App/DFAppDelegate.m -o "$APP/DuoFaceTest"
"$CLANG" "${CFLAGS[@]}" -dynamiclib Controller/DFTestSpringBoardController.m \
  -o "$DYLIBDIR/DFDuoFaceTestController.dylib"
cp App/Info.plist "$APP/Info.plist"
xcrun ibtool --compile "$APP/LaunchScreen.storyboardc" App/LaunchScreen.storyboard
python3 scripts/make_icon.py "$APP"
cp Controller/DFTestSpringBoardController.plist "$DYLIBDIR/DFDuoFaceTestController.plist"
cp DEBIAN/control DEBIAN/postinst DEBIAN/postrm "$PKG/DEBIAN/"
chmod 0755 "$PKG/DEBIAN/postinst" "$PKG/DEBIAN/postrm"
chmod 0755 "$APP/DuoFaceTest" "$DYLIBDIR/DFDuoFaceTestController.dylib"
# Use normal ldid ad hoc signatures; NEVER claim Apple-issued CarPlay entitlements.
ldid -S "$APP/DuoFaceTest"
ldid -S "$DYLIBDIR/DFDuoFaceTestController.dylib"
xcrun --sdk iphoneos lipo -archs "$APP/DuoFaceTest" | grep -qw arm64
xcrun --sdk iphoneos lipo -archs "$DYLIBDIR/DFDuoFaceTestController.dylib" | grep -qw arm64
PLIST="$APP/Info.plist" FILTER="$DYLIBDIR/DFDuoFaceTestController.plist" python3 - <<'PY'
from pathlib import Path
import plistlib,os
i=plistlib.loads(Path(os.environ["PLIST"]).read_bytes())
assert i['CFBundleIdentifier']=='com.duoface.testapp'
assert i['CFBundleExecutable']=='DuoFaceTest'
f=plistlib.loads(Path(os.environ['FILTER']).read_bytes())
assert f['Filter']['Executables']==['SpringBoard'],f
print('Home icon app bundle + exact SpringBoard-only filter verified')
PY
DEB="$OUT_DIR/com.duoface.testapp_0.1.0~app1_iphoneos-arm64.deb"
dpkg-deb --build "$PKG" "$DEB"
test "$(dpkg-deb -f "$DEB" Package)" = com.duoface.testapp
test "$(dpkg-deb -f "$DEB" Version)" = '0.1.0~app1'
test "$(dpkg-deb -f "$DEB" Architecture)" = iphoneos-arm64
echo "Built real DuoFace Test.app and SpringBoard companion: $DEB"
sha256sum "$DEB"
