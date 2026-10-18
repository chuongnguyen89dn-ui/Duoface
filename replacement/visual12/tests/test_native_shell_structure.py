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
assert 'restoreAction:@selector(restorePane:)' in ui
assert 'restoreAction:(SEL)restoreAction' in src
assert '@"VisualAssets/duoface-fullscreen.png",@"restore",target,restoreAction' in src
assert '- (void)restorePane:(UIButton *)button {' in ui
assert 'self.maximized=-1;' in ui and 'DFIPerfMark(@"pane_restore"' in ui
assert 'initWithIndex:i target:self action:@selector(drag:)' in ui
assert 'tapAction:@selector(swapPanes)' in ui
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
assert '#include "DFINativePickerCards.inc"' in ui
assert '@interface DFV12List' not in ui, "Legacy QA UITableView picker must not remain"
assert 'DFINativePickerCardsController *list' in ui
assert 'DFINativePickerCardsController *list=[DFINativePickerCardsController new]' in ui
cards=(root/"replacement/visual12/engine/runtime/DFINativePickerCards.inc").read_text()
assert 'DFINativePickerCardsController : UIViewController <UIScrollViewDelegate>' in cards
assert 'duoface.native.picker.app-cards' in cards
assert 'pickerCardTapped:' in cards and 'recentActionTapped:' in cards
assert 'UIControl *card=' in cards
assert 'cardWidth' in cards and 'card.layer.cornerRadius' in cards
# Original DuoNavi 1.0.4 evidence: selector trace a35cc includes
# gridCols/gridRows/hideIconLabels, setPagingEnabled, UIPageControl,
# setNumberOfPages, setCurrentPage, and horizontal contentSize.
assert 'UIPageControl *_pageControl;' in cards
assert '[_pageControl addTarget:self action:@selector(pageControlChanged:)' in cards
assert '_scrollView.pagingEnabled=!recent;' in cards
assert '_scrollView.alwaysBounceHorizontal=!recent && pageCount>1;' in cards
assert '_pageControl.numberOfPages=recent?0:pageCount;' in cards
assert 'CGSizeMake(pageCount*width,scrollHeight)' in cards
assert 'nativeGridCols' in cards and 'value>=4 && value<=6?value:4' in cards
assert 'nativeGridRows' in cards and 'value==2 || value==3?value:2' in cards
assert 'nativeHideIconLabels' in cards
assert 'scrollViewDidEndDecelerating:' in cards
assert 'duoface.native.picker.pages' in cards
assert 'DFIApprovedLiveGreen()' in cards and 'DFIApprovedRed()' in cards

assert 'DFINativePickerCardsController' in (root/"replacement/visual12/verify_full_ui_parity.py").read_text()
assert 'const CGFloat desiredTab[4]={43.0,51.0,47.0,51.0};' in ui
assert 'const CGFloat desiredTotal=192.0;' in ui
assert 'closeReserved=48.0' in ui
assert 'nativeMenuHeight=30.0' in ui
# iOS16 UIButtonConfiguration does not reliably honor titleEdgeInsets.
approved=(root/"replacement/visual12/engine/runtime/DFIApprovedVisuals.h").read_text()
assert 'caption.frame=CGRectMake(0,18,CGRectGetWidth(button.bounds),12);' in approved
assert 'caption.font=[UIFont systemFontOfSize:10];' in approved
assert 'button.configuration=nil;' in approved
assert 'button.titleEdgeInsets=' not in approved


# Approved native v12 divider semantics: swap on tap, move logo only after
# 0.30s hold and preserve split ratio on pane focus/restore.
assert 'tapAction:@selector(swapPanes)' in ui
assert 'holdAction:@selector(moveDividerLogo:)' in ui
assert 'tapAction:@selector(menu)' not in ui
assert 'UILongPressGestureRecognizer *hold=' in src
assert 'hold.minimumPressDuration=0.30;' in src
assert 'hold.cancelsTouchesInView=YES;' in src
assert 'initWithTarget:target action:holdAction' in src
assert 'panAction:(SEL)panAction' not in src
assert '- (void)moveDividerLogo:(UILongPressGestureRecognizer *)recognizer' in ui
assert 'self.dividerLogoPositions[index]=@(DFIClamp(offset/length,.10,.90));' in ui
assert 'DFIWritePreference(@"dividerLogoPositions"' in ui
assert 'self.maximized=-1;[self saveLayout];[self.view setNeedsLayout];' in ui
assert 'self.maximized=-1;self.fraction=self.layoutKind==4' not in ui
assert 'self.layer.cornerRadius=11.0;' in src, 'Original Native12 pill corner 11pt'
assert 'CGRectGetMaxX(frame)-78,CGRectGetMinY(frame)+3,76,22' in ui
assert '_dotsButton.frame=CGRectMake(4,0,30,22)' in src
assert '_expandButton.frame=CGRectMake(39,0,30,22)' in src
assert 'self.panePills[i].hidden=CGRectIsEmpty(frame)||frame.size.width<76||frame.size.height<22;' in ui
assert 'self.layer.cornerRadius=20.0;' in src
assert 'self.contentView.layer.borderWidth=0.0;' in src

print("DFINATIVE_UI_WINDOW_SPLIT_PILL_DIVIDER_PICKER_VIEW_TREE_STATIC_PASS")
print("DEVICE_SCREENSHOT_AND_CARPLAY_STATUS_BAR_NOT_YET_VERIFIED")
