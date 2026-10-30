#!/usr/bin/env python3
"""Read-only byte-checked full DEB pair: original DuoNavi 1.0.4 vs signed QA127."""
import argparse, json, pathlib, sys, tempfile
from datetime import datetime, timezone

ROOT=pathlib.Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT/"sideplay/audit/qa125-vs-four-original-real-debs-20261030"))
from full_deb_inventory_and_callback_crosswalk import snapshot, write, digest, RISK_SELECTORS

ORIGINAL_SHA="f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd"
QA127_SHA="ddbc2ded86b768ffd8fa720a0c883e7e6884c24ffc26a142a306431987950a61"
HOST="sideplay/duoface-native-scene-host/"
ORIGINAL_HOOK_PROOF="sideplay/audit/lock-native-duonavi-fullscan-20261030/DEEP_QA122_DUONAVI_LOCK_CONFIRMED_20261030.md"

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--original",type=pathlib.Path,required=True)
    parser.add_argument("--current",type=pathlib.Path,required=True)
    parser.add_argument("--out",type=pathlib.Path,required=True)
    args=parser.parse_args()
    assert digest(args.original)==ORIGINAL_SHA, "ORIGINAL_SHA_MISMATCH"
    assert digest(args.current)==QA127_SHA, "QA127_SHA_MISMATCH"
    assert (ROOT/ORIGINAL_HOOK_PROOF).is_file()
    args.out.mkdir(parents=True,exist_ok=True)
    with tempfile.TemporaryDirectory() as d:
        original=snapshot(args.original,"DuoNavi104",pathlib.Path(d)/"original")
        current=snapshot(args.current,"DuoFaceQA127",pathlib.Path(d)/"qa127")
    for name,pkg in [("DuoNavi104",original),("DuoFaceQA127",current)]:
        write(args.out/(name+"_ALL_FILES_AND_BINARIES.json"),{k:v for k,v in pkg.items() if k!="all_strings"})
    def source(file):
        return (ROOT/HOST/file).read_text(encoding="utf-8")
    life=source("DFSceneLifecycle.m")
    host=source("DFSceneHost.m")
    template=source("DFNativeHostAppDelegate.m")
    geometry=source("DFHostedMapRenderSize.h")
    checks={
        "scene_update_hook":'hook(cls,selector,(IMP)DFUpdateScene' in life,
        "manual_scene_settings_observer":'hook(host,observer,(IMP)DFManagedSceneObserver' in life,
        "scene_destroy_observer":'sceneHandle:didDestroyScene:' in life,
        "underlock_background_hook":'hook(cls,background,(IMP)DFUnderLockBackground123' in life,
        "underlock_intercept_hook":'hook(cls,intercept' in life,
        "underlock_second_hook":'hook(cls,should' in life,
        "weak_owner_registry":'weakToStrongObjectsMapTable' in life,
        "global_owned_foreground_force":'candidate,fg,YES' in life,
        "template_background_stops_touch_owner":'stopTouchOwnerWithReason:@"scene-background"' in template,
        "generic_2x_logical_viewport":'pane.width*2.0' in geometry and 'pane.height*2.0' in geometry,
        "scene_owner_probe_requires_attached_window":'surface.appController.viewIfLoaded.window!=surface.window' in host,
        "qa127_frame_write_no_foreground_writer":'QA127 real-device root-cause audit' in host
    }
    assert checks["scene_update_hook"] and checks["manual_scene_settings_observer"]
    assert checks["underlock_background_hook"] and not checks["scene_destroy_observer"]
    original_tokens=set(RISK_SELECTORS)&original["all_strings"]
    current_tokens=set(RISK_SELECTORS)&current["all_strings"]
    results={
        "timestamp_utc":datetime.now(timezone.utc).isoformat(),
        "scope":"exact signed QA127 package vs authentic stock DuoNavi104: entire package manifest + all Mach-O + source contract",
        "original_sha":original["sha256"],"qa127_sha":current["sha256"],
        "original_file_count":original["file_count"],"qa127_file_count":current["file_count"],
        "original_macho_count":original["binary_count"],"qa127_macho_count":current["binary_count"],
        "original_only_risk_tokens":sorted(original_tokens-current_tokens),
        "qa127_only_risk_tokens":sorted(current_tokens-original_tokens),
        "original_underlock_registered_from_verified_arm64":{
            "interceptUpdateForScene:withNewSettings:":"0x2ecf80",
            "_shouldBeBackgroundUnderLockForScene:withSettings:":"0x2ecfa0",
            "shouldBeUnderLockForScene:":"0x2ecfc0"
        },
        "current_source_gates":checks,
        "limitations":"String/selector presence is not functional parity. iOS16.7.16 does not expose all original selectors. No proof of physical app touch ACK, scene owner or fixed crash.",
        "release_status":"NO SOURCE RUNTIME PATCH. NO BUILD. NO SILEO PUBLICATION. NO DEVICE TEST."
    }
    write(args.out/"SUMMARY.json",results)
    lines=[
        "# Original DuoNavi 1.0.4 vs signed DuoFace QA127 — two real DEBs",
        "",
        "## SHA256-verified artifact bytes and package inventory",
        "| File | SHA256 | Paths | Mach-O |",
        "|---|---|---:|---:|",
        "| Original DuoNavi 1.0.4 | "+original["sha256"]+" | "+str(original["file_count"])+" | "+str(original["binary_count"])+" |",
        "| Signed DuoFace QA127 | "+current["sha256"]+" | "+str(current["file_count"])+" | "+str(current["binary_count"])+" |",
        "",
        "Full control/maintainer scripts, file hashes/modes, plist filters, binary UUID/imports and risk-selector presence are in two retained JSON manifests.",
        "",
        "## Original callback contract vs QA127 implementation",
        "| Original evidence | QA127 first-party source |",
        "|---|---|",
        "| DuoNavi three exact ARM64 under-lock registrations at 0x2ecf80/0x2ecfa0/0x2ecfc0 | Only one runtime-ABI-approved background predicate hook; the other methods are not hooked |",
        "| Native12 original observer and separate scene-destroy callback | DFSceneLifecycle.m only hooks settings observer; no separate scene-destroy callback |",
        "| Original selected-app/hosted-scene identity marker + display identity policy | QA127 uses weak current-scene registry and window-dependent owner proof; cannot simply reuse vendor markers |",
        "| Original bridge owner coordinates app lifetime, UI host and frame | QA127 still globally changes foreground NO->YES while CPTemplate background indiscriminately stops TouchOwner |",
        "| Original renderSizeForBundleID app policy | QA127 generic logical 2x for every app, no GOFA map layout receiver confirmation |",
        "",
        "## What this DOES NOT prove",
        "- Legacy audit run 41015886871 examined signed QA125; this run actually examines signed QA127 bytes.",
        "- Original methods are disassembled and registered in SHA-pinned prior audits, not executed by this scanner.",
        "- Do not hook original selectors missing on iOS16.7.16; never reuse licensing or passcode/activation logic.",
        "- Original package might itself have app-specific assumptions. Similar strings are not a runtime fix.",
        "- User reports QA127 still crashes and touch does not work; this scanner does not fix or device-test it.",
        "",
        "## Concrete repair gate",
        "Implement first-party per-generation scene owner and coherent update/destroy handling, first with exact controller/handle/scene identity, before further foreground modifications. Distinguish true Home/unplug from iPhone lock and verify installed vs loaded dylib UUID. Preserve QA90 rotation, QA92 divider and QA120 Dock. Verify touch transport at the app receiver rather than assuming a pane hit equals Play. Rebuild only once a specific source repair is testable; do not publish guesses.",
        ""
    ]
    (args.out/"REPORT.md").write_text("\n".join(lines),encoding="utf-8")
    assert len(original["files"])==original["file_count"]
    assert len(current["files"])==current["file_count"]
    print("EXACT_TWO_DEB_QA127_VS_DUONAVI_SCAN_PASS","original",original["file_count"],original["binary_count"],"qa127",current["file_count"],current["binary_count"],"NO_SILEO_CHANGE")

if __name__=="__main__": main()
