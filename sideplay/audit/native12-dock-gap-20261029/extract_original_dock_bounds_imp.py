#!/usr/bin/env python3
"""Read-only SHA pinned Native12 v12/HUD8 Dock vs usable bounds IMP audit."""
from pathlib import Path
import runpy

METHODS=[
    ("CBWindow","carPlayContentInsets"),
    ("CBWindow","carPlayUsableBounds"),
    ("CBWindow","carPlayScreenBounds"),
    ("CBWindow","carPlayUIScreen"),
    ("CBWindow","carPlayCADisplay"),
    ("CBWindow","getCarPlayDisplay"),
    ("CBWindow","resetCachedBounds"),
    ("CBWindow","initWithAppFrame:"),
    ("CBWindow","createWindows"),
    ("CBWindow","resizeWindows"),
    ("CBBridgedSplitApp","layoutSplitViews"),
]
def main():
    extractor=Path(__file__).resolve().parents[1]/"native12-layout-forensic-20261021/extract_layout_imp.py"
    module=runpy.run_path(str(extractor))
    fn=module["main"]
    fn.__globals__["METHODS"]=METHODS
    fn()
if __name__=="__main__":
    main()
