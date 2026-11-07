#!/bin/bash
# Build a separately uninstallable diagnostic DEB. Never publish it automatically.
set -euo pipefail
cd "$(dirname "$0")"
SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
command -v ldid >/dev/null
command -v dpkg-deb >/dev/null
VERSION='0.0.1~gate0readonly1'
PKG='com.duoface.carplay.gate0probe'
STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT
LIB="$STAGING/var/jb/Library/MobileSubstrate/DynamicLibraries"
mkdir -p "$LIB" "$STAGING/DEBIAN" dist
xcrun --sdk iphoneos clang -dynamiclib -target arm64-apple-ios16.0 \
  -isysroot "$SDK" -fobjc-arc -fblocks -O2 -Wall -Wextra -Werror \
  -Wno-deprecated-declarations -framework Foundation -framework UIKit \
  -o "$LIB/DFGate0CarPlayProbe.dylib" DFGate0CarPlayProbe.m
cp DFGate0CarPlayProbe.plist "$LIB/DFGate0CarPlayProbe.plist"
ldid -S "$LIB/DFGate0CarPlayProbe.dylib"
cat > "$STAGING/DEBIAN/control" <<CONTROL
Package: $PKG
Name: DuoFace Maps Gate0 Read-Only Diagnostic
Version: $VERSION
Architecture: iphoneos-arm64
Maintainer: DuoFace
Priority: optional
Section: Tweaks
Description: Independent read-only CarPlay ON/OFF discovery and native scene ABI observer. No rendering changes.
CONTROL
OUT="dist/${PKG}_${VERSION}_iphoneos-arm64.deb"
dpkg-deb --root-owner-group --build "$STAGING" "$OUT"
test "$(dpkg-deb -f "$OUT" Version)" = "$VERSION"
test -s "$OUT"
shasum -a 256 "$OUT" > "dist/SHA256SUMS.txt"
echo "GATE0_PRIVATE_PROBE_BUILT=${OUT}"
