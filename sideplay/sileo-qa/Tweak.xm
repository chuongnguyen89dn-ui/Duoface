// Independent DuoFace Native12 frame QA3 on SidePlay's existing CarPlay app host.
// Suppress SidePlay's old display/chip UI, preserve live app-scenes and use
// Native12 pill, picker, divider and gestures wired to real SPDash selectors.
// Reversible: no changes to SidePlay.dylib, Native12 HUD8 or on-disk prefs.
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <math.h>
#import "../native12-display/DFSPNativeFrame.h"
#import "../native12-display/DFSPNative12Host.h"
#import "DFSPChromeBridge.h"

@interface SPDash : NSObject
- (void)setCarWindow:(UIWindow *)window;
- (void)setCarWindowFrame:(CGRect)frame;
- (CGRect)carWindowFrameNow;
- (BOOL)carDockMode;
- (CGRect)carDockArea; // verified SPDash 1.0.4 ObjC ABI CGRect
- (void)layoutRootView;
- (void)layout:(BOOL)animated;
- (NSArray *)panes;
- (UIView *)rootView;
- (NSInteger)split;
- (double)ratio;
- (void)setRatio:(double)value;
- (void)showPickerForPane:(id)pane;
- (void)dismissPicker;
- (void)pickerAppTapped:(id)sender;
- (UIView *)pickerView;
- (BOOL)showingChooser;
- (void)layoutChooser;
- (void)revealChosenLayout:(id)selection;
- (void)paneRequestsClose:(id)pane;
- (void)paneRequestsSwap:(id)pane;
@end

@interface SPPane : NSObject
- (UIView *)view;
- (UIView *)chipView;
- (UIView *)layoutButton;
- (UIView *)addButton;
- (UIView *)closeButton;
- (UIView *)swapButton;
- (UIView *)grabber;
- (UIView *)titleLabel;
- (id)appViewController;
- (NSInteger)scaleMode;
- (void)layoutInFrame:(CGRect)frame scaleMode:(NSInteger)mode;
@end

static __weak UIWindow *DFSPWindow;
static __weak SPDash *DFSPManager;
static DFSPNativeFrame *DFSPUI;
static DFSPNative12Host *DFSPHost;
// The validated root geometry can be unavailable on some CarPlay scene variants.
// Keep the DuoFace-owned UI visible without altering the vendor app scene.
static BOOL DFSPVisualCompatibility=NO;
static id<DFSPNativeFrameDelegate> DFSPAdapter;
static BOOL DFSPRefreshing=NO;
// A SidePlay-owned picker/Style modal must own the frontmost touch surface.
static BOOL DFSPLegacyModalOpen=NO;
static NSUInteger DFSPLegacyModalEpoch=0;
static BOOL DFSPUpdatingRatio=NO;
static BOOL DFSPApplyingPaneFocus=NO;
static NSInteger DFSPFocusedSlot=-1;
static NSMapTable<UIView *, NSNumber *> *DFSPFocusedHiddenViews;
static void DFSPRefresh(void);
static CGFloat DFSPOriginalLevel;
static CGRect DFSPOriginalFrame;
static BOOL DFSPFull = NO;
static BOOL DFSPApplying = NO;
static NSUInteger DFSPSequence = 0;
static NSUInteger DFSPLayoutCalls = 0;
// Only visual elements replaced by the approved Native12 shell are hidden.
// Weak keys avoid retaining a disposed SidePlay pane/scene across reconnect.
static NSMapTable<UIView *, NSNumber *> *DFSPHiddenOriginalViews;
static void DFSPHideReplacedView(UIView *view) {
    if (!view || !DFSPUI || !DFSPWindow) return;
    if (!DFSPHiddenOriginalViews)
        DFSPHiddenOriginalViews=[NSMapTable weakToStrongObjectsMapTable];
    if (![DFSPHiddenOriginalViews objectForKey:view])
        [DFSPHiddenOriginalViews setObject:@(view.hidden) forKey:view];
    // Deliberately not changing pane.view, contentView, canvasView or scenes.
    view.hidden=YES;
}
static void DFSPRestoreReplacedViews(void) {
    NSEnumerator<UIView *> *keys=[DFSPHiddenOriginalViews keyEnumerator];
    UIView *view=nil;
    NSUInteger restored=0;
    while ((view=[keys nextObject])) {
        NSNumber *prior=[DFSPHiddenOriginalViews objectForKey:view];
        if (prior) {
            view.hidden=prior.boolValue;
            ++restored;
        }
    }
    [DFSPHiddenOriginalViews removeAllObjects];
    DFSPHiddenOriginalViews=nil;
    if (restored)
        NSLog(@"[DuoFaceSidePlayDisplayQA] Restored %lu old SidePlay UI items",
              (unsigned long)restored);
}
static const CGFloat DFSPNativeFallbackLeft = 64.0;
static UIColor *DFSPOriginalWindowBackground;
static BOOL DFSPOriginalWindowOpaque=YES;
static BOOL DFSPHasOriginalWindowBackground=NO;

