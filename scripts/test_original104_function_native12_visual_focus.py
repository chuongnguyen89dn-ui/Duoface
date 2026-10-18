#!/usr/bin/env python3
"""Pin original104 functional ownership + Native12 visual pill geometry to QA.

Static assurance only: this is not a test of SpringBoard or a live CarPlay scene.
Run after the immutable-DEB crosswalk audit has been checked into the QA branch.
"""
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
contract=json.loads((ROOT/"audit/native12-deb-original104-ui/"
    "FOCUS_ORIGINAL104_NATIVE12_UI_CROSSWALK.json").read_text())
assert contract["status"]=="ORIGINAL104_FUNCTION_NATIVE12_VISUAL_FOCUS_STATIC_PASS"
assert contract["static_only"] and not contract["carplay_device_verified"]
assert contract["source_roles"]["functional"]=="original DuoNavi 1.0.4 DEB"
assert contract["source_roles"]["visual"]=="DuoFace Native12 HUD8 DEB"
sha=contract["sha256"]
assert sha["original104_deb"]=="f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd"
assert sha["native12_deb"]=="2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad"
functional=contract["original_functional_entrypoints"]
for name in ("focusSlot:animated:","restoreSplitAnimated:"):
    assert set(("saveBridgeStateToDisk","layoutSplitViews","refreshSceneLayout")).issubset(
        functional[name]["requires"]),name
assert set(("setFocusedMode:","setShowsExpandButton:","setCompactMode:")).issubset(
    functional["layoutSplitViews"]["native_visual_flags"])
visual=contract["native12_visual_pill"]
assert visual["layout_imp"]=="0x84c30"
assert set(("dotsButton","separatorView","expandButton"))==set(visual["focused_hide"])
assert visual["focused_show"]==["restoreButton"]
assert visual["known_compact_mode_trigger"] is False

shell=(ROOT/"replacement/visual12/engine/runtime/DFINativeShell.inc").read_text()
ui=(ROOT/"replacement/visual12/engine/runtime/DFIInterface.inc").read_text()
runtime=(ROOT/"replacement/visual12/engine/runtime/DFIRuntime.m").read_text()
for snippet in (
    "_dotsButton.hidden=focused;",
    "_expandButton.hidden=focused || !_showsExpandButton;",
    "_separatorView.hidden=focused || !_showsExpandButton;",
    "_restoreButton.hidden=!focused;",
    "_restoreButton.frame=_focusedMode?self.bounds:_expandButton.frame;",
    "_separatorView.backgroundColor=[UIColor colorWithWhite:1.0 alpha:0.25];",
    "_separatorView.frame=CGRectMake(half-0.25,3.5,0.5,MAX(0,height-7.0));",
    "CGFloat width=_focusedMode?(_compactMode?72.0:80.0):",
):
    assert snippet in shell, snippet
for snippet in (
    "[nativePill setFocused:self.maximized==i];",
    "CGSize nativeSize=[nativePill nativeReferenceSize];",
    "- (void)restorePane:(UIButton *)button {",
    "- (void)zoomPane:(UIButton *)button {",
    "self.maximized=-1;",
    "[self.hosts[i] resizeTo:frame.size]",
):
    assert snippet in ui, snippet
for snippet in (
    "- (void)resizeTo:(CGSize)size {",
    "- (void)applySize {",
    'NSSelectorFromString(@"updateSettings:withTransitionContext:completion:")',
    'DFIRect(settings,@"setFrame:",',
):
    assert snippet in runtime, snippet
assert "@implementation CBBridgedSplitApp" not in ui
assert "@implementation CBSlotPillView" not in shell
print("ORIGINAL104_FUNCTION_NATIVE12_VISUAL_QA_FOCUS_STATIC_PASS")
print("PHYSICAL_CARPLAY_SCENE_FOCUS_AND_COMPACT_TRIGGER_UNVERIFIED")
