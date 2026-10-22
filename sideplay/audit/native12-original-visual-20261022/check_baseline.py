#!/usr/bin/env python3
"""Non-destructive original Native12 DEB/UI-contract gate for independent DuoFace.

Do not interpret a matching ObjC selector or a passing CI run as runtime parity.
Do not copy or execute proprietary license/runtime components.
"""
import argparse
import hashlib
import json
from pathlib import Path

ORIGINAL_DEB_SHA="2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad"
ORIGINAL_DASHBOARD_SHA="9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea"
REPO=Path(__file__).resolve().parents[3]

def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def run():
    p=argparse.ArgumentParser()
    for key in ("deb","extracted","layout","ui","pill","out"):
        p.add_argument("--"+key,required=True,type=Path)
    args=p.parse_args()
    original=sha(args.deb)
    if original!=ORIGINAL_DEB_SHA:
        raise SystemExit("FAIL immutable Native12 DEB sha "+original)
    dashboard=args.extracted/"var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib"
    if not dashboard.is_file():
        raise SystemExit("FAIL original Dashboard absent from extracted Native12 DEB")
    if sha(dashboard)!=ORIGINAL_DASHBOARD_SHA:
        raise SystemExit("FAIL original Dashboard Mach-O SHA mismatch")
    original_files=sum(f.is_file() or f.is_symlink() for f in args.extracted.rglob("*"))
    if original_files!=43:
        raise SystemExit("FAIL original DEB inventory changed: "+str(original_files))
    layout=args.layout.read_text()
    ui=args.ui.read_text()
    pill=args.pill.read_text()
    chrome=(REPO/"sideplay/duoface-native-scene-host/DFNative12Chrome.m").read_text()
    current=(REPO/"sideplay/duoface-native-scene-host/DFLayoutEngine.m").read_text()
    host=(REPO/"sideplay/duoface-native-scene-host/DFSceneHost.m").read_text()

    # Every reference predicate below is independently captured from the
    # project's approved native12 source, separate from our current prototype.
    required={
       "reference_one_to_three_real_panes":
         "o.count=kind==1?1:(kind<=3?2:3)" in layout,
       "reference_eight_layouts":
         "for(int i=1;i<=8;i++)" in ui,
       "reference_single_30pt_menu_row":
         "const CGFloat nativeSide=8.0, nativeMenuHeight=30.0" in ui,
       "reference_two_divider_boundaries":
         "boundaryCount=kind<=3?1:2" in layout,
       "reference_four_menu_items":
         'NSArray *titles=@[@"App",@"Zoom",@"Style",@"Close"]' in ui,
       "reference_native_slot_pill_dimensions":
         "CGFloat width=_focusedMode?(_compactMode?72.0:80.0):" in pill
    }
    if not all(required.values()):
        raise SystemExit("FAIL approved Native12 reference is incompatible with pinned contract "+repr(required))

    checked={
      "style_count":{"reference":8,
          "current":8 if "for(NSInteger idx=0;idx<8;idx++)" in chrome else "unknown"},
      "pane_count_max":{"reference":3,
          "current":3 if "return preset==0?1:(preset==1||preset==2?2:3);" in current else "unknown"},
      "three_columns":{"reference":"three vertical columns",
          "current":"three vertical columns"
            if "CGFloat end=xx+w*(1-a)*c;" in current else "unknown"},
      "style_one_pane_index":{"reference":0,
          "current":0 if "case 0:out[0]=b;break;" in current else "unknown"},
      "menu_row":{"reference":"one 30pt header",
          "current":"one 30pt header"
            if "CGRectMake(bx,7,widths[i]*scale,30)" in chrome
            and "UIVisualEffectView *styleMaterial" in chrome
            else "unknown"},
      "second_divider":{"reference":"two independent movable boundaries",
          "current":"two independent movable boundaries"
            if "secondary-divider-pan-end" in chrome
            and "self.secondaryDividerWindow.hidden=" in chrome
            else "unknown"},
      "zoom_menu":{"reference":"real full-CarPlay Dock toggle",
          "current":"separate Zoom event; no Dock resize ACK"
            if '[self emit:@"Zoom" ratio:nil]' in chrome else "unknown"},
      "pane_pill_position":{"reference":"top-center",
          "current":"top-center" if "CGRectGetMidX(pane[i])-width/2" in chrome else "unknown"},
      "media_video_orientation":{"reference":"app media orientation lifecycle",
          "current":"fixed portrait; not device-proven"
            if "UIInterfaceOrientationPortrait" in host else "unknown"},
    }
    discrepancies=[k for k,v in checked.items() if v["reference"]!=v["current"]]
    result={
        "status":"NO_GO_NATIVE12_EXACT_VISUAL_FUNCTION_PARITY",
        "sources":{"original_native12_deb_sha256":original,
                   "original_dashboard_macho_sha256":sha(dashboard),
                   "original_payload_files":original_files,
                   "approved_layout_reference":str(args.layout),
                   "approved_ui_reference":str(args.ui),
                   "approved_native_pill_reference":str(args.pill),
                   "new_source_ref":"feature/duoface-jb-embedded-appbridge-20261020"},
        "verified_approved_source_predicates":required,
        "comparison":checked,
        "discrepancies":discrepancies,
        "blocking":["no device proof of 8 layouts, touch and two boundary drag",
                    "no original Native12 fullscreen Dock owner/transport wired yet",
                    "video touch/audio/orientation/ExitSafeMode not verified on vehicle"],
        "explicit_user_overrides":["two pills each horizontally centered near top",
                                   "latest historical hold logo 3 seconds; do not silently change it"],
        "constraints":["do not modify original Native12 binary",
                       "do not copy original license/watchdog",
                       "do not overwrite immutable published 0.0.23–0.0.28",
                       "do not publish candidate based solely on this static audit"],
        "device_runtime_tested":False
    }
    args.out.parent.mkdir(parents=True,exist_ok=True)
    args.out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n")
    print("ORIGINAL_NATIVE12_SHA_AND_43_FILE_DEB_EXTRACT_VERIFIED")
    print("CURRENT_UI_SOURCE_PARTIAL_MATCH_RUNTIME_NO_GO")
    for field in discrepancies:
        print("NATIVE12_UI_DELTA",field,json.dumps(checked[field],ensure_ascii=False))
    print("NATIVE12_UI_STATIC_AUDIT_SAVED",args.out)

if __name__=="__main__":
    run()
