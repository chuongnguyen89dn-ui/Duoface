#!/usr/bin/env python3
"""Verify actual Native12 media host geometry & orientation decision callsites."""
import pathlib,runpy
source=pathlib.Path(__file__).resolve().parents[2]/"audit/native12-layout-forensic-20261021/extract_layout_imp.py"
module=runpy.run_path(str(source))
module["main"].__globals__["METHODS"]=[
 ("CBBridgedUIAppView","updateLayout"),
 ("CBBridgedUIAppView","updateSceneFrame"),
 ("CBBridgedUIAppView","calculateNativeSizeForSlotRect:"),
 ("CBBridgedUIAppView","refreshSceneLayout"),
 ("CBBridgedUIAppView","updateSceneSettingsFrame"),
 ("CBBridgedUIAppView","setAppScale:"),
 ("CBBridgeManager","supportsInterfaceOrientation:forBundleID:"),
 ("CBBridgeManager","renderSizeForBundleID:"),
 ("CBBridgedSplitApp","layoutSplitViews"),
]
if __name__=="__main__":module["main"]()