static void DFSPLog(NSString *message) {
    NSLog(@"[DuoFaceSidePlayDisplayQA2] %@", message);
    @try {
        NSString *directory = @"/var/mobile/Library/Logs";
        [[NSFileManager defaultManager] createDirectoryAtPath:directory
                    withIntermediateDirectories:YES attributes:nil error:nil];
        NSString *path = [directory stringByAppendingPathComponent:@"DuoFaceSidePlayDisplayQA.log"];
        NSString *line = [NSString stringWithFormat:@"%@ QA2 %@\n", [NSDate date], message];
        NSData *data = [line dataUsingEncoding:NSUTF8StringEncoding];
        if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [data writeToFile:path atomically:YES];
        } else {
            NSFileHandle *output = [NSFileHandle fileHandleForWritingAtPath:path];
            if (output) {
                [output seekToEndOfFile];
                [output writeData:data];
                [output closeFile];
            }
        }
    } @catch (NSException *ignored) { (void)ignored; }
}

// This only coordinates view visibility; SidePlay remains responsible for
// creating/dismissing its own picker and hosted app scenes.
static void DFSPSetSidePlayModal(BOOL visible, NSString *reason) {
    if (DFSPLegacyModalOpen==visible &&
        (!DFSPUI || DFSPUI.hidden==visible))return;
    DFSPLegacyModalOpen=visible;
    ++DFSPLegacyModalEpoch;
    if (DFSPUI) {
        DFSPUI.hidden=visible;
        DFSPUI.userInteractionEnabled=!visible;
    }
    DFSPLog([NSString stringWithFormat:@"QA10 SidePlay modal=%d cause=%@; DuoFace overlay %@",
             visible,reason,visible?@"suspended":@"restored"]);
    if (!visible)DFSPRefresh();
}
static BOOL DFSPPickerViewStillPresented(SPDash *owner) {
    UIView *panel=owner?[owner pickerView]:nil;
    if (!panel || panel.hidden || panel.alpha<=0.01 || !panel.window ||
        panel.window!=DFSPWindow)return NO;
    CGRect inWindow=[panel convertRect:panel.bounds toView:DFSPWindow];
    CGRect inter=CGRectIntersection(inWindow,DFSPWindow.bounds);
    return !CGRectIsNull(inter) && !CGRectIsEmpty(inter) &&
           CGRectGetWidth(inter)>80 && CGRectGetHeight(inter)>60;
}
static void DFSPMaybeResumeAfterSidePlayModal(SPDash *owner,
                                              NSString *reason,
                                              NSUInteger retries) {
    if (!owner || owner!=DFSPManager || !DFSPLegacyModalOpen)return;
    BOOL active=[owner showingChooser] || DFSPPickerViewStillPresented(owner);
    if (!active) {
        DFSPSetSidePlayModal(NO,reason);
        return;
    }
    // UIKit dismissal may animate; never resurrect controls on top of
    // a live SidePlay picker. The next layout also checks this state.
    if (retries<12) {
        __weak SPDash *weakOwner=owner;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,150000000),
                       dispatch_get_main_queue(),^{
            DFSPMaybeResumeAfterSidePlayModal(weakOwner,reason,retries+1);
        });
    } else DFSPLog(@"QA10 modal still owned by SidePlay; kept overlay suspended");
}
static BOOL DFSPRectOK(CGRect rect) {
    return isfinite(rect.origin.x) && isfinite(rect.origin.y) &&
           isfinite(rect.size.width) && isfinite(rect.size.height) &&
           rect.size.width > 100.0 && rect.size.height > 100.0;
}
static BOOL DFSPExternal(UIWindow *window) {
    UIScreen *screen = window.screen;
    return screen && screen != UIScreen.mainScreen;
}
static CGRect DFSPSystemUsableRect(UIWindow *window) {
    if (!window || !DFSPExternal(window)) return CGRectNull;
    // Work in WINDOW-LOCAL coordinates, not UIScreen coordinates.
    CGRect screenRect=window.bounds;
    if (!DFSPRectOK(screenRect)) return CGRectNull;
    UIEdgeInsets inset = window.safeAreaInsets;
    BOOL usableInsets = isfinite(inset.top) && isfinite(inset.left) &&
                        isfinite(inset.bottom) && isfinite(inset.right) &&
                        inset.top>=0 && inset.left>=0 &&
                        inset.bottom>=0 && inset.right>=0 &&
                        (inset.top>0 || inset.left>0 ||
                         inset.bottom>0 || inset.right>0);
    if (!usableInsets) {
        // Native DuoNavi 1.0.4 +[CBWindow carPlayContentInsets]:
        // original arm64 at 0xb1544 loads d9 = 64.0 (left), others 0.
        // This is a SAFE fallback from the approved original's behavior,
        // not a SidePlay carDockArea or invented scale fraction.
        inset = UIEdgeInsetsMake(0, DFSPNativeFallbackLeft, 0, 0);
    }
    CGRect usable = UIEdgeInsetsInsetRect(screenRect, inset);
    if (!DFSPRectOK(usable) || !CGRectContainsRect(screenRect, usable))
        return CGRectNull;
    return usable;
}
// Never contract the system's CarPlay UIWindow: on-device QA5 proved
// window.frame mutation crops the scene and exposes Home behind it.
// A separate content-root owner keeps the window and native chrome distinct.
static BOOL DFSPApply(BOOL full, NSString *source) {
    UIWindow *window=DFSPWindow;
    DFSPNative12Host *host=DFSPHost;
    if (!window || !host || !host.isAttached ||
        !DFSPExternal(window) || DFSPApplying) {
        if (DFSPVisualCompatibility)
            DFSPLog(@"QA7: Zoom blocked: host/chrome not verified; native UI stays visible");
        return NO;
    }
    BOOL wasFull=DFSPFull;
    DFSPApplying=YES;
    BOOL applied=full?[host applyFullscreen]:[host applyNormal];
    if (applied) {
        DFSPFull=full;
        // Z-order alone cannot conjure the system bar; the window outside
        // the actual content root must also stay transparent.
        // QA9 raised a full-screen SidePlay UIWindow to statusbar-1,
        // which can cover a lower-level CarPlay dock even if it is unhidden.
        // Keep SidePlay's original z-order in both Normal and Zoom.
        window.windowLevel=DFSPOriginalLevel;
        [window setNeedsLayout];
        [window layoutIfNeeded];
        DFSPRefresh();
        // Notify the *actual* CarPlay/Dashboard process; root-only resizing
        // cannot make DBStatusBarWindow/CARStatusBarWindow reappear.
        DFSPChromeRequest(YES,!full,DFSPSequence);
    } else {
        if (wasFull) [host applyFullscreen]; else [host applyNormal];
    }
    DFSPApplying=NO;
    DFSPLog([NSString stringWithFormat:
      @"native host apply=%d zoom=%d source=%@ windowFrame=%@ windowBounds=%@ contentRoot=%@ usable=%@ level=%.1f safe=%@",
      applied,full,source,NSStringFromCGRect(window.frame),
      NSStringFromCGRect(window.bounds),
      NSStringFromCGRect([DFSPManager rootView].frame),
      NSStringFromCGRect(DFSPSystemUsableRect(window)),window.windowLevel,
      NSStringFromUIEdgeInsets(window.safeAreaInsets)]);
    return applied;
}
static NSArray *DFSPPanes(void) {
    SPDash *manager=DFSPManager;
    id array=manager?[manager panes]:nil;
    return [array isKindOfClass:[NSArray class]]?array:@[];
}
static void DFSPHideSidePlayPlaceholder(UIView *view,NSUInteger depth) {
    if (!view || depth>6)return;
    for (UIView *item in view.subviews) {
        NSString *text=nil;
        if ([item isKindOfClass:[UILabel class]])
            text=((UILabel *)item).text;
        else if ([item isKindOfClass:[UIButton class]])
            text=[((UIButton *)item) titleForState:UIControlStateNormal];
        NSString *lower=text.lowercaseString;
        if (lower.length && ([lower containsString:@"trống"] ||
                             [lower containsString:@"thêm app"] ||
                             [lower containsString:@"add app"] ||
                             [lower isEqualToString:@"empty"])) {
            DFSPHideReplacedView(item); // title-only SidePlay placeholder, not app scene.
        }
        DFSPHideSidePlayPlaceholder(item,depth+1);
    }
}
static void DFSPHideLegacyPaneControls(SPPane *pane) {
    if (!pane || !DFSPUI)return;
    // These property getter selectors are verified in SidePlay 1.0.4 arm64.
    // Hide only buttons/text replaced by DuoFace; NEVER pane.view,
    // appViewController, contentView, canvasView or scene lifecycle.
    for (UIView *candidate in @[[pane chipView]?:[NSNull null],
                                [pane layoutButton]?:[NSNull null],
                                [pane addButton]?:[NSNull null],
                                [pane closeButton]?:[NSNull null],
                                [pane swapButton]?:[NSNull null],
                                [pane grabber]?:[NSNull null],
                                [pane titleLabel]?:[NSNull null]]) {
        if ([candidate isKindOfClass:UIView.class])
            DFSPHideReplacedView(candidate);
    }
}
// SidePlay can leave a decorative 1-4pt strip between two SPPane views.
// Do NOT hide SPDash.rootView, scene owners, overlays or interactive controls.
// Only a plain, noninteractive, scene-free sibling at the actual shared edge
// qualifies; other SidePlay decoration stays until device hierarchy confirms.
static void DFSPHideLegacySplitStrips(CGRect one, CGRect two,
                                     NSArray *panes) {
    if (panes.count<2 || !DFSPUI || !DFSPManager ||
        !DFSPRectOK(one) || !DFSPRectOK(two))return;
    UIView *root=[DFSPManager rootView];
    UIView *p0=[panes[0] view],*p1=[panes[1] view];
    if (!root || !p0 || !p1 || root.window!=DFSPWindow)return;
    BOOL vertical=fabs(CGRectGetMidX(two)-CGRectGetMidX(one))>
                  fabs(CGRectGetMidY(two)-CGRectGetMidY(one));
    CGFloat split=vertical?
       (CGRectGetMidX(one)<CGRectGetMidX(two)?
        (CGRectGetMaxX(one)+CGRectGetMinX(two))*0.5:
        (CGRectGetMaxX(two)+CGRectGetMinX(one))*0.5):
       (CGRectGetMidY(one)<CGRectGetMidY(two)?
        (CGRectGetMaxY(one)+CGRectGetMinY(two))*0.5:
        (CGRectGetMaxY(two)+CGRectGetMinY(one))*0.5);
    for (UIView *candidate in root.subviews) {
        if (!candidate || candidate==p0 || candidate==p1 ||
            [candidate isKindOfClass:UIControl.class] ||
            [candidate isKindOfClass:UIScrollView.class] ||
            candidate.userInteractionEnabled || candidate.hidden ||
            [p0 isDescendantOfView:candidate] ||
            [p1 isDescendantOfView:candidate] ||
            candidate.subviews.count>0)continue;
        CGRect rect=[candidate convertRect:candidate.bounds toView:DFSPUI];
        CGFloat thickness=vertical?CGRectGetWidth(rect):CGRectGetHeight(rect);
        CGFloat span=vertical?CGRectGetHeight(rect):CGRectGetWidth(rect);
        CGFloat expected=vertical?
            MIN(CGRectGetHeight(one),CGRectGetHeight(two)):
            MIN(CGRectGetWidth(one),CGRectGetWidth(two));
        CGFloat center=vertical?CGRectGetMidX(rect):CGRectGetMidY(rect);
        if (isfinite(thickness) && thickness>0 && thickness<=4 &&
            span>=expected*0.65 && fabs(center-split)<=6) {
            DFSPHideReplacedView(candidate);
            DFSPLog([NSString stringWithFormat:
                @"QA10 hidden SidePlay decorative split strip class=%@ frame=%@",
                NSStringFromClass(candidate.class),NSStringFromCGRect(rect)]);
        }
    }
}
static CGRect DFSPPaneRect(SPPane *pane) {
    UIView *view=[pane view];
    if (!view || !view.superview || !DFSPUI || view.window!=DFSPWindow)
        return CGRectZero;
    return [view.superview convertRect:view.frame toView:DFSPUI];
}
// Focus/restore only ONE actual SidePlay-hosted SPPane. Split ratio is not
// changed; no CB binary is linked. Device resize/touch correctness is pending.
static void DFSPRestorePaneVisibility(void) {
    NSEnumerator *it=[DFSPFocusedHiddenViews keyEnumerator];
    UIView *v=nil;
    while ((v=[it nextObject])) {
        NSNumber *original=[DFSPFocusedHiddenViews objectForKey:v];
        if (original) v.hidden=original.boolValue;
    }
    [DFSPFocusedHiddenViews removeAllObjects];
    DFSPFocusedHiddenViews=nil;
}
static BOOL DFSPApplyPaneFocus(void) {
    if (DFSPFocusedSlot<0 || !DFSPWindow || !DFSPUI ||
        DFSPApplyingPaneFocus) return NO;
    NSArray *panes=DFSPPanes();
    if(panes.count<2 || DFSPFocusedSlot>1)return NO;
    SPPane *one=panes[0],*two=panes[1];
    UIView *v0=[one view],*v1=[two view];
    if(!v0 || !v1 || !v0.superview || !v1.superview ||
       v0.window!=DFSPWindow || v1.window!=DFSPWindow)return NO;
    // Geometry is the union of the REAL split panes, not window fullscreen.
    CGRect full=CGRectUnion(DFSPPaneRect(one),DFSPPaneRect(two));
    if (!DFSPRectOK(full))return NO;
    SPPane *active=panes[(NSUInteger)DFSPFocusedSlot];
    UIView *activeView=[active view];
    CGRect owned=[activeView.superview convertRect:full fromView:DFSPUI];
    if (!DFSPRectOK(owned))return NO;
    DFSPApplyingPaneFocus=YES;
    [active layoutInFrame:owned scaleMode:[active scaleMode]];
    if (!DFSPFocusedHiddenViews)
        DFSPFocusedHiddenViews=[NSMapTable weakToStrongObjectsMapTable];
    UIView *other=(DFSPFocusedSlot==0)?v1:v0;
    if(![DFSPFocusedHiddenViews objectForKey:other])
        [DFSPFocusedHiddenViews setObject:@(other.hidden) forKey:other];
    other.hidden=YES;
    DFSPUI.focusedSlot=DFSPFocusedSlot;
    DFSPApplyingPaneFocus=NO;
    return YES;
}
static void DFSPClearPaneFocus(BOOL updateLayout) {
    DFSPFocusedSlot=-1;
    DFSPUI.focusedSlot=-1;
    DFSPRestorePaneVisibility();
    if(updateLayout && DFSPManager && !DFSPApplyingPaneFocus)
        [DFSPManager layout:NO]; // host restores both real app scene frames
}
static void DFSPRefresh(void) {
    if (!DFSPUI || !DFSPManager || !DFSPWindow ||
        DFSPRefreshing || DFSPUpdatingRatio)return;
    DFSPRefreshing=YES;
    NSArray *panes=DFSPPanes();
    CGRect one=CGRectZero,two=CGRectZero;
    BOOL firstApp=NO,secondApp=NO;
    if(panes.count>0 && [panes[0] isKindOfClass:objc_getClass("SPPane")]) {
        SPPane *pane=panes[0];
        one=DFSPPaneRect(pane);
        firstApp=[pane appViewController]!=nil;
        DFSPHideLegacyPaneControls(pane);
        if(!firstApp) DFSPHideSidePlayPlaceholder([pane view],0);
    }
    if(panes.count>1 && [panes[1] isKindOfClass:objc_getClass("SPPane")]) {
        SPPane *pane=panes[1];
        two=DFSPPaneRect(pane);
        secondApp=[pane appViewController]!=nil;
        DFSPHideLegacyPaneControls(pane);
        if(!secondApp) DFSPHideSidePlayPlaceholder([pane view],0);
    }
    DFSPHideLegacySplitStrips(one,two,panes);
    // The SidePlay app picker/Style sheet is above the DuoFace scene chrome.
    // Never bring the DuoFace divider/logo over a genuine modal.
    if (DFSPLegacyModalOpen) {
        DFSPUI.hidden=YES;
        DFSPUI.userInteractionEnabled=NO;
        DFSPRefreshing=NO;
        return;
    }
    DFSPUI.focusedSlot=DFSPFocusedSlot;
    DFSPUI.frame=DFSPWindow.bounds;
    [DFSPUI updateFirst:one second:two
        hasFirstApp:firstApp hasSecondApp:secondApp
        ratio:[DFSPManager ratio] fullscreen:DFSPFull];
    [DFSPWindow bringSubviewToFront:DFSPUI];
    [DFSPUI setNeedsLayout];
    DFSPRefreshing=NO;
}
@interface DFSPNativeAdapter : NSObject <DFSPNativeFrameDelegate>
@end
@implementation DFSPNativeAdapter
- (void)nativeFrameRequestedFocusForSlot:(NSInteger)slot {
    if (slot<0 || slot>1 || !DFSPManager || DFSPFocusedSlot>=0)return;
    // Ensure host starts from a valid SidePlay two-pane scene/layout.
    DFSPFocusedSlot=slot;
    if (!DFSPApplyPaneFocus()) {
        DFSPClearPaneFocus(NO);
        DFSPLog(@"Native12 focus refused: invalid real pane geometry");
        return;
    }
    DFSPLog([NSString stringWithFormat:
            @"Native12 focus slot=%ld using real SPPane layoutInFrame:",(long)slot]);
    DFSPRefresh();
}
- (void)nativeFrameRequestedRestoreForSlot:(NSInteger)slot {
    if (slot!=DFSPFocusedSlot || !DFSPManager)return;
    DFSPClearPaneFocus(YES);
    DFSPRefresh();
    DFSPLog([NSString stringWithFormat:@"Native12 restore slot=%ld",(long)slot]);
}
- (void)nativeFrameRequestedAppForSlot:(NSInteger)slot {
    NSArray *panes=DFSPPanes();
    if(slot>=0 && slot<(NSInteger)panes.count) {
        [DFSPManager showPickerForPane:panes[(NSUInteger)slot]];
        DFSPLog([NSString stringWithFormat:
            @"Native12 App(%ld) -> SidePlay showPickerForPane:",(long)slot]);
    }
}
- (void)nativeFrameRequestedZoom {
    BOOL next=!DFSPFull;
    BOOL ok=DFSPApply(next,@"Native12 menu Zoom");
    DFSPLog([NSString stringWithFormat:@"Native12 Zoom %@ applied=%d",
             next?@"In":@"Out",ok]);
    DFSPRefresh();
}
- (void)nativeFrameRequestedStyle {
    [DFSPManager layoutChooser];
    DFSPLog(@"Native12 Style -> SidePlay layoutChooser (existing host)");
}
- (void)nativeFrameRequestedCloseForSlot:(NSInteger)slot {
    NSArray *panes=DFSPPanes();
    if(slot>=0 && slot<(NSInteger)panes.count) {
        [DFSPManager paneRequestsClose:panes[(NSUInteger)slot]];
        DFSPLog([NSString stringWithFormat:
            @"Native12 Close(%ld) -> paneRequestsClose:",(long)slot]);
    }
}
- (void)nativeFrameRequestedSwap {
    NSArray *panes=DFSPPanes();
    if(panes.count>=2) {
        [DFSPManager paneRequestsSwap:panes[0]];
        DFSPLog(@"Native12 divider tap -> SidePlay paneRequestsSwap:");
    }
}
- (void)nativeFrameDraggedToRatio:(double)ratio ended:(BOOL)ended {
    SPDash *manager=DFSPManager;
    if (!manager || !isfinite(ratio))return;
    DFSPUpdatingRatio=YES;
    // SPDash owns the real scene split: the QA divider only sends its
    // stable gesture delta. Never mutate the window or each SPPane frame.
    [manager setRatio:ratio];
    double accepted=[manager ratio];
    [manager layout:ended];
    double afterLayout=[manager ratio];
    DFSPUpdatingRatio=NO;
    if (ended && (fabs(afterLayout-ratio)>0.012 ||
                  fabs(accepted-ratio)>0.012))
        DFSPLog([NSString stringWithFormat:
            @"QA10 SidePlay ratio drift requested=%.5f accepted=%.5f afterLayout=%.5f split=%ld",
            ratio,accepted,afterLayout,(long)[manager split]]);
    DFSPRefresh();
    if(ended) {
        NSArray *parts=DFSPPanes();
        CGRect a=parts.count>0?DFSPPaneRect(parts[0]):CGRectZero;
        CGRect b=parts.count>1?DFSPPaneRect(parts[1]):CGRectZero;
        DFSPLog([NSString stringWithFormat:
          @"Native12 divider requested=%.5f hostRatio=%.5f style=%ld realPane0=%@ realPane1=%@ normalWindow=%@",
          ratio,[manager ratio],(long)[manager split],
          NSStringFromCGRect(a),NSStringFromCGRect(b),
          NSStringFromCGRect(DFSPWindow.frame)]);
    }
}
@end

