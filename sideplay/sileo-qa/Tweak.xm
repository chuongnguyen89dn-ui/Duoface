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

@interface SPDash : NSObject
- (void)setCarWindow:(UIWindow *)window;
- (void)setCarWindowFrame:(CGRect)frame;
- (CGRect)carWindowFrameNow;
- (BOOL)carDockMode;
- (void)layoutRootView;
- (void)layout:(BOOL)animated;
- (NSArray *)panes;
- (UIView *)rootView;
- (NSInteger)split;
- (double)ratio;
- (void)setRatio:(double)value;
- (void)showPickerForPane:(id)pane;
- (void)layoutChooser;
- (void)paneRequestsClose:(id)pane;
- (void)paneRequestsSwap:(id)pane;
@end

@interface SPPane : NSObject
- (UIView *)view;
- (UIView *)chipView;
- (UIView *)layoutButton;
- (id)appViewController;
- (NSInteger)scaleMode;
- (void)layoutInFrame:(CGRect)frame scaleMode:(NSInteger)mode;
@end

static __weak UIWindow *DFSPWindow;
static __weak SPDash *DFSPManager;
static DFSPNativeFrame *DFSPUI;
static DFSPNative12Host *DFSPHost;
static id<DFSPNativeFrameDelegate> DFSPAdapter;
static BOOL DFSPRefreshing=NO;
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
        !DFSPExternal(window) || DFSPApplying) return NO;
    BOOL wasFull=DFSPFull;
    DFSPApplying=YES;
    BOOL applied=full?[host applyFullscreen]:[host applyNormal];
    if (applied) {
        DFSPFull=full;
        // Z-order alone cannot conjure the system bar; the window outside
        // the actual content root must also stay transparent.
        window.windowLevel=full?DFSPOriginalLevel:UIWindowLevelStatusBar-1.0;
        [window setNeedsLayout];
        [window layoutIfNeeded];
        DFSPRefresh();
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
        DFSPHideReplacedView([pane chipView]);
        DFSPHideReplacedView([pane layoutButton]);
        if(!firstApp) DFSPHideSidePlayPlaceholder([pane view],0);
    }
    if(panes.count>1 && [panes[1] isKindOfClass:objc_getClass("SPPane")]) {
        SPPane *pane=panes[1];
        two=DFSPPaneRect(pane);
        secondApp=[pane appViewController]!=nil;
        DFSPHideReplacedView([pane chipView]);
        DFSPHideReplacedView([pane layoutButton]);
        if(!secondApp) DFSPHideSidePlayPlaceholder([pane view],0);
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
    [manager setRatio:ratio];
    // The existing SidePlay host applies the new ratio to its REAL SPPane
    // view + scene frames. We do not resize a decorative fake split image.
    [manager layout:ended];
    DFSPUpdatingRatio=NO;
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
    [DFSPHost restoreAndDetach];
    DFSPHost=nil;
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
        if (!DFSPFull) (void)DFSPApply(NO,@"reconnected");
        return;
    }
    if (DFSPWindow && DFSPWindow!=window) DFSPRemove();
    DFSPOriginalLevel=window.windowLevel;
    DFSPOriginalFrame=window.frame;
    DFSPWindow=window;
    DFSPManager=owner;
    DFSPFull=NO;
    DFSPApplying=NO;
    DFSPFocusedSlot=-1;
    DFSPRestorePaneVisibility();
    DFSPLayoutCalls=0;
    // Fail closed instead of applying an unverified global window crop.
    UIView *realRoot=[owner rootView];
    CGRect usable=DFSPSystemUsableRect(window);
    DFSPHost=[[DFSPNative12Host alloc]initWithCarPlayWindow:window
                    contentRoot:realRoot nativeUsableInWindow:usable];
    if (!DFSPHost) {
        DFSPLog([NSString stringWithFormat:
          @"QA6 host refused unsafe geometry window=%@ bounds=%@ root=%@ usable=%@",
          NSStringFromCGRect(window.frame),NSStringFromCGRect(window.bounds),
          realRoot,NSStringFromCGRect(usable)]);
        DFSPRemove();
        return;
    }
    DFSPOriginalWindowBackground=window.backgroundColor;
    DFSPOriginalWindowOpaque=window.opaque;
    DFSPHasOriginalWindowBackground=YES;
    // Transparent outside the content-owned usable area.
    window.opaque=NO;
    window.backgroundColor=UIColor.clearColor;
    DFSPAdapter=[DFSPNativeAdapter new];
    DFSPUI=[[DFSPNativeFrame alloc]initWithFrame:window.bounds];
    DFSPUI.delegate=DFSPAdapter;
    [window addSubview:DFSPUI];
    DFSPLog(@"Native12 approved frame mounted; SidePlay chip controls suppressed");
    DFSPLog([NSString stringWithFormat:
        @"SPDash host attached external=%@ originalFrame=%@ oldLevel=%.1f",
        window.screen,NSStringFromCGRect(DFSPOriginalFrame),DFSPOriginalLevel]);
    if (!DFSPApply(NO,@"startup")) {
        DFSPLog(@"startup override FAILED; disable replacement and restore old UI");
        DFSPRemove(); // no hidden legacy UI while the new display is broken
        return;
    }
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
        DFSPLog(@"SPDash display takeover hooks QA2 installed");
        return;
    }
    if (attempt<30)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,1000000000),
                       dispatch_get_main_queue(), ^{DFSPTryInit(attempt+1);});
    else DFSPLog(@"SPDash class missing; disabled");
}
%ctor {
    @autoreleasepool {
        if (![NSBundle.mainBundle.bundleIdentifier.lowercaseString
               isEqualToString:@"com.apple.springboard"]) return;
        dispatch_async(dispatch_get_main_queue(), ^{DFSPTryInit(0);});
    }
}
