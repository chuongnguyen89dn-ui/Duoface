#!/usr/bin/env python3
"""Static QA3 contract checks: Native12 GUI controls -> real SidePlay host ABI.
Source/audit only, no compiled binary extraction, no license logic.
"""
import hashlib
import json
import re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
AUDIT=ROOT/"sideplay/native12-display/audit/SIDEPLAY_SPLIT_OWNER_SELECTORS.json"
FRAMES=(ROOT/"sideplay/native12-display/DFSPNativeFrame.m").read_text()
BRIDGE=(ROOT/"sideplay/sileo-qa/Tweak.xm").read_text()
MAKE=(ROOT/"sideplay/sileo-qa/Makefile").read_text()
CONTROL=(ROOT/"sideplay/sileo-qa/control").read_text()
ASSET=ROOT/"dist/visual-1.0.3-12/assets/duoface-logo-picker-alpha-v2.png"
assert hashlib.sha256(ASSET.read_bytes()).hexdigest()=="43b6dafb8fc0550c2b3032c11acae1e0712350ca5b4dd235b7dc14c7951c74f7"
items=json.loads(AUDIT.read_text())["matches"]
owners={entry["class"]:{m["selector"]:m["type"] for m in entry["selectors"]} for entry in items}
want={
  "SPDash":{"-setRatio:":"v24@0:8d16","-ratio":"d16@0:8","-layout:":"v20@0:8B16",
            "-paneRequestsSwap:":"v24@0:8@16","-paneRequestsClose:":"v24@0:8@16",
            "-showPickerForPane:":"v24@0:8@16","-layoutChooser":"v16@0:8"},
  "SPPane":{"-view":"@16@0:8","-chipView":"@16@0:8","-layoutButton":"@16@0:8",
            "-appViewController":"@16@0:8"}
}
for owner,methods in want.items():
    assert owner in owners,owner
    for name,typ in methods.items():
        assert owners[owner].get(name)==typ,(owner,name,owners[owner].get(name),typ)
checks={
 "native_default_pills":'duoface.native.slot.%ld.pill' in FRAMES,
 "native_picker_menu":all(f'@"{x}"' in FRAMES for x in ("App","Zoom","Style","Close")),
 "native_approved_sheet":'UIBlurEffectStyleSystemMaterialDark' in FRAMES and 'DFSPSheetRadius = 20.0' in FRAMES,
 "divider_drag":'UIPanGestureRecognizer' in FRAMES and 'nativeFrameDraggedToRatio:ratio ended:ended' in FRAMES,
 "logo_hold":'minimumPressDuration=0.30' in FRAMES,
 "logo_swap":'nativeFrameRequestedSwap' in FRAMES,
 "native_ratio_bounds":'1.0/3.0' in FRAMES and '2.0/3.0' in FRAMES,
 "host_live_set_ratio":'[manager setRatio:ratio]' in BRIDGE and '[manager layout:ended]' in BRIDGE,
 "hide_sideplay_old_controls":'[pane chipView].hidden=YES' in BRIDGE and '[pane layoutButton].hidden=YES' in BRIDGE,
 "old_zoom_floating_removed":not re.search(r"DFSPPositionZoom|DFSPZoomQA2Target|DFSPZoomTag|static UIButton \*DFSPZoom",BRIDGE),
 "original_app_host_preserved":'%hook SPDash' in BRIDGE and '%orig;' in BRIDGE,
 "native_frame_linked":"../native12-display/DFSPNativeFrame.m" in MAKE,
 "test_package_isolation":"Package: com.duoface.sideplaydisplay" in CONTROL and
        "Version: 0.1.1~native12frame3" in CONTROL
}
for k,v in checks.items():
    assert v,k
print(json.dumps({"checks":len(checks),"passed":list(checks.keys()),"sideplay_owners":list(want.keys()),
    "source_pinned_original_sha":json.loads(AUDIT.read_text())["sha256"]},ensure_ascii=False,indent=2))
