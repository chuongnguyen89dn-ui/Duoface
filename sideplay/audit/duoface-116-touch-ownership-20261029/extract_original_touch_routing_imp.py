#!/usr/bin/env python3
"""Read-only, SHA-verified original Native12 touch-owner method extraction.

Uses the existing immutable first-party project's ARM64 extractor, does not
run or link licensed code in independent DuoFace, and does not rewrite touch.
"""
from pathlib import Path
import runpy

TOUCH_METHODS = [
    ("CBTouchCloneView", "sendTouchEventAtPoint:isDown:"),
    ("CBTouchCloneView", "touchesBegan:withEvent:"),
    ("CBTouchCloneView", "touchesMoved:withEvent:"),
    ("CBTouchCloneView", "touchesEnded:withEvent:"),
    ("CBTouchCloneView", "touchesCancelled:withEvent:"),
    ("CBBridgedUIAppView", "hitTest:withEvent:"),
    ("CBBridgedUIAppView", "touchesBegan:withEvent:"),
    ("CBBridgedUIAppView", "setAppScale:"),
    ("CBBridgedUIAppView", "updateLayout"),
    ("CBBridgedUIAppView", "refreshSceneLayout"),
    ("CBUIAppContainerView", "hitTest:withEvent:"),
    ("CBUIAppContainerView", "touchesBegan:withEvent:"),
    ("CBUIAppContainerView", "layoutSubviews"),
    ("CBWindow", "resizeWindows"),
]


def main() -> None:
    extractor = (Path(__file__).resolve().parents[1]
                 / "native12-layout-forensic-20261021/extract_layout_imp.py")
    module = runpy.run_path(str(extractor))
    fn = module["main"]
    fn.__globals__["METHODS"] = TOUCH_METHODS
    fn()


if __name__ == "__main__":
    main()
