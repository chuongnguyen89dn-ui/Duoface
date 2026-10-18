#!/usr/bin/env bash
# Native12 HUD8 visual migration QA DEB; Sileo published only via separately verified publisher. Main product remains unchanged.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
PIN="d5227b4cb42bb0143e63840c95eff8d776b73068"
OUT="dist/visual12-native8ui1-qa"
WORK="$RUNNER_TEMP/visual12-qa"
STAGE="$WORK/stage"
APP="$STAGE/var/jb/Applications/DuoFaceVisual12.app"
TWEAK="$STAGE/var/jb/Library/MobileSubstrate/DynamicLibraries"
PREF="$STAGE/var/jb/Library/PreferenceBundles/DuoFaceVisual12Prefs.bundle"
LOADER="$STAGE/var/jb/Library/PreferenceLoader/Preferences"
IMAGES="$STAGE/var/jb/Library/Application Support/DuoFaceVisual12"
SRC="replacement/visual12/engine"
mkdir -p "$OUT"
rm -rf "$WORK"
mkdir -p "$WORK/templates" "$APP" "$TWEAK" "$PREF" "$LOADER" "$IMAGES" "$STAGE/DEBIAN"
git cat-file -e "$PIN^{commit}"
git show "$PIN:independent/engine/app/main.m" > "$WORK/templates/app-main.m"
git show "$PIN:independent/engine/app/Info.plist" > "$WORK/templates/app-info.plist"
git show "$PIN:independent/engine/preferences/Entry.m" > "$WORK/templates/prefs-entry.m"
git show "$PIN:independent/engine/preferences/Info.plist" > "$WORK/templates/prefs-info.plist"
git show "$PIN:independent/engine/preferences/Loader.plist" > "$WORK/templates/prefs-loader.plist"
git show "$PIN:independent/engine/packaging/DuoFaceIndependent.plist" > "$WORK/templates/filter.plist"
git show "$PIN:independent/engine/packaging/entitlements.plist" > "$WORK/templates/entitlements.plist"
git show "$PIN:independent/engine/packaging/postinst" > "$WORK/templates/postinst"
git show "$PIN:independent/engine/packaging/postrm" > "$WORK/templates/postrm"
python3 - "$WORK" "$STAGE" <<'PY'
from pathlib import Path
import sys,hashlib,json,plistlib
work,stage=map(Path,sys.argv[1:])
t=work/"templates"
app=stage/"var/jb/Applications/DuoFaceVisual12.app"
prefs=stage/"var/jb/Library/PreferenceBundles/DuoFaceVisual12Prefs.bundle"
def trans(s):
    return (s.replace("com.duoface.independent","com.duoface.visual12")
             .replace("DuoFaceIndependent","DuoFaceVisual12")
             .replace("../shared/DFISettings.h","DFISettings.h")
             .replace("DFISettingsController","DFV12SettingsController")
             .replace("DFIPreferencesController","DFV12PreferencesController")
             .replace("DuoFace Mới","DuoFace"))
targets={
"app-main.m":t/"app-new.m",
"app-info.plist":app/"Info.plist",
"prefs-entry.m":t/"prefs-new.m",
"prefs-info.plist":prefs/"Info.plist",
"prefs-loader.plist":stage/"var/jb/Library/PreferenceLoader/Preferences/DuoFaceVisual12Prefs.plist",
"filter.plist":stage/"var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceVisual12.plist",
"entitlements.plist":t/"signed.plist",
"postinst":stage/"DEBIAN/postinst","postrm":stage/"DEBIAN/postrm"
}
for inp,out in targets.items():out.write_text(trans((t/inp).read_text()))
info=plistlib.loads((app/"Info.plist").read_bytes())
assert info["CFBundleIdentifier"]=="com.duoface.visual12"
assert info["CFBundleExecutable"]=="DuoFaceVisual12"
prefinfo=plistlib.loads((prefs/"Info.plist").read_bytes())
assert prefinfo["NSPrincipalClass"]=="DFV12PreferencesController"
assets=Path("dist/visual-1.0.3-12/assets")
expected={
"duoface-icon.png":"03f0a9e31bffced19419f06193d866bb2d66d824c5ba10c5c24eee8718217def",
"duoface-logo.png":"78450d8ee4759353bdc21f27a06016c03fab61038ae60109ba21515c087b0089",
"duoface-logo-vert.png":"7fa216e2fa89e4fc32e49045ab29d72f6bee3fef4f974444c98fb5bd631e25d2",
"duoface-logo-picker-alpha-v2.png":"43b6dafb8fc0550c2b3032c11acae1e0712350ca5b4dd235b7dc14c7951c74f7",
"VisualAssets/duoface-fullscreen.png":"10e52f01a16cb7d34a81330373a290bcac1bdb0ba9c91119527ef3dcb13cdb36",
"VisualAssets/duoface-picker.png":"16a959b71a0d3d8ef86e2ac9163024af457aec180770c757fe4b16d2b0a85f8a",
"VisualAssets/duoface-swap.png":"d3ec77c783a186896d63bb08732ee78e427f16e1c127c0785b36bf5eaa037275"}
dest=stage/"var/jb/Library/Application Support/DuoFaceVisual12"
copied={}
for source in sorted(assets.rglob("*")):
    if not source.is_file():continue
    rel=source.relative_to(assets).as_posix()
    if rel.startswith(".") or rel.endswith((".bak",".tmp")):continue
    raw=source.read_bytes()
    sha=hashlib.sha256(raw).hexdigest()
    if rel in expected and sha!=expected[rel]:raise SystemExit("Artwork SHA mismatch: "+rel)
    target=dest/rel;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(raw)
    copied[rel]={"size":len(raw),"sha256":sha}
