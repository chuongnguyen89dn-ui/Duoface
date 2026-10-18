#!/usr/bin/env python3
"""QA7 fail-soft compatibility: static gate, NOT CarPlay/device validation."""
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[3]
src=(ROOT/"sideplay/sileo-qa/Tweak.xm").read_text()
mk=(ROOT/"sideplay/sileo-qa/Makefile").read_text()
ctl=(ROOT/"sideplay/sileo-qa/control").read_text()
ui=(ROOT/"sideplay/native12-display/DFSPNativeFrame.m").read_text()
host=(ROOT/"sideplay/native12-display/DFSPNative12Host.m").read_text()
def must(flag,why):
    if not flag: raise AssertionError(why)
    print("PASS",why)
must("DFSPNative12Host.m" in mk, "Native12 content root code still linked")
must("0.1.7~native12chrome9" in ctl, "QA9 isolated package version")
must("QA9 injection and SPDash hooks installed" in src, "early injection has an observable startup marker")
must("QA7 owner-check attached=" in src and "rootTransform=" in src,
    "log distinguishes unsuitable root geometry/transform")
must("DFSPVisualCompatibility=(DFSPHost==nil);" in src,
    "invalid host enables a visual-only DuoFace fallback")
start=src.index("DFSPHost=[[DFSPNative12Host")
end=src.index("DFSPOriginalWindowBackground=window.backgroundColor;",start)
must("DFSPRemove()" not in src[start:end], "host refusal cannot silently remove DuoFace UI")
start=src.index('if (DFSPHost && !DFSPApply(NO,@"startup"))')
end=src.index("DFSPRefresh();",start)
must("DFSPRemove()" not in src[start:end] and
    "DFSPVisualCompatibility=YES;" in src[start:end] and
    "[DFSPHost restoreAndDetach];" in src[start:end],
    "Normal failure restores original root WITHOUT abandoning DuoFace shell")
must("if (DFSPHost) {" in src[start:end] or
    'window.opaque=NO;' in src[src.index("DFSPOriginalWindowBackground=window.backgroundColor;"):src.index("DFSPAdapter=[DFSPNativeAdapter new]")],
    "UIBackground rules are guarded by host geometry state")
must("if (!DFSPFull && DFSPHost)" in src,
    "reconnect does not retry an unverified visual-only host")
must("DFSPVisualCompatibility" in src and
    'QA7: Zoom blocked:' in src and
    "if (!window || !host || !host.isAttached" in src,
    "unsafe Zoom cannot trigger native fullscreen without verified host")
must("DFSPHideLegacyPaneControls(pane);" in src and
    "[pane chipView]" in src and "[pane layoutButton]" in src,
    "replaced SidePlay controls hidden using QA9 helper on live refresh")
must("DFSPUI=[[DFSPNativeFrame alloc]initWithFrame:window.bounds];" in src and
    "DFSPRefresh();" in src[end:],
    "DuoFace shell is created in both normal and compatible visual mode")
must("window.frame=desired;" not in src and "w.frame=target;" not in host,
    "root geometry never contracts UIWindow")
must("CGRectGetMidX(rect)-pillSize.width/2" in ui and
    "CGRectGetMinY(rect)+topInset" in ui,
    "Native12 pill top-centers each live pane")
print("QA9 SOURCE SAFETY PASS — chrome ACK code linked, device scenes and bar not yet tested")
