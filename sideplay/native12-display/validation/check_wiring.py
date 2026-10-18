#!/usr/bin/env python3
"""Static QA3 Native12→SidePlay integration contract (no device assertion).
Read-only checks actual compiled-source owners and original selector audit.
"""
import json
import re
from pathlib import Path

BASE=Path(__file__).resolve().parents[3]
SRC=(BASE/"sideplay/sileo-qa/Tweak.xm").read_text()
FRAME=(BASE/"sideplay/native12-display/DFSPNativeFrame.m").read_text()
HEADER=(BASE/"sideplay/native12-display/DFSPNativeFrame.h").read_text()
SELECTORS=json.loads((BASE/"sideplay/native12-display/audit/SIDEPLAY_SPLIT_OWNER_SELECTORS.json").read_text())
classes={r["class"]:set(k["selector"] for k in r["selectors"]) for r in SELECTORS["matches"]}
def require(b,desc):
    if not b:
        raise AssertionError(desc)
    print("PASS:",desc)

def uses(owner, selector):
    return selector in classes.get(owner,set())

def count(text,regex):
    return len(re.findall(regex,text))

def main():
    for meth in ("-setRatio:","-ratio","-layout:","-panes",
                 "-paneRequestsSwap:","-showPickerForPane:","-layoutChooser",
                 "-paneRequestsClose:","-setCarWindow:"):
        require(uses("SPDash",meth),"audited SPDash selector "+meth)
    for meth in ("-layoutInFrame:scaleMode:","-appViewController","-view"):
        require(uses("SPPane",meth),"audited SPPane selector "+meth)
    wiring={
        "app":(r"nativeFrameRequestedAppForSlot:",r"\[DFSPManager showPickerForPane:"),
        "zoom":(r"nativeFrameRequestedZoom",r"DFSPApply\(next"),
        "style":(r"nativeFrameRequestedStyle",r"\[DFSPManager layoutChooser\]"),
        "close":(r"nativeFrameRequestedCloseForSlot:",r"\[DFSPManager paneRequestsClose:"),
        "swap":(r"nativeFrameRequestedSwap",r"\[DFSPManager paneRequestsSwap:"),
        "ratio":(r"nativeFrameDraggedToRatio:",r"\[manager setRatio:ratio\]"),
        "paneLayout":(r"\[manager layout:ended\]",r"\[DFSPUI updateFirst:"),
    }
    for label,(delegate,call) in wiring.items():
        require(re.search(delegate,SRC) is not None and re.search(call,SRC) is not None,
                "Native12→SidePlay real handler: "+label)
    require("DFSPHideSidePlayPlaceholder" in SRC and "[pane chipView].hidden=YES" in SRC,
            "old SidePlay placeholder + chip suppressed; live pane retained")
    require("appViewController" in SRC and "DFSPPaneRect" in SRC,
            "visual shell takes actual SidePlay pane rect and app state")
    for selector in ("pillTapped:","swapTapped:","dragDivider:","moveLogo:",
                     "menuTapped:","hitTest:","resetForDisconnect"):
        require(selector in FRAME,"visible Native12 action "+selector)
    require("hold.minimumPressDuration=0.30" in FRAME and
            "requireGestureRecognizerToFail:hold" in FRAME,
            "logo long press and independent pan arbitration installed")
    require("self.logoRelativePosition=" in FRAME and
            "self.currentRatio=ratio" in FRAME,
            "logo position vs split ratio are separate state fields")
    require("return nil;" in FRAME and
            "[self convertPoint:point toView:view]" in FRAME,
            "pass-through touches outside native UI controls")
    require("App" in FRAME and "Zoom" in FRAME and
            "Style" in FRAME and "Close" in FRAME,
            "approved 4-button picker present")
    require("DFSPNativeFrameDelegate" in HEADER,
            "source-owned UI delegate type present")
    require("CBBridgeManager" not in SRC and "DuoFaceDashboard.dylib" not in SRC,
            "no native licensed CarPlay engine imported into QA3")
    print("STATIC WIRING PASS. Device tests NOT executed. Live app pan hit-test still unverified.")

if __name__=="__main__":
    main()
