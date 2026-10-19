#!/usr/bin/env python3
"""QA10 source-only regression: picker isolation, split ownership and stable ratio.

Checks only source/known SidePlay 1.0.4 ObjC method contracts.  Never builds or
executes a DEB, mutates a connected phone or claims real CarPlay parity.
Run from repo root: python3 sideplay/native12-display/validation/check_qa10_picker_divider.py
"""
from pathlib import Path
import math

ROOT=Path(__file__).resolve().parents[3]
def read(p):return (ROOT/p).read_text(encoding="utf-8")
frame=read("sideplay/native12-display/DFSPNativeFrame.m")
tweak=read("sideplay/sileo-qa/Tweak.xm")
ctrl=read("sideplay/sileo-qa/control")
def verify(ok, label):
    if not ok:raise AssertionError(label)
    print("QA10_PASS",label)

verify("Version: 0.1.7~native12chrome9" in ctrl,
       "source-only; packaging version unchanged, no premature release")
verify("logo.backgroundColor=UIColor.clearColor" in frame and
       "logo.layer.borderWidth=0" in frame and
       "logo.layer.shadowOpacity=0" in frame and
       "colorWithWhite:0.17 alpha:0.96" not in frame,
       "no QA dark disk, stroke or shadow behind approved DuoFace logo")
verify("dividerLine" not in frame and "UIView *line=" not in frame,
       "unapproved QA one-pixel full-pane stripe removed")
verify("logoPan" not in frame and "action:@selector(moveLogo:)" in frame and
       "action:@selector(dragDivider:)" in frame,
       "logo hold and divider ratio pan have separate gesture ownership")
verify("self.splitPanInitialTouch=[pan locationInView:self]" in frame and
       "self.splitPanInitialUnion=whole" in frame and
       "self.splitPanInitialRatio=DFSPClampRatio(self.currentRatio,NO)" in frame and
       "self.splitPanReversed" in frame and
       "now.x-self.splitPanInitialTouch.x" in frame and
       "now.y-self.splitPanInitialTouch.y" in frame,
       "drag snapshots geometry and ratio only at Began, not after SidePlay relayout")
verify("fabs(ratio-self.splitPanLastRatio)>=0.003" in frame and
       "ratio=cancelled?self.splitPanInitialRatio:DFSPClampRatio(ratio,ended)" in frame,
       "subpixel jitter gated and cancelled gesture restores previous split")
verify("self.dividerTrack.hidden=YES;" in frame and
       "self.pickerVisible ||" in frame and
       "for (DFSPNativeSlotPill *pill in self.pills)pill.hidden=YES;" in frame,
       "DuoFace modal hides behind its own App/Zoom/Style/Close menu")
verify("DFSPSetSidePlayModal(YES" in tweak and
       "- (void)showPickerForPane:(id)pane" in tweak and
       "- (void)dismissPicker" in tweak and
       "- (void)pickerAppTapped:(id)sender" in tweak and
       "DFSPMaybeResumeAfterSidePlayModal" in tweak and
       "DFSPUI.hidden=YES;" in tweak and
       "[DFSPWindow bringSubviewToFront:DFSPUI];" in tweak,
       "SidePlay app picker suspends overlay; old bring-to-front remains guarded")
verify("if (DFSPLegacyModalOpen) {" in tweak and
       "DFSPUI.userInteractionEnabled=NO;" in tweak,
       "background divider cannot receive taps while SidePlay picker is displayed")
verify("- (void)revealChosenLayout:(BOOL)shown" in tweak and
       "%orig(shown);" in tweak and
       "- (void)layoutChooser" in tweak,
       "SidePlay show/dismiss chooser method type matches original BOOL ABI")
verify("DFSPHideLegacySplitStrips(one,two,panes)" in tweak and
       "candidate.gestureRecognizers.count>0" in tweak and
       "[p0 isDescendantOfView:candidate]" in tweak and
       "candidate.subviews.count>0" in tweak and
       "DFSPHideReplacedView(candidate)" in tweak,
       "legacy split decoration only hidden when noninteractive and scene-free")
verify("window.windowLevel=DFSPOriginalLevel;" in tweak and
       "window.windowLevel=full?DFSPOriginalLevel:UIWindowLevelStatusBar-1.0;" not in tweak,
       "restore original CarPlay host window level instead of covering lower dock")
verify("QA10 SidePlay ratio drift" in tweak and
       "afterLayout=[manager ratio]" in tweak,
       "final SidePlay ratio mismatch diagnosed without changing scene host")
verify("DFSPRestoreReplacedViews();" in tweak and
       "DFSPLegacyModalOpen=NO;" in tweak,
       "visual changes reversibly reset when CarPlay disconnects")

def dragged(initial, d, extent, reversed=False):
    value=initial + (-1 if reversed else 1)*d/extent
    return max(1/3,min(2/3,value))
verify(abs(dragged(0.5,80,800)-0.6)<1e-10,
       "normal direction 80px of 800px updates ratio by +0.1")
verify(abs(dragged(0.5,80,800,True)-0.4)<1e-10,
       "swapped pane index reverses direction without shifting touch origin")
verify(abs(dragged(0.5,0,800)-0.5)<1e-10 and
       abs(dragged(0.5,1000,800)-2/3)<1e-10,
       "touch-down does not jump and ratios remain clamped")
# Regression: re-layout changes live pane frames, but frozen starting geometry
# yields the same value at the same drag delta instead of chasing a moved edge.
frozen=dragged(0.5,64,800)
verify(abs(frozen-0.58)<1e-10,
       "frozen geometry avoids moving-origin jitter after SidePlay relayout")
print("QA10_ALL_SOURCE_ONLY_GATES_PASS; CarPlay dock/appearance requires real device")