static void DFSPRemove(void) {
    UIWindow *oldWindow=DFSPWindow;
    // Reset CarPlay chrome ownership and original hidden-state snapshots.
    DFSPChromeRequest(NO,YES,DFSPSequence);
    [DFSPHost restoreAndDetach];
    DFSPHost=nil;
    DFSPVisualCompatibility=NO;
    if (oldWindow) {
        oldWindow.windowLevel=DFSPOriginalLevel;
        if (DFSPHasOriginalWindowBackground) {
            oldWindow.backgroundColor=DFSPOriginalWindowBackground;
            oldWindow.opaque=DFSPOriginalWindowOpaque;
        }
        // Restore only the original frame at disconnect, never during Zoom.
        oldWindow.frame=DFSPOriginalFrame;
    }
    DFSPOriginalWindowBackground=nil;
    DFSPHasOriginalWindowBackground=NO;
    DFSPClearPaneFocus(YES);
    [DFSPUI resetForDisconnect];
    DFSPRestoreReplacedViews(); // true state rollback, including originally hidden views
    DFSPLegacyModalOpen=NO;
    ++DFSPLegacyModalEpoch;
    DFSPUI=nil;
    DFSPAdapter=nil;
    DFSPWindow=nil;
    DFSPManager=nil;
    DFSPFull=NO;
    DFSPApplying=NO;
    DFSPLog(@"window detached; old SidePlay level/frame restored");
}
static void DFSPInstall(SPDash *owner, UIWindow *window,
                        NSUInteger generation, NSUInteger attempt) {
    if (generation!=DFSPSequence || !owner || !window) return;
    if (!DFSPExternal(window)) {
        if (attempt<12)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,250000000),
                           dispatch_get_main_queue(), ^{
                DFSPInstall(owner,window,generation,attempt+1);
            });
        else DFSPLog(@"window not external; no global UIWindow override");
        return;
    }
    if (DFSPWindow==window && DFSPUI) {
        if (!DFSPFull && DFSPHost) (void)DFSPApply(NO,@"reconnected");
        DFSPRefresh();
        return;
    }
    if (DFSPWindow && DFSPWindow!=window) DFSPRemove();
    DFSPOriginalLevel=window.windowLevel;
    DFSPOriginalFrame=window.frame;
    DFSPWindow=window;
    DFSPManager=owner;
    DFSPLegacyModalOpen=NO;
    ++DFSPLegacyModalEpoch;
    DFSPFull=NO;
    DFSPApplying=NO;
    DFSPFocusedSlot=-1;
    DFSPRestorePaneVisibility();
    DFSPLayoutCalls=0;
    // Fail closed instead of applying an unverified global window crop.
    UIView *realRoot=[owner rootView];
    CGRect usable=DFSPSystemUsableRect(window);
    // SidePlay's own dock geometry is recorded verbatim for real-device triage.
    // carDockArea is a CGRect from its original arm64 method metadata; do not
    // force it into UIWindow-local coordinates without an owner validation.
    DFSPLog([NSString stringWithFormat:
        @"QA9 SidePlay host dockMode=%d dockArea=%@ carWindowFrameNow=%@ actualWindow=%@",
        [owner carDockMode],NSStringFromCGRect([owner carDockArea]),
        NSStringFromCGRect([owner carWindowFrameNow]),NSStringFromCGRect(window.frame)]);
    DFSPHost=[[DFSPNative12Host alloc]initWithCarPlayWindow:window
                    contentRoot:realRoot nativeUsableInWindow:usable];
    DFSPVisualCompatibility=(DFSPHost==nil);
    DFSPLog([NSString stringWithFormat:
      @"QA7 owner-check attached=%d rootInWindow=%d rootTransform=%@ rootFrame=%@ rootBounds=%@ windowFrame=%@ windowBounds=%@ usable=%@ safe=%@",
      DFSPHost!=nil,
      realRoot && [realRoot isDescendantOfView:window],
      realRoot?NSStringFromCGAffineTransform(realRoot.transform):@"nil",
      realRoot?NSStringFromCGRect(realRoot.frame):@"nil",
      realRoot?NSStringFromCGRect(realRoot.bounds):@"nil",
      NSStringFromCGRect(window.frame),NSStringFromCGRect(window.bounds),
      NSStringFromCGRect(usable),NSStringFromUIEdgeInsets(window.safeAreaInsets)]);
    // A rejected host must NEVER silently restore the old SidePlay controls.
    // Reversible visual-only mode does not resize UIWindow or hosted scenes;
    // Zoom remains disabled until the native geometry/chrome owner is confirmed.
    DFSPOriginalWindowBackground=window.backgroundColor;
    DFSPOriginalWindowOpaque=window.opaque;
    DFSPHasOriginalWindowBackground=YES;
    if (DFSPHost) {
        window.opaque=NO;
        window.backgroundColor=UIColor.clearColor;
    }
    DFSPAdapter=[DFSPNativeAdapter new];
    DFSPUI=[[DFSPNativeFrame alloc]initWithFrame:window.bounds];
    DFSPUI.delegate=DFSPAdapter;
    [window addSubview:DFSPUI];
    DFSPLog(@"Native12 approved frame mounted; SidePlay chip controls suppressed");
    DFSPLog([NSString stringWithFormat:
        @"SPDash host attached external=%@ originalFrame=%@ oldLevel=%.1f",
        window.screen,NSStringFromCGRect(DFSPOriginalFrame),DFSPOriginalLevel]);
    if (DFSPHost && !DFSPApply(NO,@"startup")) {
        DFSPLog(@"QA7: host Normal failed; preserving DuoFace UI only; no scene/window crop");
        [DFSPHost restoreAndDetach];
        DFSPHost=nil;
        DFSPVisualCompatibility=YES;
        // Keep original SidePlay root and window chrome geometry untouched.
        window.windowLevel=DFSPOriginalLevel;
        window.backgroundColor=DFSPOriginalWindowBackground;
        window.opaque=DFSPOriginalWindowOpaque;
    }
    if (DFSPVisualCompatibility)
        DFSPLog(@"QA9 VISUAL_COMPATIBILITY: visual-only, Zoom locked; CarPlay bar receiver requested; window unchanged");
    // Request native system bar even if geometry validation rejected the root.
    // This must never mutate the SidePlay app-scene/window geometry.
    if (!DFSPHost)DFSPChromeRequest(YES,YES,DFSPSequence);
    DFSPRefresh();
}
%hook SPDash
- (void)setCarWindow:(UIWindow *)window {
    %orig; // preserve creation and app hosting; replace only display control
    NSUInteger generation=++DFSPSequence;
    if (!window) {
        if (DFSPManager==self) DFSPRemove();
        return;
    }
    __weak SPDash *weakOwner=self;
    __weak UIWindow *weakWindow=window;
    dispatch_async(dispatch_get_main_queue(), ^{
        DFSPInstall(weakOwner,weakWindow,generation,0);
    });
}
// SidePlay owns these modal panels. QA9 kept its own divider/logo above
// them by calling bringSubviewToFront: on every refresh.
- (void)showPickerForPane:(id)pane {
    if (DFSPManager==self)DFSPSetSidePlayModal(YES,@"showPickerForPane");
    %orig(pane);
    if (DFSPManager==self)DFSPSetSidePlayModal(YES,@"picker presented");
}
- (void)dismissPicker {
    %orig;
    if (DFSPManager==self)
        DFSPMaybeResumeAfterSidePlayModal(self,@"dismissPicker",0);
}
- (void)pickerAppTapped:(id)sender {
    %orig(sender);
    if (DFSPManager==self)
        DFSPMaybeResumeAfterSidePlayModal(self,@"pickerAppTapped",0);
}
- (void)layoutChooser {
    if (DFSPManager==self)DFSPSetSidePlayModal(YES,@"layoutChooser");
    %orig;
}
- (void)revealChosenLayout:(id)selection {
    %orig(selection);
    if (DFSPManager==self)
        DFSPMaybeResumeAfterSidePlayModal(self,@"revealChosenLayout",0);
}
// App-host preferences/frame selectors remain owned by SidePlay.
// Never force carDockMode=NO or re-assign its UIWindow.frame from QA.
- (void)layout:(BOOL)animated {
    %orig(animated);
    if (DFSPManager==self && DFSPHost && !DFSPApplying &&
        ![DFSPHost reconcileAfterSystemLayout])
        DFSPLog(@"QA6: host content-root reconcile after SPDash.layout failed");
    // Old SidePlay may relayout on rotation, ratio/style and scene updates.
    // Re-apply owner-visible focused pane after the original host layout.
    if (DFSPManager==self && !DFSPApplying && !DFSPApplyingPaneFocus) {
        if (DFSPFocusedSlot>=0 && !DFSPApplyPaneFocus())
            DFSPClearPaneFocus(NO);
        DFSPRefresh();
    }
}
- (void)layoutRootView {
    %orig; // preserve SPDash scene/app layout; adjust only validated root.
    if (DFSPManager==self && DFSPWindow && DFSPHost && !DFSPApplying) {
        if (![DFSPHost reconcileAfterSystemLayout])
            DFSPLog(@"QA6: content-root reconcile after SPDash.layoutRootView failed");
        DFSPRefresh();
    }
}
%end

static void DFSPTryInit(unsigned attempt) {
    if (objc_getClass("SPDash")) {
        %init;
        DFSPLog(@"QA9 injection and SPDash hooks installed (0.1.7~native12chrome9)");
        return;
    }
    if (attempt<30)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,1000000000),
                       dispatch_get_main_queue(), ^{DFSPTryInit(attempt+1);});
    else DFSPLog(@"QA7: SPDash class missing after 30 attempts; check SpringBoard injection and installed QA version");
}
%ctor {
    @autoreleasepool {
        if (![NSBundle.mainBundle.bundleIdentifier.lowercaseString
               isEqualToString:@"com.apple.springboard"]) return;
        dispatch_async(dispatch_get_main_queue(), ^{DFSPTryInit(0);});
    }
}
