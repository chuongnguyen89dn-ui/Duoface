#!/usr/bin/env python3
"""Non-vendor implementation boundary for Native12 UI -> independent DuoFace QA.

Read actual immutable Native12 / original104 *audit* for class and asset identity.
Assert source-owned replacements and callback targets; never load/call vendor runtime.
STATIC assertions only; no CarPlay device UI acceptance or license component.
"""
from pathlib import Path
import hashlib
import json
import re
import sys

ROOT=Path(__file__).resolve().parents[1]
METRICS=ROOT/"audit/native12-deb-original104-ui/METRICS.json"
REFERENCE={
    "duoface-logo.png":(960,240,"78450d8ee4759353bdc21f27a06016c03fab61038ae60109ba21515c087b0089"),
    "duoface-logo-picker-alpha-v2.png":(627,228,"43b6dafb8fc0550c2b3032c11acae1e0712350ca5b4dd235b7dc14c7951c74f7"),
    "duoface-logo-vert.png":(640,640,"7fa216e2fa89e4fc32e49045ab29d72f6bee3fef4f974444c98fb5bd631e25d2"),
    "VisualAssets/duoface-picker.png":(256,70,"16a959b71a0d3d8ef86e2ac9163024af457aec180770c757fe4b16d2b0a85f8a"),
    "VisualAssets/duoface-fullscreen.png":(88,88,"10e52f01a16cb7d34a81330373a290bcac1bdb0ba9c91119527ef3dcb13cdb36"),
    "VisualAssets/duoface-swap.png":(120,120,"d3ec77c783a186896d63bb08732ee78e427f16e1c127c0785b36bf5eaa037275"),
}
CONTRACT=[
    ("window","CBWindow","createWindows","DFINativeWindowSurface","DFIStart"),
    ("window_usable","CBWindow","carPlayUsableBounds","usableContentFrame","DFIFramesMake"),
    ("picker","CBMultitaskingOverlayView","setupAppPickerCardsInCardW:cardH:contentY:","DFINativePickerCardsController","pickerCardTapped:"),
    ("picker_header","CBMultitaskingOverlayView","setupCardContent","DFINativePickerMenuBar","attachNativePickerHeader"),
    ("slot_buttons","CBSlotPillView","layoutSubviews","DFINativeSlotPillView","choose:"),
    ("divider_hold","CBDividerView","handleMoveButtonLongPress:","DFINativeDividerLogo","moveDividerLogo:"),
    ("divider_resize","CBBridgedSplitApp","handleDividerPan:isVertical:state:","DFINativeDividerTrack","drag:"),
    ("divider_swap","CBBridgedSplitApp","swapSlot:withSlot:","swapPanes","tapAction:@selector(swapPanes)"),
    ("focus","CBBridgedSplitApp","focusSlot:animated:","zoomPane:","self.maximized"),
    ("focus_restore","CBBridgedSplitApp","restoreSplitAnimated:","self.maximized=-1","self.fraction"),
    ("scene_start","CBBridgedUIAppView","startInParentViewController:","DFV12SceneHost","attachTo:"),
    ("scene_geometry","CBBridgedUIAppView","calculateNativeSizeForSlotRect:","resizeTo:","applySize"),
    ("scene_close","CBBridgedUIAppView","dismiss","setRequestedMode:","invalidate"),
]
SOURCEFILES=[
"replacement/visual12/engine/runtime/DFINativeShell.inc",
"replacement/visual12/engine/runtime/DFIInterface.inc",
"replacement/visual12/engine/runtime/DFINativePickerCards.inc",
"replacement/visual12/engine/runtime/DFIRuntime.m",
"replacement/visual12/engine/DFILayouts.h",
]
def main():
    data=json.loads(METRICS.read_text())
    assert data["status"]=="NATIVE12_VS_ORIGINAL104_ACTUAL_DEB_READONLY"
    assert data["device_tested"] is False
    assert data["native12"]["deb_sha256"]=="2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad"
    assert data["original104"]["deb_sha256"]=="f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd"
    assets=data["native12"]["png_assets"]
    source=(ROOT/"replacement/visual12/build_qa.sh").read_text()
    for name,(w,h,sha) in REFERENCE.items():
        x=[z for z in assets if z["path"].endswith("/"+name)]
        assert len(x)==1,(name,len(x))
        assert (x[0]["width_px"],x[0]["height_px"],x[0]["sha256"])==(w,h,sha),name
        # Independent QA already ships the *exact* approved PNG bytes,
        # under its own, separate asset root, not a vendor runtime dependency.
        assert f'"{name}":"{sha}"' in source,name
    src="\n".join((ROOT/p).read_text() for p in SOURCEFILES)
    for label,cls,method,*needles in CONTRACT:
        native=data["native12"]["classes"][cls]
        original=data["original104"]["classes"][cls]
        assert next((m.get("present") for m in native["selected"] if m["name"]==method),None) is True,(cls,method)
        assert next((m.get("present") for m in original["selected"] if m["name"]==method),None) is True,(cls,method,"original104")
        for term in needles:assert term in src,(label,term)
    assert "DFIApprovedHeaderLogo()" in src or "DFIApprovedHeaderLogo" in (ROOT/"replacement/visual12/engine/runtime/DFIApprovedVisuals.h").read_text()
    assert "hold.minimumPressDuration=0.30;" in src
    assert "_scrollView.pagingEnabled=!recent;" in src
    assert "tapAction:@selector(swapPanes)" in src
    for forbidden in ("@implementation CBBridgeManager","@implementation CBLicenseSyncManager",
        'DuoNaviDashboard.dylib','DuoFaceDashboard.dylib'):
        assert forbidden not in src,forbidden
    print("NATIVE12_ACTUAL_DEB_ASSET_HASHES_AND_INDEPENDENT_UI_CALLBACK_CONTRACT_STATIC_PASS")
    print(f"asset_png={len(REFERENCE)} mapping={len(CONTRACT)} device_ui_proven=NO original_vendor_runtime_included=NO")
if __name__=="__main__":
    main()
