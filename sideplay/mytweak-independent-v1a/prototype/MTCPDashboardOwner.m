// First-party Dashboard view bridge. No vendor binary or license. No window creation.
// Root view remains owned by Apple; the overlay is constrained to a system-visible
// bar's opposite content rect. At x=-45 the whole operation FAILS CLOSED.
#import "MTCPDashboardOwner.h"
#import "MTCPNativeChromeLayout.h"
#import "MTCPBridgeContract.h"
#import "MTCPRemoteLayer.h"
#import <math.h>
@interface MTCPDashboardOwner ()
@property(nonatomic,weak) UIViewController *dashboardRoot;
@property(nonatomic,strong) UIView *contentView;
@property(nonatomic,strong) MTCPRemoteLayerReceiver *receiver;
@property(nonatomic,assign) CGRect contentRect;
@property(nonatomic,assign,readwrite) BOOL attached;
@end
@implementation MTCPDashboardOwner
- (CGRect)activeContentRect { return self.attached?self.contentRect:CGRectNull; }
static BOOL MTCPDashboardProcess(void) {
    NSString *p=NSProcessInfo.processInfo.processName;
    return [p isEqualToString:@"CarPlay"] || [p isEqualToString:@"CarPlayApp"];
}
static BOOL MTCPDashboardWindow(UIViewController *root,UIWindow **window) {
    if (!root || !root.isViewLoaded || ![NSStringFromClass(root.class) isEqualToString:@"DBDashboardRootViewController"])return NO;
    UIWindow *w=root.view.window;
    if (!w || !w.windowScene || !w.screen || w.screen==UIScreen.mainScreen ||
        w.rootViewController!=root || w.hidden || w.alpha<0.95)return NO;
    if (window)*window=w;
    return YES;
}
static BOOL MTCPNativeBarContent(UIWindow *dashboard,CGRect *content) {
    CGRect screen=dashboard.bounds;
    if (!MTCPNativeContentIsWithinScreen(screen,screen))return NO;
    BOOL found=NO;
    CGRect accepted=CGRectNull;
    // A CarPlay process can own more than one active external UIWindowScene;
    // the status window may be a sibling scene of the Dashboard root.
    NSUInteger inspected=0;
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class] ||
            scene.activationState!=UISceneActivationStateForegroundActive)continue;
        UIWindowScene *ws=(UIWindowScene *)scene;
        if (ws.screen!=dashboard.screen)continue;
        for (UIWindow *w in ws.windows) {
            if (++inspected>32)return NO; // ambiguous scene topology: fail closed
            NSString *name=NSStringFromClass(w.class);
            if (![name isEqualToString:@"DBStatusBarWindow"] &&
                ![name isEqualToString:@"CARStatusBarWindow"])continue;
            if (w.hidden || w.alpha<0.95 || w.screen!=dashboard.screen)continue;
            CGRect frame=[dashboard convertRect:w.bounds fromWindow:w];
            CGRect usable=CGRectNull;
            if (!MTCPNativeUsableBounds(screen,frame,&usable,NULL))continue;
            if (found && !CGRectEqualToRect(accepted,usable))return NO;
            found=YES;
            accepted=usable;
        }
    }
    if (!found)return NO;
    *content=accepted;
    return YES;
}
// A receiver ACK is not a "Dock visible" assertion. It means the
// system-owned Dashboard child has an active CALayerHost with a live surface.
- (BOOL)writeLiveReceiverAck:(UIWindow *)w {
    if (!self.attached || !self.receiver.session ||
        !MTCPDashboardWindow(self.dashboardRoot,NULL) || !w ||
        CGRectGetWidth(w.bounds)<=0 || CGRectGetHeight(w.bounds)<=0)return NO;
    NSDictionary *packet=MTCPBridgeReadSurface(self.receiver.session);
    uint32_t cid=[packet[@"ContextID"] unsignedIntValue];
    CGRect r=self.contentRect, b=w.bounds;
    CGRect normalized=CGRectMake((CGRectGetMinX(r)-CGRectGetMinX(b))/CGRectGetWidth(b),
                      (CGRectGetMinY(r)-CGRectGetMinY(b))/CGRectGetHeight(b),
                      CGRectGetWidth(r)/CGRectGetWidth(b),
                      CGRectGetHeight(r)/CGRectGetHeight(b));
    return cid!=0 && MTCPBridgeWriteReceiverAck(self.receiver.session,cid,normalized);
}
- (BOOL)attachToDashboardRoot:(UIViewController *)root {
    if (![NSThread isMainThread] || !MTCPDashboardProcess() ||
        !MTCPBridgeExplicitOptIn() || self.attached)return NO;
    UIWindow *w=nil;
    if (!MTCPDashboardWindow(root,&w))return NO;
    CGRect usable=CGRectNull;
    if (!MTCPNativeBarContent(w,&usable))return NO;
    // The source is a session-bound real CAContext, not a fabricated snapshot.
    if (!MTCPBridgeReadSurface(nil))return NO;
    CGRect local=[root.view convertRect:usable fromView:w];
    if (!MTCPNativeContentIsWithinScreen(root.view.bounds,local))return NO;
    UIView *host=[[UIView alloc] initWithFrame:local];
    host.accessibilityIdentifier=@"duoface.native.content.host";
    host.backgroundColor=UIColor.clearColor;
    host.clipsToBounds=YES;
    host.autoresizingMask=UIViewAutoresizingNone;
    [root.view addSubview:host];
    MTCPRemoteLayerReceiver *receiver=[MTCPRemoteLayerReceiver new];
    if (![receiver connectWithOwnedContentView:host]) {
        [host removeFromSuperview];
        return NO;
    }
    self.dashboardRoot=root;
    self.contentView=host;
    self.receiver=receiver;
    self.contentRect=usable;
    self.attached=YES;
    if (![self writeLiveReceiverAck:w]) {
        [self detach];return NO; // No sender handoff without valid acknowledgement.
    }
    return YES;
}
- (void)refresh {
    if (!self.attached)return;
    if (![NSThread isMainThread] || !MTCPBridgeExplicitOptIn() ||
        !self.receiver.session || !MTCPBridgeReadSurface(self.receiver.session)) {
        [self detach];return;
    }
    UIWindow *w=nil;
    if (!MTCPDashboardWindow(self.dashboardRoot,&w)) {[self detach];return;}
    CGRect usable=CGRectNull;
    if (!MTCPNativeBarContent(w,&usable)) {[self detach];return;}
    CGRect local=[self.dashboardRoot.view convertRect:usable fromView:w];
    if (!MTCPNativeContentIsWithinScreen(self.dashboardRoot.view.bounds,local)) {
        [self detach];return;
    }
    self.contentView.frame=local;
    self.contentRect=usable;
    if (![self writeLiveReceiverAck:w]) [self detach];
}
- (void)detach {
    if (self.receiver.session)MTCPBridgeInvalidateReceiverAck(self.receiver.session);
    [self.receiver disconnect];
    [self.contentView removeFromSuperview];
    self.receiver=nil;
    self.contentView=nil;
    self.dashboardRoot=nil;
    self.contentRect=CGRectNull;
    self.attached=NO;
}
- (void)dealloc {[self detach];}
@end
