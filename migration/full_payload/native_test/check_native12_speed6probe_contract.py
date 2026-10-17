#!/usr/bin/env python3
"""Check actual Native12 ABI and Speed6Probe read-only single-renderer regression."""
from pathlib import Path
import json
def main():
    r=Path(".")
    source=(r/"runtime/speedbubble/DFSpeedNativeHostProbe.mm").read_text()
    previous=(r/"runtime/speedbubble/DFSpeedNativeSplitHost.mm").read_text()
    mk=(r/"Makefile.speedhud-split6-probe-stage").read_text()
    plist=(r/"DuoFaceSpeedHUDSplit6.plist").read_text()
    pack=(r/"migration/full_payload/native_test/build_native12_speed6probe1_candidate.py").read_text()
    native=json.loads((r/"audit/speedbubble/NATIVE12_GOFAHUD_SPLIT_SCENE_OWNER_READONLY.json").read_text())
    assert native["classes"]["CBWindow"]["+activeCarPlayWindow"]["objc_type"]=="@16@0:8"
    assert native["classes"]["CBBridgeManagerDashboard"]["-activated"]["objc_type"]=="B16@0:8"
    assert native["classes"]["CBBridgeManagerDashboard"]["-bridgeDidActivate:"]["objc_type"]=="v24@0:8@16"
    assert native["classes"]["CBWindow"]["-hide:"]["objc_type"]=="v24@0:8@?16"
    assert source.split("// Speed6: NEW renderer")[0]==previous.split("// Speed6: NEW renderer")[0]
    for code in ("S6DashboardActive()","S6OriginalGOFARendererDisabled()",
          "S6VerifiedHost(owner)","[host addSubview:s6HUD]",
          "[host bringSubviewToFront:s6HUD]","S6Unmount"):
        assert code in source,code
    for probe in ("PROBE_NATIVE_HOST","raw_active_window_class","raw_is_CBWindow",
          "host_probe_reason","root_scene_role","content_window_matches_root",
          "controller_window_matches_root","content_descends_from_controller",
          "hooks","s6ProbePrevious","now-s6ProbeAt<15.0"):
        assert probe in source,probe
    for forbidden in ("DFProbeCarPlayHostWindows","windowLevel=10000000",
         "initWithWindowScene:","connectedScenes","local.gofahud.carplay.show"):
        assert forbidden not in source,forbidden
    assert 'NSBundle.mainBundle.bundleIdentifier.lowercaseString' in source
    assert '@"com.apple.carplayapp"' in source
    assert "DFSpeedNativeHostProbe.mm runtime/speedbubble/DFSpeedTransport.mm" in mk
    assert "DFSpeedNativeSplitHost.mm" not in mk and "DFSpeedSceneOverlay" not in mk
    assert 'Bundles = ("com.apple.CarPlayApp")' in plist and "SpringBoard" not in plist
    assert 'NEW=("DuoFaceSpeedHUD.dylib","DuoFaceSpeedHUD.plist")' in pack
    assert 'shutil.copy2("DuoFaceSpeedHUDSplit6.plist",plist)' in pack
    assert 'assert dll.stem==plist.stem' in pack
    assert 'VERSION="0.1.0~native12+speed6zprobe1"' in pack
    assert '"host_probe_only_no_gate_relaxation":True' in pack
    assert '"scene_overlay_window_created":False' in pack
    print("SPEED6PROBE_NATIVE12_ABI_SINGLE_SPLIT_HOST_AND_LOG_SAFETY_STATIC_PASS_NOT_DEVICE_TESTED")
if __name__=="__main__":
    main()
