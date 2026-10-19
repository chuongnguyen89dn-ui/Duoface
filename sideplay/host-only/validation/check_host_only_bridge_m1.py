#!/usr/bin/env python3
"""Milestone M1: licensed SidePlay APP HOST ONLY boundary, Native12 visual owner.

Static gate: verifies exactly which working host selectors cross into
DuoFace; does not claim vendor package UI has been removed or device tested.
Run at repo root: python3 sideplay/host-only/validation/check_host_only_bridge_m1.py
"""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
def read(path):return (ROOT/path).read_text(encoding="utf-8")
def check(ok, message):
    if not ok:raise AssertionError(message)
    print("HOST_M1_PASS",message)
h=read("sideplay/host-only/DFSPSceneHostBridge.h")
src=read("sideplay/host-only/DFSPSceneHostBridge.m")
tweak=read("sideplay/sileo-qa/Tweak.xm")
make=read("sideplay/sileo-qa/Makefile")
ctl=read("sideplay/sileo-qa/control")
index=json.loads(read("sideplay/native12-display/audit/SIDEPLAY_SPLIT_OWNER_SELECTORS.json"))

check("DFSPSceneHostBridge.m" in make and
      "DFSPSceneHostBridge.h" in tweak and
      "DFSPSceneHostBridge *DFSPSceneBridge" in tweak,
      "app scene host boundary compiled and attached to Native12 visual shell")
check("DFSPSceneBridge=[[DFSPSceneHostBridge alloc]" in tweak and
      "DFSPSceneBridge=nil;" in tweak and
      "DFSPSceneBridge.carWindow!=DFSPWindow" in tweak,
      "host lease tied to connected external CarPlay scene and detached safely")
check("hostedFrameForSlot:0 relativeToView:DFSPUI" in tweak and
      "hostedFrameForSlot:1 relativeToView:DFSPUI" in tweak and
      "hasHostedAppInSlot:0" in tweak and
      "hasHostedAppInSlot:1" in tweak and
      "firstApp=[pane appViewController]" not in tweak and
      "secondApp=[pane appViewController]" not in tweak,
      "two Native12 slot statuses and view rectangles now pass host boundary")
check("SPDash" in src and "SPPane" in src and
      all(k in src for k in ("- (NSArray *)panes;", "- (UIView *)view;",
        "- (id)appViewController;")),
      "host boundary has only verified app/scene lifecycle selectors")
check(all(k not in src for k in (
      "- (void)layoutChooser;", "- (void)showPickerForPane:",
      "- (void)setRatio:", "- (void)slideBarHidden:",
      "@selector(serviceBlocked)", "@selector(applyServiceState)",
      "@selector(licenseWatchdogTimerFired:)", "#import \"SidePlay",
      "CBBridgeManager *", "@selector(unlock)")),
      "no SidePlay UI/layout/license or Native12 license-bundled manager API in host boundary")
check("loadBundleIdentifier:" not in src and
      "loadBundleIdentifier:" not in h and
      "- (void)loadApp:" not in src and
      "M1 is intentionally READ ONLY" in h,
      "ObjC encoding @ cannot establish -loadApp: parameter type; launching deliberately gated until M2")
check("Package: com.duoface.sideplaydisplay" in ctl and
      "Version: 0.1.9~native12dock11" in ctl and
      "com.sideplay (>= 1.0.4-1)" in ctl and
      "SidePlay.dylib" not in make,
      "QA11 Sileo release and legal SidePlay host dependency remain unchanged")
check("DFSPNativeDock.xm" in make and
      "../native12-display/DFSPNativeFrame.m" in make and
      "DFSPNative12Host.m" in make,
      "no untested replacement of Native12 visual/CarPlay window code")

classes={entry["class"]:entry for entry in index["matches"]}
for cls, selectors in {"SPDash":{"-panes":"@16@0:8"},
                       "SPPane":{"-view":"@16@0:8",
                                 "-appViewController":"@16@0:8"}}.items():
    table={s["selector"]:s["type"] for s in classes[cls]["selectors"]}
    for selector,encoding in selectors.items():
        check(table.get(selector)==encoding,
              f"original SidePlay 1.0.4 ABI confirmed {cls}.{selector}")
print("HOST_M1_STATIC_PASS — no DEB release, app hosting remains SidePlay-owned")
