#!/usr/bin/env python3
"""Read-only SpringBoard owner probe: no extra CarPlay renderer and native API pin checks."""
from pathlib import Path
import json
def main():
    root=Path(".")
    code=(root/"runtime/speedbubble/DFSpeedSpringBoardOwnerProbe.mm").read_text()
    make=(root/"Makefile.speedhud-springboard-owner-stage").read_text()
    plist=(root/"DuoFaceSpeedOwner.plist").read_text()
    pkg=(root/"migration/full_payload/native_test/build_native12_speed6zzowner1_candidate.py").read_text()
    audit=json.loads((root/"audit/speedbubble/NATIVE12_SPEED4_SPLIT_OWNER_CHAIN_READONLY.json").read_text())
    owner=audit["methods"]["CBBridgeManager"]
    assert owner["+sharedInstanceIfExists"]["objc_type"]=="@16@0:8"
    assert owner["-window"]["objc_type"]=="@16@0:8"
    native=audit["methods"]["CBWindow"]
    assert native["+activeCarPlayWindow"]["objc_type"]=="@16@0:8"
    assert native["-rootWindow"]["objc_type"]=="@16@0:8"
    for required in (
        "sharedInstanceIfExists","activeCarPlayWindow","SPRINGBOARD_NATIVE12_OWNER_PROBE",
        "SPRINGBOARD_OWNER_PROBE_LOADED","DuoFaceSpeedOwner-SpringBoard.jsonl",
        "manager_window","manager_instance_class","native_CBWindow","external_screen",
        "scene_role","content_window_is_root","content_descends_controller",
        "now-DFOwnerLastWrite<15.0","isEqualToString:@\"SpringBoard\"",
    ): assert required in code,required
    for forbidden in (
        "method_setImplementation","MSHookMessageEx","initWithWindowScene:",
        "windowLevel","makeKeyAndVisible","addSubview:","connectedScenes",
        "setWindowScene:","sharedInstance\");", "local.gofahud.carplay.show",
    ): assert forbidden not in code,forbidden
    assert "DFSpeedSpringBoardOwnerProbe.mm" in make
    assert "DFSpeedSceneOverlay.mm" not in make
    assert "DuoFaceSpeedOwner" in make
    assert 'Executables = ("SpringBoard")' in plist
    assert "CarPlayApp" not in plist
    assert 'VERSION="0.1.0~native12+speed6zzowner1"' in pkg
    assert 'PIN="42f7300463fa7aeecfb28342298e5faf3c77dcf0319e77964a6b35622eba722e"' in pkg
    assert 'NEW=("DuoFaceSpeedOwner.dylib","DuoFaceSpeedOwner.plist")' in pkg
    assert "len(before)==41" in pkg
    assert '"all_previous_speed6_payload_files_byte_identical":True' in pkg
    assert '"no_springboard_uiwindow_creation_or_method_hooks":True' in pkg
    print("OWNERPROBE_NATIVE12_KNOWN_ABI_READONLY_NO_UIWINDOW_NO_WAZE_PASS_NOT_DEVICE_TESTED")
if __name__=="__main__":main()
