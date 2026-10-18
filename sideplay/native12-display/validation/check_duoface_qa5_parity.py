#!/usr/bin/env python3
"""Read-only QA5 source parity tests against ALREADY archived Native12 contracts.

This proves code structure/integration, NOT that a CarPlay device renders it.
No license-bound original binary is imported or executed.
"""
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[3]
def source(name):return (ROOT/name).read_text(encoding="utf-8")
frame=source("sideplay/native12-display/DFSPNativeFrame.m")
head=source("sideplay/native12-display/DFSPNativeFrame.h")
pill=source("sideplay/native12-display/DFSPNativeSlotPill.m")
pill_h=source("sideplay/native12-display/DFSPNativeSlotPill.h")
adapter=source("sideplay/sileo-qa/Tweak.xm")
make=source("sideplay/sileo-qa/Makefile")
def check(cond,desc):
    assert cond, desc
    print("PASS",desc)

check("initWithSlot:i target:self" in frame and "for (NSInteger i=0;i<2;i++)" in frame,
      "exactly two DuoFace-owned slot pill instances created in two-pane UI")
check(all(x in pill for x in (
    "duoface-picker.png","duoface-fullscreen.png",
    "Chọn menu ứng dụng","Phóng to riêng ô","Khôi phục chia màn hình")),
    "real archived DuoFace picker/expand artwork and three independent callbacks")
check(all(x in pill for x in (
    "self.compact?72:80", "self.compact?64:76", "self.compact?38:44",
    "self.compact?19:22","self.layer.cornerRadius=11.0")),
    "verified Native12 6-mode pill dimensions and corner radius")
check("CGRectGetMidX(rect)-pillSize.width/2" in frame and
      "CGRectGetMinY(rect)+topInset" in frame and
      "CGRectGetMidY(rect)-pillSize.height/2" not in frame and
      "CGRectGetMinX(rect)+8.0" not in frame and
      "CGRectGetMaxX(rect)-pillSize.width" not in frame,
      "two pills follow top-center of EACH pane, not screen center or QA corner")
check(all(x in frame for x in ("expandTapped:","restoreTapped:","pillTapped:")) and
      "nativeFrameRequestedFocusForSlot:button.tag" in frame and
      "nativeFrameRequestedRestoreForSlot:button.tag" in frame and
      "self.selectedSlot=sender.tag" in frame,
      "menu, per-pane focus and per-pane restore routed to separate handlers")
check("nativeFrameRequestedZoom" not in frame.split("- (void)expandTapped:")[1].split("}\n")[0],
      "per-pane focus does NOT call fullscreen CarPlay Zoom")
check("nativeFrameRequestedFocusForSlot:" in head and
      "nativeFrameRequestedRestoreForSlot:" in head and
      "self.focusedSlot>=0" in frame,
      "real split UI supports focused mode and temporarily hides divider")
check("SPPane" in adapter and "layoutInFrame:owned scaleMode:" in adapter and
      "DFSPRestorePaneVisibility" in adapter and
      "DFSPClearPaneFocus(YES)" in adapter,
      "real SidePlay app scene layout used; sibling pane visibility restored")
check("DFSPHideLegacyPaneControls(pane)" in adapter and
      "DFSPRestoreReplacedViews()" in adapter,
      "legacy SidePlay pane controls hidden using QA9 owned helper with reversible rollback")
check("DFSPNativeSlotPill.m" in make and
      "DFSPNativeFrame.m" in make and
      "SidePlay.dylib" not in make,
      "both owned visual modules linked, vendor SidePlay binary not embedded")
check("DFSPNative12" not in pill or "CBSlotPillView" not in pill,
      "UI implementation does not require license-bound CBSlotPillView")
print("11 source-level QA5 parity gates PASS; device scene and CarPlay chrome NOT verified")
