#!/bin/bash
# Run from repo root or any directory. ROOTLESS dpkg payload, no Theos.
set -euo pipefail
SRC="$(cd "$(dirname "$0")" && pwd)"
PACKAGE_DIR="$(mktemp -d)"
trap 'rm -rf "$PACKAGE_DIR"' EXIT
mkdir -p "$PACKAGE_DIR/DEBIAN"
cp "$SRC/DEBIAN/control" "$PACKAGE_DIR/DEBIAN/control"
cp "$SRC/DEBIAN/postinst" "$SRC/DEBIAN/prerm" "$PACKAGE_DIR/DEBIAN/"
chmod 0755 "$PACKAGE_DIR/DEBIAN/postinst" "$PACKAGE_DIR/DEBIAN/prerm"
mkdir -p "$PACKAGE_DIR/var/jb/usr/share/doc/duoface-nativebridgeqa-activate"
cp "$SRC/var/jb/usr/share/doc/duoface-nativebridgeqa-activate/enabled.plist" \
   "$PACKAGE_DIR/var/jb/usr/share/doc/duoface-nativebridgeqa-activate/enabled.plist"
OUT="$SRC/packages"
mkdir -p "$OUT"
dpkg-deb --build "$PACKAGE_DIR" \
  "$OUT/com.duoface.carplay.nativebridgeqa.activate_0.0.1~configfix1_iphoneos-arm64.deb"
