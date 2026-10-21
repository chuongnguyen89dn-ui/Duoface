#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"
python3 prepare.py
mkdir -p "$ROOT/packages"
# Compile only the independent narrow default-off admission source.
make clean package FINALPACKAGE=1
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
INPUT="$ROOT/packages/com.duoface.carplay.gate1smoke_0.0.3~enablefix1_iphoneos-arm64.deb"
test -s "$INPUT"
dpkg-deb -x "$INPUT" "$TMP"
DYLIB="$TMP/var/jb/Library/MobileSubstrate/DynamicLibraries/DFGate1SmokeAdmission.dylib"
FILTER="$TMP/var/jb/Library/MobileSubstrate/DynamicLibraries/DFGate1SmokeAdmission.plist"
test -s "$DYLIB" && test -s "$FILTER"
APP="$TMP/var/jb/Applications/DuoFaceGate1.app"
mkdir -p "$APP" "$TMP/DEBIAN"
SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
xcrun --sdk iphoneos clang -target arm64-apple-ios16.0 -isysroot "$SDK" \
  -fobjc-arc -O2 -Wall -Wextra -Werror -Wno-deprecated-declarations \
  -Wl,-headerpad,0x1000 \
  -framework UIKit -framework Foundation -framework QuartzCore -framework CoreGraphics \
  -o "$APP/DuoFaceGate1" Gate1App.m
cp Info.plist "$APP/Info.plist"
ldid -Sentitlements.plist "$APP/DuoFaceGate1"
python3 "$ROOT/verify_macho.py" "$APP/DuoFaceGate1"
plutil -lint "$APP/Info.plist"
# Deterministic icon; no copied vendor graphics or external assets.
APP_PATH="$APP" python3 - <<'PY'
from pathlib import Path
import os,struct,zlib
root=Path(os.environ["APP_PATH"])
G=["11111","10000","10111","10001","10001","10001","11111"]
ONE=["00100","01100","00100","00100","00100","00100","01110"]
for factor in (2,3):
    n=60*factor
    scale=max(3,n//20)
    data=bytearray()
    for y in range(n):
        data.append(0)
        for x in range(n):
            on=False
            for bitmap,left in ((G,n//2-7*scale),(ONE,n//2+scale)):
                gx=(x-left)//scale
                gy=(y-(n-7*scale)//2)//scale
                if 0<=gx<5 and 0<=gy<7 and bitmap[gy][gx]=="1" and x>=left:
                    on=True
            data+=bytes((255,255,255,255) if on else (9,52+(x*45//n),129+(y*80//n),255))
    def chunk(name,data):
        return struct.pack(">I",len(data))+name+data+struct.pack(">I",zlib.crc32(name+data)&0xffffffff)
    payload=b"\x89PNG\r\n\x1a\n"+chunk(b"IHDR",struct.pack(">IIBBBBB",n,n,8,6,0,0,0))+chunk(b"IDAT",zlib.compress(bytes(data),9))+chunk(b"IEND",b"")
    (root/f"AppIcon60x60@{factor}x.png").write_bytes(payload)
PY
cp control "$TMP/DEBIAN/control"
cp postinst prerm postrm "$TMP/DEBIAN/"
chmod 0755 "$TMP/DEBIAN/postinst" "$TMP/DEBIAN/prerm" "$TMP/DEBIAN/postrm"
# Inspect forbidden overlaps before the final package is written.
test "$(find "$TMP/var/jb/Applications" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')" = 1
test "$(find "$TMP/var/jb/Library/MobileSubstrate/DynamicLibraries" -type f | wc -l | tr -d ' ')" = 2
OUT="$ROOT/packages/com.duoface.carplay.gate1smoke_0.0.3~enablefix1_iphoneos-arm64.deb"
rm -f "$OUT"
dpkg-deb --build --root-owner-group "$TMP" "$OUT"
test "$(dpkg-deb -f "$OUT" Package)" = com.duoface.carplay.gate1smoke
! dpkg-deb -f "$OUT" | grep -E '^(Conflicts|Replaces|Provides|Breaks):'
dpkg-deb -c "$OUT" | grep -F 'DuoFaceGate1.app/DuoFaceGate1'
dpkg-deb -c "$OUT" | grep -F 'DFGate1SmokeAdmission.dylib'
dpkg-deb -c "$OUT" | grep -F 'DFGate1SmokeAdmission.plist'
mkdir -p "$ROOT/packages/validation"
dpkg-deb -e "$OUT" "$ROOT/packages/validation"
for file in postinst prerm postrm; do test -x "$ROOT/packages/validation/$file"; done
printf 'GATE1_DEB=%s\n' "$OUT"
shasum -a 256 "$OUT"
