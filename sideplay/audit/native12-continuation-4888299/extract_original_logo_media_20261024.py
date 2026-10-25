#!/usr/bin/env python3
"""SHA-pinned original DuoFace Native12 read-only ARM64: divider + media + scene teardown.
No vendor code imported, no app linking, no licensing.
"""
import pathlib
import runpy

source = pathlib.Path(__file__).resolve().parents[2] / "audit/native12-layout-forensic-20261021/extract_layout_imp.py"
module = runpy.run_path(str(source))
module["main"].__globals__["METHODS"] = [
    ("CBDividerView", "pointInside:withEvent:"),
    ("CBDividerView", "hitTest:withEvent:"),
    ("CBDividerView", "configureWithButtonConfigs:"),
    ("CBDividerView", "moveButtonTouchDown:"),
    ("CBDividerView", "moveButtonTouchUp:"),
    ("CBDividerView", "moveButtonTouchCancelled:"),
    ("CBDividerView", "handleMoveButtonLongPress:"),
    ("CBDividerView", "handlePan:"),
    ("CBDividerView", "updateGripLayout"),
    ("CBDividerView", "moveButtons"),
    ("CBBridgedUIAppView", "updateLayout"),
    ("CBBridgedUIAppView", "refreshSceneLayout"),
    ("CBBridgedUIAppView", "updateSceneSettingsFrame"),
    ("CBBridgedUIAppView", "setAudioOnlyBackgroundMode:"),
    ("CBBridgedUIAppView", "dismiss"),
    ("CBBridgeManager", "renderSizeForBundleID:"),
    ("CBDividerView", "startBlinking"),
    ("CBDividerView", "stopBlinking"),
    ("CBBridgedSplitApp", "noteUserActivity"),
    ("CBBridgedSplitApp", "startBlinkingSession"),
    ("CBBridgedSplitApp", "stopBlinkingSession"),
    ("CBBridgedSplitApp", "startContainerBorderBlinking:"),
    ("CBBridgedSplitApp", "stopContainerBorderBlinking:"),
    ("CBBridgedSplitApp", "configureDividerButtons"),
    ("CBBridgedSplitApp", "layoutSplitViews"),
]
if __name__ == "__main__":
    module["main"]()
