#!/usr/bin/env python3
"""QA11 regression against the on-car QA10 image and accepted QA7 drag path.

These are structural guards, NOT evidence that the CarPlay Dock appeared.
Run at repo root: python3 sideplay/native12-display/validation/check_qa11_device_regressions.py
"""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
def file(p):return (ROOT/p).read_text(encoding="utf-8")
frame=file("sideplay/native12-display/DFSPNativeFrame.m")
tweak=file("sideplay/sileo-qa/Tweak.xm")
dock=file("sideplay/sileo-qa/DFSPNativeDock.xm")
control=file("sideplay/sileo-qa/control")
def must(ok,description):
    if not ok:raise AssertionError(description)
    print("QA11_PASS",description)

must("UIPanGestureRecognizer *logoPan" in frame and
     "[logo addGestureRecognizer:logoPan];" in frame and
     "[logoPan requireGestureRecognizerToFail:hold];" in frame and
     "action:@selector(dragDivider:)" in frame,
     "QA7 working logo direct-pan path restored, not only transparent track")
must("[logo addGestureRecognizer:hold];" in frame and
     "hold.minimumPressDuration=0.30;" in frame and
     "action:@selector(moveLogo:)" in frame,
     "logo relocation held for 0.30s stays separate from split-ratio drag")
must("self.splitPanInitialTouch=[pan locationInView:self]" in frame and
     "self.splitPanInitialUnion=whole;" in frame and
     "self.splitPanReversed" in frame and
     "fabs(ratio-self.splitPanLastRatio)>=0.003" in frame,
     "split ratio uses frozen gesture origin and swapped-pane orientation")
must("DFSPHideLegacyPaneControls(pane);" in tweak and
     "[pane grabber]" in tweak,
     "SidePlay original grabber replaced ONLY when DuoFace logo pan exists")
must("DFSPOldPaneBarsSuppressed=YES;" in tweak and
     "DFSPOldPaneBarsSuppressed=NO;" in tweak and
     "DFSPRestoreLegacyPaneBars();" in tweak and
     "static BOOL DFSPOwnedPane" in tweak,
     "SidePlay old navigation bar suppression owns lifecycle and is reversible")
must("%hook SPPane" in tweak and
     "- (void)setBarHidden:(BOOL)hidden" in tweak and
     "- (void)slideBarHidden:(BOOL)hidden" in tweak and
     "if (DFSPOwnedPane(self))hidden=YES;" in tweak,
     "old per-pane navigation bar cannot reappear after delayed SidePlay layout")
must("DFSPSetSidePlayModal(YES" in tweak and
     "if (DFSPLegacyModalOpen) {" in tweak and
     "DFSPUI.userInteractionEnabled=NO;" in tweak and
     "DFSPMaybeResumeAfterSidePlayModal" in tweak,
     "SidePlay picker owns presentation while DuoFace controls remain hidden")
must("BOOL hide=DFSPDockZoomRequested?YES:original.boolValue;" in dock and
     "if (DFSPDockRequested && DFSPDockZoomRequested && !DFSPDockApplying)" in dock,
     "only Zoom hides system chrome; Normal RESTORES original, never forces new bar")
must("CarPlay process=%@" in dock and
     "scene windows=%@" in dock and "appDockVC not verified" in dock,
     "real CarPlay process/window inventory logged to diagnose missing app Dock")
must("DFSPNativeDockUsableBounds(window)" in tweak and
     "DFSPNativeFallbackLeft" not in tweak and
     "window.windowLevel=DFSPOriginalLevel;" in tweak,
     "single Native12-style dock usable-bounds owner with unchanged host window level")
must("0.1.8~native12dock10" in control,
     "no accidental production release/version bump before QA11 build approval")
print("QA11_STATIC_REGRESSION_PASS — APPLE CARPLAY DOCK NOT VISUALLY VERIFIED")
