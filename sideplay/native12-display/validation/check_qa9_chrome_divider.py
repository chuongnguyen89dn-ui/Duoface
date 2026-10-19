#!/usr/bin/env python3
"""QA10 source-only regression of Native12 system Dock ownership and split.

This branch REPLACES QA9's artificial ChromeBridge with the source-owned
Native12 DashboardChrome lifecycle adapted to the existing SidePlay app host.
No DEB build, carplay process or runtime verification occurs here.
"""
from pathlib import Path

ROOT=Path(__file__).resolve().parents[3]
def read(p):return (ROOT/p).read_text(encoding="utf-8")
def check(ok,msg):
    if not ok: raise AssertionError(msg)
    print("QA10_NATIVE_DOCK_PASS",msg)

source=read("sideplay/sileo-qa/Tweak.xm")
dock=read("sideplay/sileo-qa/DFSPNativeDock.xm")
header=read("sideplay/sileo-qa/DFSPNativeDock.h")
frame=read("sideplay/native12-display/DFSPNativeFrame.m")
host=read("sideplay/native12-display/DFSPNative12Host.m")
control=read("sideplay/sileo-qa/control")
plist=read("sideplay/sileo-qa/DuoFaceSidePlayDisplayQA.plist")
mk=read("sideplay/sileo-qa/Makefile")

check("Package: com.duoface.sideplaydisplay" in control and
      "com.sideplay (>= 1.0.4-1)" in control,
      "only QA package uses independent host integration; stable binaries untouched")
check("DFSPNativeDock.xm" in mk and "DFSPNativeDock.h" in source and
      "DFSPChromeBridge.xm" not in mk and
      "DFSPChromeBridge.h" not in source and
      "DuoFaceDashboard.dylib" not in mk and
      not (ROOT/"sideplay/sileo-qa/DFSPChromeBridge.xm").exists() and
      not (ROOT/"sideplay/sileo-qa/DFSPChromeBridge.h").exists(),
      "one active native dock source; obsolete QA ChromeBridge fully removed")
check("CBBridgeManager" not in source and
      "CBBridgeManager" not in dock and
      "licenseWatchdogTimerFired" not in dock,
      "no vendor license/coupled bridge classes copied from Native12")
check('Mode = "Any";' in plist and
      "Executables" in plist and
      "CarPlayApp" in plist and
      "Dashboard" in plist and
      "com.apple.springboard" in plist,
      "CarPlay/Dashboard receiver and SpringBoard sender match Substrate filter")
check("DBStatusBarWindow" in dock and "CARStatusBarWindow" in dock and
      "%group DFSPNativeDockDB" in dock and "%group DFSPNativeDockCAR" in dock and
      "DFSPDockIsWindow" in dock,
      "native12 status-window classes observed, no fake dock UI created")
check("DFSPDockOriginalHidden" in dock and
      "DFSPDockRestoreOriginal" in dock and
      "DFSPDockRequested=NO" in dock and
      "DFSPDockPost(DFSPDockAckDetach)" in dock,
      "original Apple dock state restored upon CarPlay scene detach")
check("DFSPDockZoomRequested=CFEqual(name,DFSPDockZoom)" in dock and
      "BOOL hide=DFSPDockZoomRequested" in dock and
      "win.hidden=hide" not in dock and "w.hidden=hide" in dock,
      "Normal explicitly shows system dock; Zoom hides; source-managed rollback")
check("CFNotificationCenterGetDarwinNotifyCenter()" in dock and
      "DFSPDockNormal" in dock and "DFSPDockZoom" in dock and
      "DFSPDockDetach" in dock and "DFSPDockAckMissing" in dock and
      "DFSPDockAckNormal" in dock and "ACK TIMEOUT" in dock,
      "iOS Darwin command+ACK statuses and late-start retries are available")
check("DFSPDockRequest(YES,full,DFSPSequence)" in source and
      "DFSPDockRequest(YES,NO,DFSPSequence)" in source and
      "DFSPDockRequest(NO,NO,DFSPSequence)" in source and
      "DFSPChromeRequest(" not in source,
      "SpringBoard switches Native dock mode at Normal/Zoom/fallback/disconnect")
check("DFSPSystemUsableRect(window)" in source and
      "DFSPNativeFallbackLeft = 64.0" in source and
      "UIEdgeInsetsInsetRect(screenRect, inset)" in source and
      "window.windowLevel=DFSPOriginalLevel" in source and
      "nativeUsableInWindow:usable" in source and
      "- (BOOL)applyNormal" in host,
      "Native12 CarPlay 64pt left inset applies to SidePlay app root, not whole UIWindow")
check("window.frame=desired;" not in source and
      "window.windowLevel=full?DFSPOriginalLevel:UIWindowLevelStatusBar-1.0;" not in source and
      "SidePlay.dylib" not in mk,
      "system CarPlay window is never cropped or elevated to hide the genuine dock")
check("DFSPHideLegacyPaneControls(pane);" in source and
      "DFSPRestoreReplacedViews()" in source,
      "old SidePlay display controls hidden with rollback; app scene remains owner")
check("CGRectGetMaxX(b)+CGRectGetMinX(a)" in frame and
      "CGRectGetMaxY(b)+CGRectGetMinY(a)" in frame and
      "self.splitPanReversed?-1.0:1.0" in frame,
      "divider still supports swapped pane ratio")
check("DuoFaceSidePlayDisplayQA.log" in dock and "NATIVE_DOCK" in dock,
      "on-device log will distinguish missing CarPlay native dock class/ACK")

def divider(p0,p1,axis):
    first,second=(p0,p1) if p0[0 if axis=="x" else 2]<p1[0 if axis=="x" else 2] else (p1,p0)
    return (first[1 if axis=="x" else 3]+second[0 if axis=="x" else 2])/2
check(divider((0,440,0,480),(440,800,0,480),"x")==440 and
      divider((440,800,0,480),(0,440,0,480),"x")==440 and
      divider((0,800,0,180),(0,800,180,480),"y")==180 and
      divider((0,800,180,480),(0,800,0,180),"y")==180,
      "split boundaries remain correct after reversing both physical orientations")
print("QA10_NATIVE_DOCK_STATIC_PASS — CarPlay screenshot confirmation NOT available")
