#!/usr/bin/env python3
"""Read-only SHA-pinned Native12 host lifecycle IMP extraction."""
import pathlib,runpy
source=pathlib.Path(__file__).resolve().parents[2]/"audit/native12-layout-forensic-20261021/extract_layout_imp.py"
module=runpy.run_path(str(source))
module["main"].__globals__["METHODS"]=[
 ("CBBridgedUIAppView","initWithBundleIdentifier:"),
 ("CBBridgedUIAppView","initWithBundleIdentifier:scale:"),
 ("CBBridgedUIAppView","start"),
 ("CBBridgedUIAppView","startInParentViewController:"),
 ("CBBridgedUIAppView","setHosting:"),
 ("CBBridgedUIAppView","setInvalidated:"),
 ("CBBridgedUIAppView","setAudioOnlyBackgroundMode:"),
 ("CBBridgedUIAppView","dismiss"),
 ("CBBridgedUIAppView","dealloc"),
]
if __name__=="__main__":module["main"]()
