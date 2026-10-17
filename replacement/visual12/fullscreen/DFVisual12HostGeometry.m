// The existing Fullscreen transport can use this same C entrypoint contract.
// This is a source-owned geometry adapter, NOT the old CBWindow Logos hook.
// Runtime use requires ONE standalone scene owner and the separate chrome ACK.
#import "DFHostGeometry.h"
#import "DFCBCompat.h"
#import <math.h>

@interface DFV12HostSnapshot : NSObject
@property(nonatomic,weak) DFCBBridgeManager *manager;
@property(nonatomic,weak) DFCBWindow *window;
@property(nonatomic,weak) DFCBBridgedSplitApp *app;
@property(nonatomic,weak) UIView *content;
@property(nonatomic,weak) UIView *splitView;
@property(nonatomic) CGRect managerFrame;
@property(nonatomic) CGRect windowFrame;
@property(nonatomic) CGRect contentFrame;
@property(nonatomic) CGRect splitFrame;
@property(nonatomic) CGSize renderSize;
@property(nonatomic) CGAffineTransform transform;
@end
@implementation DFV12HostSnapshot
@end

static DFV12HostSnapshot *DFV12Snapshot;
static BOOL DFV12Expanded, DFV12Installed, DFV12Relayout;
static void (^DFV12LifecycleCallback)(void);

static BOOL DFV12Rect(CGRect r) {
    return isfinite(r.origin.x) && isfinite(r.origin.y) &&
           isfinite(r.size.width) && isfinite(r.size.height) &&
           r.size.width > 0 && r.size.height > 0;
}
static DFCBBridgeManager *DFV12Manager(void) {
    return [DFCBBridgeManager sharedInstanceIfExists];
}
static BOOL DFV12SameOwner(void) {
    DFCBBridgeManager *m=DFV12Manager();
    return DFCBHostIsBound() && DFV12Snapshot &&
           m==DFV12Snapshot.manager && m.activated &&
           m.window==DFV12Snapshot.window && m.currentApp==DFV12Snapshot.app &&
           m.window.contentView==DFV12Snapshot.content &&
           m.currentApp.view==DFV12Snapshot.splitView;
}
BOOL DFHostCanExpand(void) {
    if(!NSThread.isMainThread || !DFV12Installed || !DFCBHostIsBound())return NO;
    DFCBBridgeManager *m=DFV12Manager();
    DFCBWindow *w=m.window;
    if(!m.activated || !w.isVisible || ![m.currentApp isKindOfClass:DFCBBridgedSplitApp.class])return NO;
    UIWindow *external=w.rootWindow;
    UIView *split=m.currentApp.view;
    return external && !external.hidden && split && split.window==external &&
           split==w.contentView && DFV12Rect([DFCBWindow carPlayScreenBounds]);
}
BOOL DFHostIsExpanded(void) {return DFV12Expanded && DFV12SameOwner();}
void DFHostSetLifecycleCallback(void (^callback)(void)) {
    if(!NSThread.isMainThread)return;
    DFV12LifecycleCallback=[callback copy];
}
void DFHostRestore(void) {
    if(!NSThread.isMainThread)return;
    DFV12HostSnapshot *s=DFV12Snapshot;
    BOOL same=DFV12SameOwner();
    DFV12Snapshot=nil;
    DFV12Expanded=NO;
    if(!s || !same)return;
    s.manager.appFrame=s.managerFrame;
    s.manager.renderSize=s.renderSize;
    s.window.appFrame=s.windowFrame;
    [s.window resizeWindows];
    s.content.frame=s.contentFrame;
    s.splitView.transform=s.transform;
    s.splitView.frame=s.splitFrame;
    [s.app layoutSplitViews];
}
BOOL DFHostSetExpanded(BOOL expanded,NSString **reason) {
    if(!NSThread.isMainThread){if(reason)*reason=@"requires main thread";return NO;}
    if(!expanded){DFHostRestore();return YES;}
    if(DFHostIsExpanded())return YES;
    if(DFV12Snapshot)DFHostRestore();
    if(!DFHostCanExpand()){if(reason)*reason=@"standalone host unavailable";return NO;}
    DFCBBridgeManager *m=DFV12Manager();
    DFCBWindow *w=m.window;
    CGRect bounds=[DFCBWindow carPlayScreenBounds];
    if(!DFV12Rect(bounds) || !CGAffineTransformIsIdentity(m.currentApp.view.transform)){
        if(reason)*reason=@"invalid screen bounds or transformed split root";
        return NO;
    }
    DFV12HostSnapshot *s=[DFV12HostSnapshot new];
    s.manager=m;s.window=w;s.app=m.currentApp;s.content=w.contentView;s.splitView=m.currentApp.view;
    s.managerFrame=m.appFrame;s.renderSize=m.renderSize;s.windowFrame=w.appFrame;
    s.contentFrame=w.contentView.frame;s.splitFrame=m.currentApp.view.frame;
    s.transform=m.currentApp.view.transform;
    DFV12Snapshot=s;DFV12Expanded=YES;
    @try {
        DFV12Relayout=YES;
        m.appFrame=bounds;
        m.renderSize=CGSizeMake(round(bounds.size.width*2),round(bounds.size.height*2));
        w.appFrame=bounds;
        [w resizeWindows];
        [m.currentApp layoutSplitViews];
        DFV12Relayout=NO;
    } @catch(NSException *exception) {
        DFV12Relayout=NO;
        if(reason)*reason=exception.reason;
        DFHostRestore();
        return NO;
    }
    CGRect actual=w.contentView.frame;
    if(!DFV12SameOwner() || !DFV12Rect(actual) ||
       fabs(CGRectGetWidth(actual)-CGRectGetWidth(bounds))>1 ||
       fabs(CGRectGetHeight(actual)-CGRectGetHeight(bounds))>1) {
        DFHostRestore();
        if(reason)*reason=@"geometry ACK failed";
        return NO;
    }
    // Native iOS CarPlay chrome is a DIFFERENT process; caller must obtain
    // its own status/dock hide ACK before claiming visible fullscreen success.
    return YES;
}
BOOL DFInstallHostGeometryHooks(void) {
    if(!NSThread.isMainThread ||
       ![NSProcessInfo.processInfo.processName isEqualToString:@"SpringBoard"])return NO;
    if(DFV12Installed)return YES;
    if(!NSClassFromString(@"DFCBBridgeManager") || !NSClassFromString(@"DFCBWindow") ||
       !NSClassFromString(@"DFCBBridgedSplitApp"))return NO;
    // The standalone engine calls bind/unbind; do NOT hook any old CB selector.
    DFCBSetLifecycleCallback(^{
        if(DFV12Expanded && !DFV12SameOwner())DFHostRestore();
        if(DFV12LifecycleCallback)DFV12LifecycleCallback();
    });
    DFV12Installed=YES;
    (void)DFV12Relayout;
    return YES;
}
