// v12-only geometry adapter, reconstructed from the hash-pinned audit.
// CBWindow geometry: 0xb1aac; split layout: 0x1044f8; owner: 0x2ca140.
// This module changes neither licensing nor split/focus selection.
#import "DFHostGeometry.h"
#import <objc/runtime.h>
#import <math.h>
typedef void (^DFHostCompletion)(void);

@interface CBWindow : NSObject
+ (CGRect)carPlayScreenBounds;
+ (CGRect)carPlayUsableBounds;
@property(nonatomic) CGRect appFrame;
@property(nonatomic, readonly) UIWindow *rootWindow;
@property(nonatomic, readonly) UIView *contentView;
@property(nonatomic, readonly) BOOL isVisible;
- (void)resizeWindows;
- (void)show;
// ObjC metadata v24@0:8@?16: this argument is a completion block, NOT a BOOL.
- (void)hide:(DFHostCompletion)completion;
- (void)destroyWindows;
@end

@interface CBBridgedSplitApp : NSObject
@property(nonatomic, readonly) UIView *view;
- (void)layoutSplitViews;
@end

@interface CBBridgeManager : NSObject
+ (instancetype)sharedInstanceIfExists;
@property(nonatomic, readonly) BOOL activated;
@property(nonatomic, readonly) CBWindow *window;
@property(nonatomic, readonly) id currentApp;
@property(nonatomic) CGRect appFrame;
@property(nonatomic) CGSize renderSize;
- (void)deactivateCurrentApp;
@end

@interface DFHostSnapshot : NSObject
@property(nonatomic, weak) CBBridgeManager *manager;
@property(nonatomic, weak) CBWindow *window;
@property(nonatomic, weak) CBBridgedSplitApp *app;
@property(nonatomic, weak) UIView *content;
@property(nonatomic, weak) UIView *appView;
@property(nonatomic) CGRect managerFrame;
@property(nonatomic) CGSize renderSize;
@property(nonatomic) CGRect windowFrame;
@property(nonatomic) CGRect contentFrame;
@property(nonatomic) CGRect appViewFrame;
@property(nonatomic) CGAffineTransform appViewTransform;
@end
@implementation DFHostSnapshot
@end

static DFHostSnapshot *DFSnapshot;
static BOOL DFExpanded;
static BOOL DFRelayoutInProgress;
static BOOL DFHooksInstalled;
static __weak CBWindow *DFHidingWindow;
static void (^DFLifecycleCallback)(void);

static CBBridgeManager *DFManager(void) {
    Class cls = NSClassFromString(@"CBBridgeManager");
    return [cls respondsToSelector:@selector(sharedInstanceIfExists)] ?
        [cls sharedInstanceIfExists] : nil;
}
static BOOL DFRectValid(CGRect rect) {
    return isfinite(rect.origin.x) && isfinite(rect.origin.y) &&
        isfinite(rect.size.width) && isfinite(rect.size.height) &&
        rect.size.width > 0 && rect.size.height > 0;
}
static BOOL DFSameOwner(void) {
    CBBridgeManager *manager = DFManager();
    return DFSnapshot && manager == DFSnapshot.manager && manager.activated &&
        manager.window == DFSnapshot.window && manager.currentApp == DFSnapshot.app &&
        manager.window.contentView == DFSnapshot.content &&
        [DFSnapshot.app view] == DFSnapshot.appView;
}
BOOL DFHostCanExpand(void) {
    NSCAssert(NSThread.isMainThread, @"Host geometry must run on main thread");
    CBBridgeManager *manager = DFManager();
    CBWindow *window = manager.window;
    id app = manager.currentApp;
    Class splitClass = NSClassFromString(@"CBBridgedSplitApp");
    if (!DFHooksInstalled || !manager.activated || !window.isVisible || window == DFHidingWindow ||
        !splitClass || ![app isKindOfClass:splitClass]) return NO;
    UIView *view = [app view];
    return window.rootWindow && !window.rootWindow.hidden && window.contentView &&
        view && [view isDescendantOfView:window.contentView] &&
        DFRectValid([NSClassFromString(@"CBWindow") carPlayScreenBounds]);
}
BOOL DFHostIsExpanded(void) { return DFExpanded && DFSameOwner(); }
void DFHostSetLifecycleCallback(void (^callback)(void)) { DFLifecycleCallback = [callback copy]; }

static void DFRelayout(void) {
    if (DFRelayoutInProgress || !DFSameOwner()) return;
    DFRelayoutInProgress = YES;
    @try {
        CBWindow *window = DFSnapshot.window;
        CBBridgeManager *manager = DFSnapshot.manager;
        CGRect bounds = [NSClassFromString(@"CBWindow") carPlayUsableBounds];
        manager.appFrame = bounds;
        // Same render-size calculation as v12 metrics callback at 0x1d14e0.
        manager.renderSize = CGSizeMake(roundf((float)(bounds.size.width * 2)),
                                        roundf((float)(bounds.size.height * 2)));
        window.appFrame = bounds;
        [window resizeWindows];
        // resizeWindows owns contentView; use the actual parent coordinate space.
        UIView *view = DFSnapshot.appView;
        UIView *parent = view.superview;
        if (parent) view.frame = [parent convertRect:window.contentView.bounds
                                           fromView:window.contentView];
        [DFSnapshot.app layoutSplitViews];
        [view setNeedsLayout];
        [view layoutIfNeeded];
    } @finally {
        DFRelayoutInProgress = NO;
    }
}

