#!/usr/bin/env python3
"""Fail-closed QA6 source safety checks; not a device/UI parity assertion."""
from pathlib import Path
import re,json
ROOT=Path(__file__).resolve().parents[3]
def read(p):return (ROOT/p).read_text(encoding="utf-8")
t=read("sideplay/sileo-qa/Tweak.xm")
h=read("sideplay/native12-display/DFSPNative12Host.m")
f=read("sideplay/native12-display/DFSPNativeFrame.m")
mk=read("sideplay/sileo-qa/Makefile")
ctl=read("sideplay/sileo-qa/control")
checks={
 "host_used_and_linked": "DFSPNative12Host.m" in mk and
    'initWithCarPlayWindow:window' in t and 'DFSPHost' in t,
 "separate_content_root": 'contentRoot:realRoot' in t and
    '[DFSPHost reconcileAfterSystemLayout]' in t,
 "root_host_changes_content_not_window": 'v.frame=target;' in h and
    'window.frame=' not in h and 'w.frame=' not in h,
 "no_window_contraction_during_normal": "window.frame=desired;" not in t and
    "window.frame=normal" not in t and "oldWindow.frame=DFSPOriginalFrame;" in t,
 "no_unverified_dock_prefs_override": "- (BOOL)carDockMode {" not in t and
    "- (CGRect)carWindowFrameNow {" not in t and "- (void)setCarWindowFrame:(CGRect)frame {" not in t,
 "safebounds_in_window_coords": 'CGRect screenRect=window.bounds;' in t and
    'CGRectContainsRect(screenRect, usable)' in t,
 "original_window_presentation_rollback": all(x in t for x in
    ("DFSPHasOriginalWindowBackground", "oldWindow.backgroundColor=DFSPOriginalWindowBackground",
    "[DFSPHost restoreAndDetach]", "DFSPOriginalLevel")),
 "native_root_fail_closed": all(x in t for x in
    ('if (!DFSPHost) {', 'DFSPRemove();', 'QA6 host refused unsafe geometry')),
 "no_duplicate_big_add_app": '＋ Chọn ứng dụng' not in f and
    "self.placeholders" not in f and "DFSPNativeSlotPill *pill" in f,
 "verified_real_host_panels": "SPPane *one=panes[0]" in t and
    "layoutInFrame:owned scaleMode:" in t,
 "has_native_bar_separate_owner_but_not_misrepresented_as_wired":
    'DFSPNative12ChromeOwner.m' not in mk and 'DFSPNative12ChromeOwner *' not in t,
 "qa6_isolated_version_and_vendor_dependency":
    "0.1.4~native12root6" in ctl and "com.sideplay (>= 1.0.4-1)" in ctl,
 "no_cb_license_binary_link": "DuoFaceDashboard.dylib" not in mk and
    "SidePlay.dylib" not in mk
}
for k,ok in checks.items():
    if not ok: raise AssertionError(f"{k}: failed, do not build")
print(json.dumps({"status":"QA6_SOURCE_SAFETY_PASS_DEVICE_UNVERIFIED",
                  "checks":checks,
                  "unverified":["physical CarPlay bar/owner","actual 2 scenes and orientation",
                                "8 native layouts, 3-app host","Native12 picker/Style, HUD8"]},indent=2))
