#!/usr/bin/env python3
"""Speed6 static safety regression; NOT proof of CarPlay runtime visibility."""
from pathlib import Path
import json

def main():
    root=Path(".")
    mm=(root/"runtime/speedbubble/DFSpeedNativeSplitHost.mm").read_text()
    make=(root/"Makefile.speedhud-split6-stage").read_text()
    plist=(root/"DuoFaceSpeedHUDSplit6.plist").read_text()
    pack=(root/"migration/full_payload/native_test/build_native12_speed6split_candidate.py").read_text()
    audit=json.loads((root/"audit/speedbubble/NATIVE12_GOFAHUD_SPLIT_SCENE_OWNER_READONLY.json").read_text())
    methods=audit["classes"]
    assert methods["CBWindow"]["+activeCarPlayWindow"]["objc_type"]=="@16@0:8"
    assert methods["CBBridgeManagerDashboard"]["-activated"]["objc_type"]=="B16@0:8"
    assert methods["CBBridgeManagerDashboard"]["-bridgeDidActivate:"]["objc_type"]=="v24@0:8@16"
    assert methods["CBBridgeManagerDashboard"]["-bridgeDidDeactivate"]["objc_type"]=="v16@0:8"
    assert methods["CBWindow"]["-show"]["objc_type"]=="v16@0:8"
    assert methods["CBWindow"]["-hide:"]["objc_type"]=="v24@0:8@?16"
    assert methods["CBWindow"]["-destroyWindows"]["objc_type"]=="v16@0:8"
    assert 'Bundles = ("com.apple.CarPlayApp")' in plist and "SpringBoard" not in plist
    assert "com.waze" not in plist and "CarPlayTemplateUIHost" not in plist
    assert "DFSpeedNativeSplitHost.mm runtime/speedbubble/DFSpeedTransport.mm" in make
    assert "DFSpeedSceneOverlay.mm" not in make and "DFSpeedBubbleBridge.mm" not in make
    assert "S6DashboardActive()" in mm and "S6VerifiedHost(owner)" in mm
    assert "S6OriginalGOFARendererDisabled()" in mm
    assert 'local.gofahud.carplay.show' not in mm
    assert "initWithWindowScene:" not in mm
    assert "windowLevel=10000000" not in mm
    assert "connectedScenes" not in mm
    assert "DFProbeCarPlayHostWindows" not in mm
    assert "[host addSubview:s6HUD]" in mm
    assert "[host bringSubviewToFront:s6HUD]" in mm
    assert "S6Unmount" in mm
    assert "CBBridgeManagerDashboard" in mm
    assert "NSClassFromString(@\"GOFACarGlobalWindow\")" in mm
    assert "GOFAHUD" not in plist
    assert "speed6split" in pack
    assert 'NEW=("DuoFaceSpeedHUD.dylib","DuoFaceSpeedHUD.plist")' in pack
    assert 'shutil.copy2("DuoFaceSpeedHUDSplit6.plist",plist)' in pack
    assert '"scene_overlay_window_created":False' in pack
    assert '"no_third_party_injection_or_waze_hooks":True' in pack
    assert "0.1.0~native12+speed6split" in pack
    assert "DuoFaceSpeedHUDSplit6.plist" in pack
    print("SPEED6_SPLIT_HOST_NATIVE12_ABI_AND_ONE_RENDERER_STATIC_PASS; NOT_DEVICE_TESTED")
if __name__=="__main__":
    main()
