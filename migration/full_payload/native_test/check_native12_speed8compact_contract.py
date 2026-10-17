#!/usr/bin/env python3
"""Speed8 static regression contract. Real Mac Theos build and device test are separate gates."""
from pathlib import Path
p=Path(".")
src=(p/"runtime/speedbubble/DFSpeedNativeSplit8SpringBoard.mm").read_text()
make=(p/"Makefile.speedhud-native8compact-stage").read_text()
reader=(p/"runtime/speedbubble/DFSpeedGMapReader8.mm").read_text()
transport=(p/"runtime/speedbubble/DFSpeedTransport8.mm").read_text()
builder=(p/"migration/full_payload/native_test/build_native12_speed8compact_candidate.py").read_text()
plist=(p/"DuoFaceSpeedHUDNative7.plist").read_text()
for x in ("CBBridgeManager","CBWindow","CBBridgedSplitApp","currentApp",
          "count<2 || count>4","attached<2","pane.window==root",
          "CBTouchPassThroughRootSceneWindow","S7Unmount",
          "[root addSubview:s7HUD]","[root bringSubviewToFront:s7HUD]",
          "DFAllowedArea(s7HUD)","initWithFrame:CGRectMake(0,0,104,46)",
          "UILongPressGestureRecognizer","showSettings:",
          "settingsAction:","DuoFaceSpeedSplit8-SpringBoard.jsonl"):
    assert x in src,x
assert "CGRect area=parent.bounds;" in src
assert "s7HUD.superview==root && s7HUD.window==root" in src
for x in ("[[UIWindow alloc]","windowLevel=10000000","initWithWindowScene:",
          "connectedScenes","method_setImplementation","MSHookMessageEx",
          "local.gofahud.carplay.show"):
    assert x not in src,x
assert "DFSpeedNativeSplit8SpringBoard.mm" in make
assert "DFSpeedTransport8.mm" in make and "DFSpeedGMapReader8.mm" in make
assert "-DDF_SPEED_HUD_SPRINGBOARD=1" in make
assert "Executables = (\"SpringBoard\")" in plist
assert "RequestPinnedGMapSource" in reader and "com.chou.gmaphud.source.selection" in reader
assert "selectedSource" in src and '@"source"' in reader
assert "DFSpeed::ReadPinnedGMapWire(native)" in transport
assert "if (pinned && src!=pinned)" in transport
assert 'PIN="a59c65f96457b436a0adf581ce96ad0a7fd769552f13ca67112b41b525811155"' in builder
assert 'VERSION="0.1.0~native12+speed8compact"' in builder
assert 'REPLACE=("DuoFaceSpeedHUD.dylib",)' in builder
assert "assert len(originals)==42" in builder
assert '"data_feed_live_on_device_verified":False' in builder
print("SPEED8_STATIC_DRAG_SETTINGS_GMAP_READER_AND_42_UNCHANGED_PAYLOAD_PASS_NOT_DEVICE_TESTED")
