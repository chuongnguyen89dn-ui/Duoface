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
  -fobjc-arc -fblocks -O2 -Wall -Wextra -Werror -Wno-deprecated-declarations \
  -framework UIKit -framework CarPlay -framework Foundation -framework QuartzCore -framework CoreGraphics -framework AVFoundation -framework Speech \
  -o "$APP/DuoFaceNativeHost" main.m DFNativeHostAppDelegate.m DFNative12BasicController.m DFNativeHostRootController.m DFVoiceAssistant.m DFNativeDiagnostics.m \
  DFNativeHostSurfaceView.m DFLayoutEngine.m ../mytweak-independent-v1a/prototype/MTCPBridgeContract.m
# Separate SpringBoard input receiver: no implicit overlay at jailbreak startup.
DYLIB="$TMP/var/jb/Library/MobileSubstrate/DynamicLibraries/DFTouchOwnerProbe.dylib"
xcrun --sdk iphoneos clang -dynamiclib -target arm64-apple-ios16.0 -isysroot "$SDK" \
  -fobjc-arc -O2 -Wall -Wextra -Werror -Wno-deprecated-declarations \
  -framework UIKit -framework Foundation -framework QuartzCore -framework CoreGraphics \
  -o "$DYLIB" DFTouchOwnerProbe.m DFNative12Chrome.m DFNative12PresetPreview.m DFLayoutEngine.m DFSceneHost.m DFSceneLifecycle.m DFSceneOrientationPolicy.m DFAppLibrary.m DFAppPickerVC.m DFDockZoomCoordinator.m DFDisconnectCloseCoordinator.m
cp DFTouchOwnerProbe.plist "$TMP/var/jb/Library/MobileSubstrate/DynamicLibraries/DFTouchOwnerProbe.plist"
ldid -S "$DYLIB"
# The native Apple AppDock owner lives inside the actual CarPlay UI process.
# This receiver is separate from the SpringBoard pane/input scene host.
DOCK_DYLIB="$TMP/var/jb/Library/MobileSubstrate/DynamicLibraries/DFCarPlayDockOwner.dylib"
xcrun --sdk iphoneos clang -dynamiclib -target arm64-apple-ios16.0 -isysroot "$SDK" \
  -fobjc-arc -O2 -Wall -Wextra -Werror -Wno-deprecated-declarations \
  -framework UIKit -framework Foundation -framework CoreGraphics \
  -DDFCarPlayCaptureLiveOwnerSnapshot=DFIntegratedCarPlayCaptureLiveOwnerSnapshot \
  -o "$DOCK_DYLIB" DFCarPlayDockOwner.m ../native-carplay-scene-v1/DFCarPlayLiveOwnerSnapshot.m
cp DFCarPlayDockOwner.plist "$TMP/var/jb/Library/MobileSubstrate/DynamicLibraries/DFCarPlayDockOwner.plist"
ldid -S "$DOCK_DYLIB"
# User-opted-in in-process native Maps scene UIKit container. Default idle;
# never touch SpringBoard/Dock or run until an explicit iPhone action.
MAP_DYLIB="$TMP/var/jb/Library/MobileSubstrate/DynamicLibraries/DFNativeMapPaneCoordinator.dylib"
xcrun --sdk iphoneos clang -dynamiclib -target arm64-apple-ios16.0 -isysroot "$SDK" \
  -fobjc-arc -fblocks -O2 -Wall -Wextra -Werror -Wno-deprecated-declarations \
  -framework UIKit -framework Foundation -framework CoreGraphics \
  -o "$MAP_DYLIB" ../native-carplay-scene-v1/DFNativeMapPaneCoordinator.m \
  ../native-carplay-scene-v1/DFNativeMapPaneAdapter.m
cp ../native-carplay-scene-v1/DFNativeMapPaneCoordinator.plist \
  "$TMP/var/jb/Library/MobileSubstrate/DynamicLibraries/DFNativeMapPaneCoordinator.plist"
ldid -S "$MAP_DYLIB"

# YouTube-only first-party receiver; same integrated DEB, no additional app.
YT_DYLIB="$TMP/var/jb/Library/MobileSubstrate/DynamicLibraries/DFYouTubeOrientationRelay.dylib"
xcrun --sdk iphoneos clang -dynamiclib -target arm64-apple-ios16.0 -isysroot "$SDK" \
  -fobjc-arc -fblocks -O2 -Wall -Wextra -Werror -Wno-deprecated-declarations \
  -framework UIKit -framework Foundation -framework CoreGraphics \
  -o "$YT_DYLIB" DFYouTubeOrientationRelay.m DFYouTubeOrientationVirtualization.m
cp DFYouTubeOrientationRelay.plist "$TMP/var/jb/Library/MobileSubstrate/DynamicLibraries/DFYouTubeOrientationRelay.plist"
ldid -S "$YT_DYLIB"
# Assets are our previously approved DuoFace artwork from the project's source.
ART="$ROOT/../../dist/visual-1.0.3-12/assets"
APP_ART="$APP/VisualAssets"
SYSTEM_ART="$TMP/var/jb/Library/Application Support/DuoFaceNativeHost/VisualAssets"
mkdir -p "$APP_ART" "$SYSTEM_ART"
for f in duoface-logo.png duoface-logo-vert.png duoface-logo-picker-alpha-v2.png; do
  test -s "$ART/$f"
  cp "$ART/$f" "$APP_ART/$f"
  cp "$ART/$f" "$SYSTEM_ART/$f"
done
for f in duoface-picker.png duoface-fullscreen.png duoface-swap.png; do
  test -s "$ART/VisualAssets/$f"
  cp "$ART/VisualAssets/$f" "$APP_ART/$f"
  cp "$ART/VisualAssets/$f" "$SYSTEM_ART/$f"
done
test -s "$ART/duoface-icon.png"
sips -s format png -z 120 120 "$ART/duoface-icon.png" --out "$APP/DuoFaceIcon60@2x.png" >/dev/null
sips -s format png -z 180 180 "$ART/duoface-icon.png" --out "$APP/DuoFaceIcon60@3x.png" >/dev/null
# iOS splash is compiled by Xcode's Interface Builder; copy the logo at
# bundle root as well so the launch scene can resolve its image by name.
cp "$ART/duoface-logo.png" "$APP/duoface-logo.png"
xcrun ibtool --errors --warnings --notices \
  --compile "$APP/DuoFaceLaunchScreen.storyboardc" DuoFaceLaunchScreen.storyboard
cp Info.plist "$APP/Info.plist"
ldid -Sentitlements.plist "$APP/DuoFaceNativeHost"
plutil -lint "$APP/Info.plist"
cp control "$TMP/DEBIAN/control"
cp postinst postrm "$TMP/DEBIAN/"
chmod 0755 "$TMP/DEBIAN/postinst" "$TMP/DEBIAN/postrm"
# Only uicache app registration; no respring or CarPlay runtime state changes.
OUT="$ROOT/packages/com.duoface.carplay.nativescenehost_0.1.123~underlock1_iphoneos-arm64.deb"
dpkg-deb --build "$TMP" "$OUT"
echo "BUILT=$OUT"
