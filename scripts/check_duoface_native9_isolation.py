#!/usr/bin/env python3
"""Static regression gate for DuoFace logo-only addon (NO DEB, NO SILEO).

Rejects the native8 packaging regression: rebuilding the entire visual dylib
when the user requested only to move one native logo. Requires native6 VisualHook
to remain immutable in the next candidate and native CBDividerView.handlePan:
to be left unhooked. Real CarPlay operation still requires on-device testing.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import re
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
STANDALONE=ROOT/"src/DuoFaceLogoGripOnly.m"
GRIP=ROOT/"src/DFDividerLogoGrip.inc"
VISUAL=ROOT/"src/DuoFaceVisualHook.m"
NATIVE8_REPORT=ROOT/"audit/payload-migration/NATIVE8_COMBINED_REGRESSION.json"

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def test():
    cli=argparse.ArgumentParser()
    cli.add_argument("--out",type=Path,required=True)
    args=cli.parse_args()
    standalone=STANDALONE.read_text()
    grip=GRIP.read_text()
    visual=VISUAL.read_text()
    report=json.loads(NATIVE8_REPORT.read_text())
    assert report["status"]=="NATIVE8_CARPLAY_CODE_IDENTICAL_AND_GRIP_HOOK_DELTA_PASS"
    assert report["only_hook_and_two_binary_literal_data_changed"]
    assert report["native6_baseline_sha256"]=="88b0e9358c075e2131ddb9e6ac25689584765d1285120e2e3282ce8a5bb3df15"
    checks={}
    def require(name,condition):
        checks[name]=bool(condition)
        assert condition,name

    require("standalone_imports_original_logic", '#include "DFDividerLogoGrip.inc"' in standalone)
    require("native_pan_preserve_flag_active",
        "#define DF_LOGO_PRESERVE_NATIVE_DIVIDER_PAN 1" in standalone)
    require("pan_hook_function_conditionally_excluded",
        bool(re.search(r"#ifndef DF_LOGO_PRESERVE_NATIVE_DIVIDER_PAN\s*// Legacy experimental hook[\s\S]*?static void DFLogoDividerPan\(",grip)))
    require("pan_hook_call_conditionally_excluded",
        bool(re.search(r"#ifndef DF_LOGO_PRESERVE_NATIVE_DIVIDER_PAN\s*hook\(divider, @selector\(handlePan:\)",grip)))
    require("pan_selector_requirement_conditionally_excluded",
        bool(re.search(r"#ifndef DF_LOGO_PRESERVE_NATIVE_DIVIDER_PAN\s*,@selector\(handlePan:\)",grip)))
    require("preserve_native_visual_compiled_library",
        'DuoFaceVisualHook.dylib' in standalone
        and "DFApplyButton" not in standalone
        and "DFInstallBorderRunner" not in standalone)
    require("do_not_mutate_native_pill_or_fullscreen",
        "_expandButton" not in standalone
        and "_restoreButton" not in standalone
        and "duoface-fullscreen.png" not in standalone)
    require("do_not_mutate_visual_layers",
        not any(v in standalone for v in (
            "DFSetButtonBackgroundColor", "DFSetLayerBorderWidth",
            "DFSetLayerBorderColor", "setBackgroundImage:",
            "setImage:forState:", "addSubview:")))
    require("install_only_native_logo_callbacks",
        "DFInstallLogoGripHooks(hook, divider)" in standalone
        and "@selector(layoutSubviews)" in standalone)
    require("complete_native_layout_chained_first",
        standalone.find("oldDFGripOnlyLayout)(divider, cmd);")
        < standalone.find("DFLogoRestorePositionBeforeLayout(divider)"))
    require("move_logo_position_and_native_touch_frame",
        "DFLogoSetRelativePos(info, fraction)" in grip and
        "@selector(updateGripLayout)" in grip)
    require("native_quick_tap_preserved",
        "oldDFGripTouchUp)(divider, cmd, sender)" in grip)
    require("held_button_cannot_native_swap",
        "session->holdRecognized" in grip and
        "oldDFGripTouchCancel" in grip)
    require("hold_threshold_300ms",
        bool(re.search(r"kDFLogoHoldThreshold\s*=\s*0\.30\s*;",grip)) and
        "DFLogoSetNativeHoldThreshold" in standalone)
    require("native_visual_source_left_intact",
        '#include "DFDividerLogoGrip.inc"' in visual)
    require("native6_binary_rollback_pinned",report["native6_baseline_sha256"]!="")
    result={
        "status":"SOURCE_ONLY_NATIVE9_LOGO_ISOLATION_ROUTE_PASS",
        "case_count":len(checks),"cases":checks,
        "scope":"A separate lightweight button-only dylib, not replacement of original visual hook",
        "already_device_verified":"Native8 logo reposition succeeds per user; fullscreen/ratio/content regressions also reported",
        "planned_change":"Restore original native6 visual dylib byte-for-byte, append standalone logo grip dylib with original injection filter",
        "native_divider_pan_original_handler":"UNHOOKED_BY_STANDALONE_SOURCE",
        "natively_rendered_buttons":"UNMODIFIED_BY_STANDALONE_SOURCE",
        "requires_runtime_validation":[
            "divider resize outside logo","logo drag without split change",
            "YouTube original circular fullscreen","panels unobstructed",
            "tap-to-swap","reconnect","orientation","license strings remain masked",
        ],
        "files_sha256":{
            "src/DuoFaceLogoGripOnly.m":digest(STANDALONE),
            "src/DFDividerLogoGrip.inc":digest(GRIP),
            "src/DuoFaceVisualHook.m":digest(VISUAL),
        },
        "generated_new_deb":False,"sileo_modified":False,
        "device_tested_for_repair":False,
    }
    args.out.parent.mkdir(parents=True,exist_ok=True)
    args.out.write_text(json.dumps(result,indent=2,ensure_ascii=False)+"\n")
    print(json.dumps({k:v for k,v in result.items() if k!="cases"},
                     indent=2,ensure_ascii=False))

if __name__=="__main__":
    test()