void DFHostRestore(void) {
    NSCAssert(NSThread.isMainThread, @"Host restore must run on main thread");
    DFHostSnapshot *saved = DFSnapshot;
    if (!saved) { DFExpanded = NO; return; }
    BOOL sameOwner = DFSameOwner();
    DFExpanded = NO; // Disable the usable-bounds override before restoring.
    DFSnapshot = nil;
    if (sameOwner) {
        saved.manager.appFrame = saved.managerFrame;
        saved.manager.renderSize = saved.renderSize;
        saved.window.appFrame = saved.windowFrame;
        [saved.window resizeWindows];
        saved.content.frame = saved.contentFrame;
        saved.appView.transform = saved.appViewTransform;
        saved.appView.frame = saved.appViewFrame;
        [saved.app layoutSplitViews];
        [saved.appView setNeedsLayout];
        [saved.appView layoutIfNeeded];
    }
    NSLog(@"[DuoFaceFullscreen] host restored sameOwner=%d", sameOwner);
}

BOOL DFHostSetExpanded(BOOL expanded, NSString **reason) {
    NSCAssert(NSThread.isMainThread, @"Host transition must run on main thread");
    if (!expanded) { DFHostRestore(); return YES; }
    if (DFHostIsExpanded()) return YES;
    if (DFSnapshot) DFHostRestore();
    if (!DFHostCanExpand()) {
        if (reason) *reason = @"v12 split host unavailable";
        return NO;
    }
    CBBridgeManager *manager = DFManager();
    CBWindow *window = manager.window;
    CBBridgedSplitApp *app = manager.currentApp;
    DFHostSnapshot *saved = [DFHostSnapshot new];
    saved.manager = manager; saved.window = window; saved.app = app;
    saved.content = window.contentView; saved.appView = app.view;
    saved.managerFrame = manager.appFrame; saved.renderSize = manager.renderSize;
    saved.windowFrame = window.appFrame; saved.contentFrame = window.contentView.frame;
    saved.appViewFrame = app.view.frame; saved.appViewTransform = app.view.transform;
    // A transformed split root requires a separate coordinate audit, not a guessed reset.
    if (!CGAffineTransformIsIdentity(saved.appViewTransform)) {
        if (reason) *reason = @"split root has an unsupported transform";
        return NO;
    }
    DFSnapshot = saved; DFExpanded = YES;
    @try { DFRelayout(); }
    @catch (NSException *exception) {
        if (reason) *reason = exception.reason;
        DFHostRestore();
        return NO;
    }
    CGRect expected = [NSClassFromString(@"CBWindow") carPlayScreenBounds];
    CGRect actual = window.contentView.frame;
    BOOL applied = DFSameOwner() && fabs(actual.origin.x-expected.origin.x)<0.5 &&
        fabs(actual.origin.y-expected.origin.y)<0.5 &&
        fabs(actual.size.width-expected.size.width)<0.5 &&
        fabs(actual.size.height-expected.size.height)<0.5;
    if (!applied) {
        DFHostRestore();
        if (reason) *reason = @"content geometry did not match CarPlay display";
        return NO;
    }
    NSLog(@"[DuoFaceFullscreen] host geometry applied %@", NSStringFromCGRect(actual));
    return YES; // This is geometry success only; Dashboard chrome needs its own ACK.
}

%group DFHostGeometry
%hook CBWindow
+ (CGRect)carPlayUsableBounds {
    if (DFExpanded && DFSameOwner()) return [self carPlayScreenBounds];
    return %orig;
}
- (void)resizeWindows {
    %orig;
    if (DFExpanded && self == DFSnapshot.window && !DFRelayoutInProgress) DFRelayout();
}
- (void)show {
    if (self == DFHidingWindow) DFHidingWindow = nil;
    %orig;
    if (DFLifecycleCallback) DFLifecycleCallback();
}
- (void)hide:(DFHostCompletion)completion {
    if (self == DFSnapshot.window) DFHostRestore();
    DFHidingWindow = self;
    DFHostCompletion wrapped = ^{
        if (completion) completion();
        if (DFLifecycleCallback) DFLifecycleCallback();
    };
    %orig(wrapped);
    if (DFLifecycleCallback) DFLifecycleCallback();
}
- (void)destroyWindows {
    if (self == DFSnapshot.window) DFHostRestore();
    %orig;
    if (DFLifecycleCallback) DFLifecycleCallback();
}
%end
%hook CBBridgeManager
- (void)deactivateCurrentApp {
    if (self == DFSnapshot.manager) DFHostRestore();
    %orig;
    if (DFLifecycleCallback) DFLifecycleCallback();
}
%end
%end

BOOL DFInstallHostGeometryHooks(void) {
    if (DFHooksInstalled) return YES;
    if (![[NSBundle.mainBundle.bundleIdentifier lowercaseString] isEqualToString:@"com.apple.springboard"])
        return NO;
    if (!NSClassFromString(@"CBWindow") || !NSClassFromString(@"CBBridgeManager") ||
        !NSClassFromString(@"CBBridgedSplitApp")) return NO;
    %init(DFHostGeometry);
    DFHooksInstalled = YES;
    return YES;
}
