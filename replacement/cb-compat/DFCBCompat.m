// DuoFace-owned compatibility facade around a separately implemented CarPlay
// window/scene owner. This file does NOT implement an app scene launcher.
// Built only into a standalone replacement package; no CB vendor payload.
#import "DFCBCompat.h"
#import <objc/runtime.h>
#import <math.h>

NSString * const DFCBCompatErrorDomain = @"com.duoface.visual12.cbcompat";

static __weak UIWindow *DFCBActualWindow;
static __weak UIViewController *DFCBActualController;
static DFCBWindow *DFCBWindowProxy;
static DFCBBridgedSplitApp *DFCBSplitProxy;
static DFCBBridgeManager *DFCBManagerProxy;

static BOOL DFCBValidRect(CGRect r) {
    return isfinite(r.origin.x) && isfinite(r.origin.y) &&
           isfinite(r.size.width) && isfinite(r.size.height) &&
           r.size.width > 0 && r.size.height > 0;
}
static void DFCBSetError(NSError **error, NSInteger code, NSString *reason) {
    if(error) *error=[NSError errorWithDomain:DFCBCompatErrorDomain code:code
       userInfo:@{NSLocalizedDescriptionKey:reason}];
}
static BOOL DFCBMainThread(void) { return NSThread.isMainThread; }
static BOOL DFCBHasOwner(void) {
    UIWindow *w=DFCBActualWindow;
    UIViewController *c=DFCBActualController;
    return w && c && w.rootViewController==c && c.isViewLoaded &&
           c.view.window==w && DFCBValidRect(w.bounds);
}

@interface DFCBWindow ()
@property(nonatomic,weak) UIWindow *externalWindow;
@end
@implementation DFCBWindow
+ (CGRect)carPlayScreenBounds {
    UIWindow *w=DFCBActualWindow;
    return DFCBHasOwner()?w.bounds:CGRectZero;
}
+ (CGRect)carPlayUsableBounds { return [self carPlayScreenBounds]; }
- (UIWindow *)rootWindow { return DFCBHasOwner()?self.externalWindow:nil; }
- (UIView *)contentView { return DFCBHasOwner()?DFCBActualController.view:nil; }
- (BOOL)isVisible {
    return DFCBHasOwner() && !self.externalWindow.hidden &&
           !self.contentView.hidden;
}
- (void)resizeWindows {
    if(!DFCBMainThread() || !DFCBHasOwner()) return;
    UIView *view=self.contentView;
    if(!view) return;
    CGRect r=self.appFrame;
    if(!DFCBValidRect(r)) r=self.externalWindow.bounds;
    view.frame=r;
    [view setNeedsLayout];
    // The owning controller already knows how to relayout the pane views.
    [view layoutIfNeeded];
}
- (void)show {
    if(!DFCBMainThread() || !DFCBHasOwner())return;
    self.externalWindow.hidden=NO;
}
- (void)hide:(void(^)(void))completion {
    if(DFCBMainThread() && DFCBHasOwner())self.externalWindow.hidden=YES;
    if(completion)completion();
}
- (void)destroyWindows {
    if(!DFCBMainThread())return;
    DFCBUnbindHost(self.externalWindow);
}
@end

@interface DFCBBridgedSplitApp ()
@property(nonatomic,weak) UIViewController *ownerController;
@end
@implementation DFCBBridgedSplitApp
- (UIView *)view {
    return DFCBHasOwner()?self.ownerController.view:nil;
}
- (void)layoutSplitViews {
    if(!DFCBMainThread() || !DFCBHasOwner())return;
    UIView *view=self.view;
    [view setNeedsLayout];
    [view layoutIfNeeded];
}
@end

@interface DFCBBridgeManager ()
@property(nonatomic,readwrite) BOOL activated;
@property(nonatomic,strong,readwrite) DFCBWindow *window;
@property(nonatomic,strong,readwrite) DFCBBridgedSplitApp *currentApp;
@end
@implementation DFCBBridgeManager
+ (instancetype)sharedInstanceIfExists {
    if(!DFCBMainThread() || !DFCBHasOwner())return nil;
    return DFCBManagerProxy;
}
- (void)deactivateCurrentApp {
    if(!DFCBMainThread())return;
    DFCBUnbindHost(DFCBActualWindow);
}
@end

BOOL DFCBHostIsBound(void) {
    return DFCBMainThread() && DFCBHasOwner() &&
           DFCBManagerProxy && DFCBManagerProxy.activated &&
           DFCBManagerProxy.window==DFCBWindowProxy &&
           DFCBManagerProxy.currentApp==DFCBSplitProxy;
}

BOOL DFCBBindHost(UIWindow *window,UIViewController *splitController,NSError **error) {
    if(!DFCBMainThread()) {
        DFCBSetError(error,1,@"Host binding must happen on SpringBoard main thread");
        return NO;
    }
    if(!window || !splitController || window.rootViewController!=splitController ||
       !splitController.isViewLoaded || splitController.view.window!=window ||
       !DFCBValidRect(window.bounds)) {
        DFCBSetError(error,2,@"Standalone external window and split controller must already be attached");
        return NO;
    }
    if(DFCBActualWindow && DFCBActualWindow!=window) {
        DFCBSetError(error,3,@"Another external scene owner is already bound");
        return NO;
    }
    if(DFCBHasOwner() && DFCBActualController!=splitController) {
        DFCBSetError(error,4,@"Cannot replace active split controller without unbinding");
        return NO;
    }
    // This facade neither constructs an external window nor launches apps.
    // The one actual scene owner creates and tears down both independently.
    DFCBActualWindow=window;
    DFCBActualController=splitController;
    if(!DFCBWindowProxy)DFCBWindowProxy=[DFCBWindow new];
    if(!DFCBSplitProxy)DFCBSplitProxy=[DFCBBridgedSplitApp new];
    if(!DFCBManagerProxy)DFCBManagerProxy=[DFCBBridgeManager new];
    DFCBWindowProxy.externalWindow=window;
    DFCBWindowProxy.appFrame=window.bounds;
    DFCBSplitProxy.ownerController=splitController;
    DFCBManagerProxy.window=DFCBWindowProxy;
    DFCBManagerProxy.currentApp=DFCBSplitProxy;
    DFCBManagerProxy.appFrame=window.bounds;
    DFCBManagerProxy.renderSize=CGSizeMake(window.bounds.size.width*2,window.bounds.size.height*2);
    DFCBManagerProxy.activated=YES;
    return DFCBHostIsBound();
}
void DFCBUnbindHost(UIWindow *window) {
    if(!DFCBMainThread() || !window || window!=DFCBActualWindow)return;
    DFCBManagerProxy.activated=NO;
    DFCBManagerProxy.currentApp=nil;
    DFCBManagerProxy.window=nil;
    DFCBSplitProxy.ownerController=nil;
    DFCBWindowProxy.externalWindow=nil;
    DFCBActualController=nil;
    DFCBActualWindow=nil;
}
