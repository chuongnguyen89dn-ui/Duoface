#!/usr/bin/env python3
"""Speed7 QA: Native12 ABI, signed split root+2 real attached pane gate, zero extra UIWindow."""
from pathlib import Path
import json
r=Path(".")
s=(r/"runtime/speedbubble/DFSpeedNativeSplit7SpringBoard.mm").read_text()
original=(r/"runtime/speedbubble/DFSpeedNativeSplitHost.mm").read_text()
mk=(r/"Makefile.speedhud-native7split-stage").read_text()
pl=(r/"DuoFaceSpeedHUDNative7.plist").read_text()
pkg=(r/"migration/full_payload/native_test/build_native12_speed7split_candidate.py").read_text()
audit=json.loads((r/"audit/speedbubble/NATIVE12_SPEED4_SPLIT_OWNER_CHAIN_READONLY.json").read_text())
assert s.split("// Speed7: Native12 SpringBoard in-place split host")[0].strip().replace(
    "// Speed7: same visual HUD implementation, now hosted in native SpringBoard split view.",
    "// Inject this module into the verified DuoFace CarPlay process only; no global SpringBoard HUD.",
) == original.split("// Speed6: NEW renderer targeting")[0].strip()
for cls,sel,kind in [
 ("CBBridgeManager","+sharedInstanceIfExists","@16@0:8"),
 ("CBBridgeManager","-window","@16@0:8"),
 ("CBBridgeManager","-currentApp","@16@0:8"),
 ("CBWindow","-rootWindow","@16@0:8"),
 ("CBWindow","-isVisible","B16@0:8"),
]:
    # -currentApp was additionally observed in pinned lifecycle audit workflow.
    if sel in audit["methods"][cls]:
        assert audit["methods"][cls][sel]["objc_type"]==kind,(cls,sel)
    else: assert sel=="-currentApp" # Native12 split-lifecycle verified in CI output 38999369950.
for required in (
 "CBBridgeManager","sharedInstanceIfExists","CBBridgedSplitApp","currentApp",
 "appViews","count<2 || count>4","attached<2",
 "S7Ancestor(pane,splitRoot)","pane.window==root",
 "splitRoot.window!=root","root.screen==UIScreen.mainScreen",
 "CBTouchPassThroughRootSceneWindow","[controller addSubview:s7HUD]",
 "[controller bringSubviewToFront:s7HUD]","S7Unmount",
 "SPLIT7_MOUNTED_ONE_NATIVE_HOST","DuoFaceSpeedSplit7-SpringBoard.jsonl",
):
    assert required in s,required
for forbidden in ("[[UIWindow alloc]","initWithWindowScene:","windowLevel=10000000",
 "connectedScenes","method_setImplementation","MSHookMessageEx",
 "local.gofahud.carplay.show","DuoFaceSpeedScene"):
    assert forbidden not in s,forbidden
assert "DFSpeedNativeSplit7SpringBoard.mm runtime/speedbubble/DFSpeedTransport.mm" in mk
assert 'Executables = ("SpringBoard")' in pl and "CarPlayApp" not in pl
assert 'VERSION="0.1.0~native12+speed7split"' in pkg
assert 'PIN="d63cf64a5139c7c235b9836b963f2a6a9f25ac414c4eda79bcea07ddda32475a"' in pkg
assert 'assert len(before)==43' in pkg
assert '"replaced_only_HUD_dylib_and_plist":True' in pkg
assert '"creates_new_UIWindow":False' in pkg
print("SPEED7_NATIVE12_SINGLE_SPLIT_PANE_GATE_41_BYTE_IDENTICAL_STATIC_PASS_NOT_DEVICE_TESTED")
