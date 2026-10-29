#!/usr/bin/env python3
"""Read-only original Native12 timed/geometry/input owner IMP scan.
Uses the existing SHA-pinned ARM64 extractor and immutable original DEB.
No third-party binary is incorporated in DuoFace.
"""
from pathlib import Path
import runpy

TARGETS = [
    ("CBWindow", "resetCachedBounds"),
    ("CBWindow", "resizeWindows"),
    ("CBWindow", "show"),
    ("CBBridgedUIAppView", "layoutSubviews"),
    ("CBBridgedUIAppView", "calculateNativeSizeForSlotRect:"),
    ("CBBridgedUIAppView", "updateLayout"),
    ("CBBridgedUIAppView", "refreshSceneLayout"),
    ("CBBridgedUIAppView", "updateSceneSettingsFrame"),
    ("CBUIAppContainerView", "layoutSubviews"),
    ("CBBridgedSplitApp", "layoutSplitViews"),
    ("CBBridgedSplitApp", "updateScale:forSlot:"),
    ("CBBridgeManager", "receivedMetricsUpdatedNotification:"),
    ("CBBridgeManager", "updateScale:forSlot:"),
]


def main():
    extractor = Path(__file__).resolve().parents[1] / "native12-layout-forensic-20261021/extract_layout_imp.py"
    module = runpy.run_path(str(extractor))
    fn = module["main"]
    fn.__globals__["METHODS"] = TARGETS
    fn()


if __name__ == "__main__":
    main()
