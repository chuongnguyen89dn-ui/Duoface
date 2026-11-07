#!/bin/bash
set -euo pipefail
repo_root="$(git rev-parse --show-toplevel)"
qa186_temp="$(mktemp -d)"
qa186_app="$qa186_temp/PaneLayout186.app"
mkdir -p "$qa186_app"
cat > "$qa186_app/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>com.duoface.tests.panelayout186</string>
<key>CFBundleExecutable</key><string>PaneLayout186</string>
<key>CFBundleName</key><string>PaneLayout186</string>
<key>CFBundleVersion</key><string>1</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSRequiresIPhoneOS</key><true/>
<key>UILaunchScreen</key><dict/>
</dict></plist>
PLIST
qa186_sdk="$(xcrun --sdk iphonesimulator --show-sdk-path)"
qa186_arch="$(uname -m)"
xcrun clang -target "$qa186_arch-apple-ios16.0-simulator" -isysroot "$qa186_sdk" \
 -fobjc-arc -fblocks -Wall -Wextra -Werror -Wno-deprecated-declarations \
 -framework UIKit -framework Foundation -framework CoreGraphics \
 "$repo_root/sideplay/duoface-native-scene-host/tests/pane_layout_186_uikit.m" \
 -o "$qa186_app/PaneLayout186"
codesign --force --sign - "$qa186_app"
qa186_device="$(xcrun simctl list devices available -j | python3 -c 'import json,sys; d=json.load(sys.stdin); print(next(x["udid"] for k,v in d["devices"].items() if "iOS" in k for x in v if "iPhone" in x["name"] and x["isAvailable"]))')"
xcrun simctl boot "$qa186_device" || test "$(xcrun simctl list devices -j | python3 -c 'import json,sys; d=json.load(sys.stdin); print(next(x["state"] for v in d["devices"].values() for x in v if x["udid"]==sys.argv[1]))' "$qa186_device")" = Booted
xcrun simctl bootstatus "$qa186_device" -b
xcrun simctl install "$qa186_device" "$qa186_app"
xcrun simctl launch "$qa186_device" com.duoface.tests.panelayout186
qa186_container="$(xcrun simctl get_app_container "$qa186_device" com.duoface.tests.panelayout186 data)"
python3 - "$qa186_container/Documents/result.plist" <<'PY'
import pathlib,plistlib,sys,time
p=pathlib.Path(sys.argv[1])
for _ in range(45):
    if p.exists(): break
    time.sleep(1)
assert p.exists(), 'UIKit harness did not write result within 45 seconds'
r=plistlib.loads(p.read_bytes()); print(r)
assert r['passed'], r['errors']
print('QA186_REAL_UIKIT_CONTAINMENT_LAYOUT_PASS_NO_CARPLAY_PIXEL_CLAIM')
PY
xcrun simctl shutdown "$qa186_device"