assert set(expected).issubset(copied)
manifest={"source":"dist/visual-1.0.3-12/assets","files":copied,"source_hashes_verified":len(expected),"status":"ASSETS_COPIED_BYTE_FOR_BYTE_NOT_RUNTIME_PARITY"}
(dest/"asset-transfer-manifest.json").write_text(json.dumps(manifest,sort_keys=True,indent=2)+"\n")
print("APP_PLISTS_AND_APPROVED_ARTWORK_VALIDATED")
PY
cat > "$STAGE/DEBIAN/control" <<'CONTROL'
Package: com.duoface.visual12
Name: DuoFace CarPlay Standalone (QA only)
Version: 1.0.3-12~ui8native1
Architecture: iphoneos-arm64
Maintainer: chuongnguyen89dn-ui
Author: chuongnguyen89dn-ui
Section: Tweaks
Depends: preferenceloader, firmware (>= 16.0), firmware (<< 17.0), mobilesubstrate (>= 0.9.5000) | ellekit
Description: Independent scene-host QA with Native12 picker chrome and native Speed8 visual controls. Speed data/Native renderer full parity pending real-device QA.
CONTROL
SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
xcrun --sdk iphoneos clang -target arm64-apple-ios16.0 -arch arm64 -isysroot "$SDK" \
 -Wl,-headerpad,0x1000 -fobjc-arc -fblocks -Os -Wall -Wextra -Wno-unused-parameter \
 -framework Foundation -framework UIKit -framework CoreFoundation -framework CoreGraphics -framework QuartzCore -lobjc \
 -dynamiclib -I replacement/cb-compat -I runtime/fullscreen \
 "$SRC/runtime/DFIRuntime.m" replacement/cb-compat/DFCBCompat.m \
 replacement/visual12/fullscreen/DFVisual12HostGeometry.m \
 -Wl,-install_name,/var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceVisual12.dylib \
 -o "$TWEAK/DuoFaceVisual12.dylib"
xcrun --sdk iphoneos clang -target arm64-apple-ios16.0 -arch arm64 -isysroot "$SDK" \
 -Wl,-headerpad,0x1000 -fobjc-arc -fblocks -Os -Wall -Wextra -Wno-unused-parameter \
 -framework Foundation -framework UIKit -framework CoreFoundation -framework CoreGraphics -framework QuartzCore -lobjc \
 -I "$SRC/shared" "$WORK/templates/app-new.m" "$SRC/shared/DFISettings.m" -o "$APP/DuoFaceVisual12"
xcrun --sdk iphoneos clang -target arm64-apple-ios16.0 -arch arm64 -isysroot "$SDK" \
 -Wl,-headerpad,0x1000 -fobjc-arc -fblocks -Os -Wall -Wextra -Wno-unused-parameter \
 -framework Foundation -framework UIKit -framework CoreFoundation -framework CoreGraphics -framework QuartzCore -lobjc \
 -bundle -Wl,-undefined,dynamic_lookup -I "$SRC/shared" "$WORK/templates/prefs-new.m" \
 "$SRC/shared/DFISettings.m" -o "$PREF/DuoFaceVisual12Prefs"
ICON="dist/visual-1.0.3-12/assets/duoface-icon.png"
sips -s format png -z 120 120 "$ICON" --out "$APP/AppIcon60x60@2x.png" >/dev/null
sips -s format png -z 180 180 "$ICON" --out "$APP/AppIcon60x60@3x.png" >/dev/null
sips -s format png -z 29 29 "$ICON" --out "$PREF/Icon.png" >/dev/null
sips -s format png -z 58 58 "$ICON" --out "$PREF/Icon@2x.png" >/dev/null
sips -s format png -z 87 87 "$ICON" --out "$PREF/Icon@3x.png" >/dev/null
ldid -S "$TWEAK/DuoFaceVisual12.dylib"
ldid -S "$PREF/DuoFaceVisual12Prefs"
ldid -S"$WORK/templates/signed.plist" "$APP/DuoFaceVisual12"
chmod 0755 "$APP/DuoFaceVisual12" "$PREF/DuoFaceVisual12Prefs" "$TWEAK/DuoFaceVisual12.dylib" "$STAGE/DEBIAN/postinst" "$STAGE/DEBIAN/postrm"
chmod 0644 "$STAGE/DEBIAN/control" "$TWEAK/DuoFaceVisual12.plist"
FILE="$OUT/com.duoface.visual12_1.0.3-12~ui8native1_iphoneos-arm64.deb"
dpkg-deb --build --root-owner-group "$STAGE" "$FILE"
python3 replacement/visual12/verify_qa.py "$FILE"
shasum -a 256 "$FILE" > "$OUT/SHA256SUMS"
dpkg-deb -c "$FILE" > "$OUT/CONTENTS.txt"
python3 - "$FILE" <<'PY'
import hashlib,json,os,sys
from pathlib import Path
p=Path(sys.argv[1])
report={"status":"QA_DEB_BUILT_DEVICE_NOT_TESTED","package_id":"com.duoface.visual12",
"version":"1.0.3-12~ui8native1","source_commit":os.getenv("GITHUB_SHA"),
"run_id":os.getenv("GITHUB_RUN_ID"),"sha256":hashlib.sha256(p.read_bytes()).hexdigest(),
"size_bytes":p.stat().st_size,"path":str(p),"main_product":"Native12 + Hub8 unchanged",
"device_tested":False,"ui_v12_verified":False,"two_apps_tested":False,
"hub_modified":False,"sileo_published":False,"hud8_visual_present":True,"speed_transport_wired":False,"native_renderer_parity_verified":False}
(p.parent/"BAO_CAO.json").write_text(json.dumps(report,indent=2)+"\n")
PY
echo "BUILT_QA_DEB_NO_SILEO_NO_DEVICE_TEST $FILE"
