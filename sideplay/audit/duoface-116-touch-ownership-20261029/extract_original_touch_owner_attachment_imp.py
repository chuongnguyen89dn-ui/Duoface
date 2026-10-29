#!/usr/bin/env python3
"""Original Native12 attachment/hierarchy IMPs to locate CloneTouch ownership.

Read-only original Mach-O disassembly. No execution or vendor code reuse.
"""
from pathlib import Path
import runpy

METHODS = [
    ("CBWindow", "createWindows"),
    ("CBWindow", "initWithAppFrame:"),
    ("CBBridgedSplitApp", "initWithBundleIdentifier:frame:showSplash:"),
    ("CBBridgedSplitApp", "startInParentViewController:"),
    ("CBBridgedUIAppView", "startInParentViewController:"),
    ("CBBridgeManager", "loadNewAppFromCurrentRequest:"),
]


def main() -> None:
    script = (Path(__file__).resolve().parents[1]
              / "native12-layout-forensic-20261021/extract_layout_imp.py")
    module = runpy.run_path(str(script))
    fn = module["main"]
    fn.__globals__["METHODS"] = METHODS
    fn()


if __name__ == "__main__":
    main()
