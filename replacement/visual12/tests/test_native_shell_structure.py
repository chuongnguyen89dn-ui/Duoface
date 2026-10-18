#!/usr/bin/env python3
"""Native12 UI shell structural gate. Static source test, not device approval."""
from pathlib import Path
root=Path(__file__).resolve().parents[3]
src=(root/"replacement/visual12/engine/runtime/DFINativeShell.inc").read_text()
ui=(root/"replacement/visual12/engine/runtime/DFIInterface.inc").read_text()
runtime=(root/"replacement/visual12/engine/runtime/DFIRuntime.m").read_text()
refs=(root/"runtime/fullscreen/DFPickerZoomMenu.xm").read_text()
hook=(root/"src/DuoFaceVisualHook.m").read_text()
classes=("DFINativeWindowSurface","DFINativeSplitSurface","DFINativeSlotPillView",
         "DFINativeDividerTrack","DFINativeDividerLogo","DFINativePickerCard",
         "DFINativePickerMenuBar")
for name in classes:
    assert f"@interface {name}" in src, name
    assert f"@implementation {name}" in src, name
assert '#include "DFINativeShell.inc"' in ui
assert 'self.view=[[DFINativeWindowSurface alloc]initWithFrame:' in ui
assert 'self.nativeSplitSurface=((DFINativeWindowSurface *)self.view).splitSurface;' in ui
assert '[self.nativeSplitSurface addSubview:p]' in ui
assert '[self.nativeSplitSurface addSubview:pill]' in ui
assert '[self.nativeSplitSurface addSubview:track]' in ui
assert '[self.nativeSplitSurface addSubview:logo]' in ui
assert '[self.nativeSplitSurface bringSubviewToFront:self.lines[i]]' in ui
assert '[self.nativeSplitSurface bringSubviewToFront:pill]' in ui
assert 'initWithSlot:i target:self pickAction:@selector(choose:)' in ui
assert 'focusAction:@selector(zoomPane:)' in ui
assert 'initWithIndex:i target:self action:@selector(drag:)' in ui
assert '@selector(menu)' in ui
assert 'self.toolbar=[[DFINativePickerMenuBar alloc]initWithFrame:' in ui
assert 'DFINativePickerCard *card=' in ui
assert 'self.pickerShade=shade' in ui
assert '[self.pickerShade removeFromSuperview];self.pickerShade=nil;' in ui
for native_control in ('_dotsButton','_expandButton','_restoreButton'):
    assert native_control in hook
for control in ('_appSegmentBtn','_layoutSegmentBtn','_recentSegmentBtn',
                '_sheetCard','menuHeight=30.0','logoWidth=120.0'):
    assert control in refs, control
assert 'duoface-logo-picker-alpha-v2.png' in (root/"replacement/visual12/engine/runtime/DFIApprovedVisuals.h").read_text()
assert 'VisualAssets/duoface-picker.png' in src
assert 'VisualAssets/duoface-fullscreen.png' in src
assert 'VisualAssets/duoface-swap.png' in src
assert 'CGRectGetMidX(windowBounds)' in src
assert 'DFINativePickerCardFrame(splitFrame,' in ui
for forbidden in ('@implementation CBBridgeManager','@implementation CBLicenseSyncManager',
                  'licenseWatchdogTimerFired','DuoNaviDashboard.dylib'):
    assert forbidden not in src, forbidden
assert 'DFV12SceneHost' in runtime
assert 'DFCBUnbindHost(DFIWindow)' in runtime
assert 'DFIWindow=window' in runtime
assert "UIWindowLevelAlert+100" in runtime, "Actual window level still requires receiver stack verification"
# Original DuoNavi 1.0.4 carPlayContentInsets fallback is precisely
# (top=0,left=64,bottom=0,right=0), verified by ARM64 fmov d9,#64.
assert "UIEdgeInsetsMake(0,64,0,0)" in src
assert "self.window.safeAreaInsets" in src
assert "CGRectGetWidth(r)<100" in src and "CGRectGetHeight(r)<100" in src
assert "if(!CGRectContainsPoint(_splitSurface.frame,point))return nil;" in src
assert "window.backgroundColor=UIColor.clearColor;" in runtime
assert "window.opaque=NO;" in runtime
assert 'if(DFIChromeZoomRequested())' in runtime
assert 'DFIChromeSetZoom(NO);' in runtime
chrome=(root/"replacement/visual12/engine/runtime/DFIChrome.inc").read_text()
for cls in ("DBStatusBarWindow","CARStatusBarWindow","DBDockWindow"):
    assert cls in chrome
assert 'window.hidden=YES' in chrome
assert 'DFIChromeRestore' in chrome
assert "CGRect splitFrame=[(DFINativeWindowSurface *)self.view usableContentFrame];" in ui
assert "self.nativeSplitSurface.frame=splitFrame;" in ui
assert "[g locationInView:self.nativeSplitSurface]" in ui
assert "DFINativePickerCardFrame(splitFrame," in ui
print("DFINATIVE_UI_WINDOW_SPLIT_PILL_DIVIDER_PICKER_VIEW_TREE_STATIC_PASS")
print("DEVICE_SCREENSHOT_AND_CARPLAY_STATUS_BAR_NOT_YET_VERIFIED")
