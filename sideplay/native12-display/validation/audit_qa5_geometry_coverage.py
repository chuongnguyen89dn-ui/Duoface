#!/usr/bin/env python3
"""Static coverage audit: QA5 vs pinned DuoFace Native12 geometry.

PASS means the audit detects existing gaps correctly, NOT that UI is complete.
--require-complete blocks release until the P0 invariants are actually present.
No DEB rescanning, network, proprietary code or device assertions.
"""
from __future__ import annotations
import argparse, json, os
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
def get(path):return (ROOT/path).read_text(encoding="utf-8")
mk=get("sideplay/sileo-qa/Makefile")
bridge=get("sideplay/sileo-qa/Tweak.xm")
frame=get("sideplay/native12-display/DFSPNativeFrame.m")
pill=get("sideplay/native12-display/DFSPNativeSlotPill.m")
reference=os.environ.get("NATIVE12_LAYOUTS_REFERENCE_FILE","")
assert reference, "Set NATIVE12_LAYOUTS_REFERENCE_FILE from pinned visual12 commit"
geometry=Path(reference).read_text(encoding="utf-8")
models=get("sideplay/native12-display/DFSPDisplayState.c")
checks={
  "native_reference_eight_layouts":all(x in geometry for x in (
     "kind>8", "kind==1", "kind==2", "kind==3", "kind==4", "kind==5", "kind==6", "kind==7")),
  "native_reference_3_panes":("panes[3]" in geometry),
  "native_reference_secondary_ratio":("double a,double b" in geometry),
  "qa5_fixed_two_pills":("for (NSInteger i=0;i<2;i++)" in frame),
  "qa5_only_two_pane_rects":all(x in frame for x in ("firstRect","secondRect")) and
                             ("thirdRect" not in frame),
  "qa5_no_secondary_ratio":("secondaryRatio" not in frame and "secondary" not in frame),
  "qa5_single_ratio":("self.currentRatio=DFSPClampRatio" in frame and
                     "[manager setRatio:ratio]" in bridge),
  "qa5_window_shrunk_at_apply":("window.frame=desired;" in bridge),
  "qa5_window_shrunk_by_layout_root":("window.frame=desired;" in bridge.split("- (void)layoutRootView")[1]),
  "qa5_window_coords_derived_from_screen":("CGRect screenRect = window.screen.bounds;" in bridge),
  "qa5_64_pt_fallback":("DFSPNativeFallbackLeft = 64.0" in bridge),
  "qa5_forces_dock_false":("if (DFSPManager==self && DFSPWindow && !DFSPFull) return NO" in bridge),
  "qa5_overrides_window_level":("UIWindowLevelStatusBar-1.0" in bridge),
  "qa5_bypasses_owned_root_host":("DFSPNative12Host.m" not in mk and
                                  "DFSPNative12Host" not in bridge),
  "qa5_bar_owner_not_linked":("DFSPNative12ChromeOwner.m" not in mk and
                              "DFSPNative12ChromeOwner" not in bridge),
  "qa5_zoom_coordinator_not_linked":("DFSPDisplayCoordinator.m" not in mk and
                                     "DFSPDisplayCoordinator" not in bridge and
                                     "DFSPDisplayState.c" not in mk),
  "qa5_only_pill_metrics_six":all(x in pill for x in (
      "self.compact?72:80","self.compact?64:76","self.compact?38:44",
      "self.compact?19:22")),
  "qa5_divider_draws_from_pane_frames_not_ratio":(
      "CGRectGetMaxX(a)+CGRectGetMinX(b)" in frame and
      "CGRectGetMaxY(a)+CGRectGetMinY(b)" in frame and
      "self.currentRatio" not in frame.split("- (void)layoutSubviews")[1].split("- (UIView *)hitTest:")[0]),
  "qa5_old_sideplay_picker_still_visible":("[DFSPManager showPickerForPane:pane]" in bridge),
  "qa5_old_sideplay_style_still_visible":("[DFSPManager layoutChooser]" in bridge),
  "qa5_existing_separate_normal_bar_zoom_model":(
      "DFSP_SHOW_SYSTEM_BAR" in models and
      "DFSP_APPLY_HOST_NORMAL" in models and "DFSP_HIDE_SYSTEM_BAR" in models)
}
missing=[k for k,v in checks.items() if not v]
assert not missing,"Source drift; re-audit needed: "+", ".join(missing)
gaps=[
   "MAIN_WINDOW_CONTRACTED_INSTEAD_OF_CONTENT",
   "NO_VERIFIED_CARPLAY_BAR_OWNER_IN_RELEASE",
   "ONLY_2_PANES_1_RATIO_NOT_8_NATIVE_LAYOUTS",
   "SECOND_RATIO_AND_THIRD_PANE_MISSING",
   "DIVIDER_FRAME_NOT_DIRECTLY_BOUND_TO_RENDERED_RATIO",
   "ORIGINAL_SIDEPLAY_PICKER_AND_STYLE_STILL_VISIBLE",
   "NO_SCENE_RESIZE_AND_ORIENTATION_DEVICE_PROOF"
]
result={"scope":"source static ONLY, approved Native12 reference + QA5 source",
        "qa5_release":"0.1.3~native12ui5",
        "status":"NOT_NATIVE12_COMPLETE",
        "reference_8_layouts_not_deb_pane_count_proven":True,
        "source_checks":checks, "blocking_gaps":gaps,
        "ready_for_claim_native_parity":False}
print(json.dumps(result,indent=2,ensure_ascii=False))
if __name__=="__main__":
    cli=argparse.ArgumentParser()
    cli.add_argument("--require-complete",action="store_true")
    args=cli.parse_args()
    if args.require_complete:
        print("BLOCK: Native12 UI completeness not proven; DO NOT PUBLISH as fixed")
        raise SystemExit(2)
