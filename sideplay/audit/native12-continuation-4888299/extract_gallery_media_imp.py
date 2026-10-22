#!/usr/bin/env python3
"""Reuse existing immutable Native12 IMP extractor for unresolved gallery/media wiring."""
import pathlib, runpy
source=pathlib.Path(__file__).resolve().parents[2]/"audit/native12-layout-forensic-20261021/extract_layout_imp.py"
d=runpy.run_path(str(source))
d["main"].__globals__["METHODS"]=[
 ("CBMultitaskingOverlayView","showLayoutChooserInParentView:"),
 ("CBMultitaskingOverlayView","layoutSubviews"),
 ("CBBridgedUIAppView","calculateNativeSizeForSlotRect:"),
 ("CBBridgedUIAppView","updateSceneSettingsFrame"),
 ("CBBridgedUIAppView","refreshSceneLayout"),
 ("CBBridgedUIAppView","setAudioOnlyBackgroundMode:"),
 ("CBBridgedUIAppView","dismiss"),
]
if __name__=="__main__":d["main"]()
