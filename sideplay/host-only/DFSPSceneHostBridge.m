#import "DFSPSceneHostBridge.h"
#import <objc/runtime.h>
#import <math.h>

// Only SidePlay 1.0.4 arm64 ObjC ABI selectors demonstrated by the
// method-index.json audit are declared here. No SidePlay UI/chooser/ratio/zoom
// classes, no license/service selector and NO binary is linked or vendored.
@interface SPDash : NSObject
- (NSArray *)panes;
@end
@interface SPPane : NSObject
- (UIView *)view;
- (id)appViewController;
- (void)loadApp:(NSString *)bundleIdentifier;
- (void)unloadApp;
@end

@interface DFSPSceneHostBridge ()
@property (nonatomic, weak, readwrite, nullable) id host;
@property (nonatomic, weak, readwrite, nullable) UIWindow *carWindow;
@end

@implementation DFSPSceneHostBridge

- (instancetype)initWithLiveHost:(id)host carWindow:(UIWindow *)window {
    Class dash=NSClassFromString(@"SPDash");
    Class pane=NSClassFromString(@"SPPane");
    if (!host || !window || !dash || !pane ||
        ![host isKindOfClass:dash] ||
        ![host respondsToSelector:@selector(panes)]) return nil;
    if (!(self=[super init]))return nil;
    _host=host;
    _carWindow=window;
    return self;
}

// Explicitly reject a stale SidePlay manager, a rotated/disconnected window,
// or a slot whose underlying process scene has been replaced.
- (nullable SPPane *)paneAtSlot:(NSUInteger)slot {
    id manager=self.host;
    if (!manager || !self.carWindow ||
        ![manager respondsToSelector:@selector(panes)])return nil;
    NSArray *panes=[(SPDash *)manager panes];
    if (![panes isKindOfClass:NSArray.class] || slot>=panes.count)return nil;
    id obj=panes[slot];
    Class pane=NSClassFromString(@"SPPane");
    return pane && [obj isKindOfClass:pane]?(SPPane *)obj:nil;
}
- (NSUInteger)hostedSlotCount {
    id manager=self.host;
    if (!manager || !self.carWindow ||
        ![manager respondsToSelector:@selector(panes)])return 0;
    NSArray *panes=[(SPDash *)manager panes];
    return [panes isKindOfClass:NSArray.class]?panes.count:0;
}
- (BOOL)hasHostedAppInSlot:(NSUInteger)slot {
    SPPane *pane=[self paneAtSlot:slot];
    return pane && [pane respondsToSelector:@selector(appViewController)] &&
           [pane appViewController]!=nil;
}
- (nullable UIView *)hostedSceneViewForSlot:(NSUInteger)slot {
    SPPane *pane=[self paneAtSlot:slot];
    UIView *view=[pane respondsToSelector:@selector(view)]?[pane view]:nil;
    return [view isKindOfClass:UIView.class] &&
           view.window==self.carWindow?view:nil;
}
- (CGRect)hostedFrameForSlot:(NSUInteger)slot relativeToView:(UIView *)target {
    UIView *view=[self hostedSceneViewForSlot:slot];
    if (!view || !view.superview || !target || target.window!=self.carWindow)
        return CGRectNull;
    CGRect rect=[view.superview convertRect:view.frame toView:target];
    if (!isfinite(rect.origin.x) || !isfinite(rect.origin.y) ||
        !isfinite(rect.size.width) || !isfinite(rect.size.height) ||
        rect.size.width<=0 || rect.size.height<=0)return CGRectNull;
    return rect;
}
- (BOOL)loadBundleIdentifier:(NSString *)bundleID intoSlot:(NSUInteger)slot {
    if (!bundleID.length || ![NSThread isMainThread])return NO;
    SPPane *pane=[self paneAtSlot:slot];
    if (!pane || ![pane respondsToSelector:@selector(loadApp:)])return NO;
    // SidePlay remains responsible for its own scene/CarBridge lifecycle and
    // any valid authorization. We only forward a user-selected bundle ID.
    [pane loadApp:bundleID];
    return YES; // request dispatched, NOT proof of successful app presentation
}
- (BOOL)unloadSlot:(NSUInteger)slot {
    if (![NSThread isMainThread])return NO;
    SPPane *pane=[self paneAtSlot:slot];
    if (!pane || ![pane respondsToSelector:@selector(unloadApp)])return NO;
    [pane unloadApp];
    return YES; // request dispatched, not a finished scene teardown guarantee
}
@end
