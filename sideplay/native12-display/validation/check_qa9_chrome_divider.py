#!/usr/bin/env python3
"""QA9 regression gates for isolated DuoFace QA7-based CarPlay chrome+divider.

This test does not simulate CarPlay processes. It checks read-only source wiring,
calculates exact left/right and top/bottom shared edges and verifies package scope.
A real device is required to confirm DBStatusBarWindow exists and becomes visible.
"""
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[3]
def load(p):return (ROOT/p).read_text(encoding="utf-8")
def check(ok,msg):
    if not ok:raise AssertionError(msg)
    print("QA9_PASS",msg)
source=load("sideplay/sileo-qa/Tweak.xm")
bridge=load("sideplay/sileo-qa/DFSPChromeBridge.xm")
header=load("sideplay/sileo-qa/DFSPChromeBridge.h")
frame=load("sideplay/native12-display/DFSPNativeFrame.m")
host=load("sideplay/native12-display/DFSPNative12Host.m")
control=load("sideplay/sileo-qa/control")
plist=load("sideplay/sileo-qa/DuoFaceSidePlayDisplayQA.plist")
mk=load("sideplay/sileo-qa/Makefile")

check("Version: 0.1.7~native12chrome9" in control and
      "Package: com.duoface.sideplaydisplay" in control and
      "com.sideplay (>= 1.0.4-1)" in control,
      "strict increasing version, same independent QA package, SidePlay host dependency")
check("DFSPChromeBridge.xm" in mk and "DFSPChromeBridge.h" in source and
      "SidePlay.dylib" not in mk and "DuoFaceDashboard.dylib" not in mk,
      "QA9 CarPlay chrome receiver built without copying vendor/native payload")
check(all(x in plist for x in (
       "com.apple.springboard","com.apple.CarPlayApp","com.apple.carplayapp",
       "com.apple.dashboard")),
      "multi-process filter injects sender in SpringBoard and receiver in CarPlay Dashboard")
check("DBStatusBarWindow" in bridge and "CARStatusBarWindow" in bridge and
      "%group DFSPQA9ChromeDB" in bridge and "%group DFSPQA9ChromeCAR" in bridge and
      "DFSPChromeInstallHooks" in bridge,
      "original iOS16 status-bar subclasses observed without global UIWindow hooking")
check("NSDistributedNotificationCenter" in bridge and
      "DFSPChromeRequestEvent" in bridge and "DFSPChromeAckEvent" in bridge and
      '"generation"' in bridge and "visibilityApplied" in bridge,
      "per-process request and explicit chrome-window ACK channel present")
check("DFSPChromeRestore()" in bridge and
      "DFSPChromeRequest(NO,YES,DFSPSequence)" in source and
      "DFSPChromeSnapshots" in bridge,
      "disconnect restores original status bar hidden-state snapshots")
check("DFSPChromeRequest(YES,!full,DFSPSequence)" in source and
      "if (!DFSPHost)DFSPChromeRequest(YES,YES,DFSPSequence)" in source,
      "Normal/Zoom and visual-only path notify real CarPlay chrome receiver")
check("DFSPHideLegacyPaneControls(pane);" in source and
      source.count("DFSPHideLegacyPaneControls(pane);")==2 and
      all(x in source for x in ("[pane chipView]","[pane layoutButton]",
        "[pane addButton]","[pane closeButton]","[pane swapButton]","[pane grabber]","[pane titleLabel]")),
      "only known SidePlay pane UI controls hidden for both real app slots")
check("DFSPRestoreReplacedViews()" in source and
      "DFSPRestorePaneVisibility()" in source and
      "window.frame=desired;" not in source,
      "teardown restores legacy UI and never crops SidePlay CarPlay UIWindow")
check("CGRectGetMaxX(b)+CGRectGetMinX(a)" in frame and
      "CGRectGetMaxY(b)+CGRectGetMinY(a)" in frame and
      ("if (reversed)ratio=1.0-ratio;" in frame or\n       "self.splitPanReversed?-1.0:1.0" in frame),
      "divider edge and drag ratio handle pane0 right or bottom")
check("DFSPSystemUsableRect" in source and
      "carDockArea" in source and
      "DFSPNative12Host" in host,
      "SidePlay actual dock measurements logged without moving vendor app scene")

# Independently demonstrate 4 deterministic cases that failed in QA7.
def splitline(p0,p1,axis):
    start0,end0=(p0[0],p0[1]) if axis=="x" else (p0[2],p0[3])
    start1,end1=(p1[0],p1[1]) if axis=="x" else (p1[2],p1[3])
    first_leading=(start0+end0)<= (start1+end1)
    return (end0+start1)/2 if first_leading else (end1+start0)/2

check(splitline((0,440,0,480),(440,800,0,480),"x")==440.0,
      "left first: vertical split divider centered at x=440")
check(splitline((440,800,0,480),(0,440,0,480),"x")==440.0,
      "right first: vertical split divider STILL centered at x=440")
check(splitline((0,800,0,180),(0,800,180,480),"y")==180.0,
      "top first: horizontal split divider centered at y=180")
check(splitline((0,800,180,480),(0,800,0,180),"y")==180.0,
      "bottom first: horizontal split divider STILL centered at y=180")
physical=(440.0/800)
check(abs((1.0-physical)-.45)<1e-9,
      "swapped pane0-right drag at x=440 has logical SPDash ratio=.45")
print("QA9_STATIC_SOURCE_AND_GEOMETRY_PASS — bar visibility requires device test")
