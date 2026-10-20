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
@property(nonatomic,assign,readwrite,getter=isHostFullscreen) BOOL hostFullscreen;
@property(nonatomic,assign) CGRect savedNormalContentRect;
@property(nonatomic,assign) CGRect savedNormalScreenRect;
@property(nonatomic,assign) CGRect savedNativeBarFrame;
@property(nonatomic,weak) UIWindow *savedNativeBarWindow;
@property(nonatomic,assign) BOOL savedNativeBarHidden;
@property(nonatomic,assign) BOOL nativeChromeModified;
@end
@implementation MTCPDashboardOwner
- (NSString *)receiverSession { return self.receiver.session; }
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
static BOOL MTCPNativeBarContent(UIWindow *dashboard,CGRect *content,
                                   UIWindow **barOut) {
    if (barOut)*barOut=nil;
    CGRect screen=dashboard.bounds;
    if (!MTCPNativeContentIsWithinScreen(screen,screen))return NO;
    BOOL found=NO;
    CGRect accepted=CGRectNull;
    UIWindow *acceptedBar=nil;
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
            acceptedBar=w;
        }
    }
    if (!found)return NO;
    *content=accepted;
    if (barOut)*barOut=acceptedBar;
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
    UIWindow *bar=nil;
    if (!MTCPNativeBarContent(w,&usable,&bar))return NO;
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
    self.savedNormalContentRect=usable;
    self.savedNormalScreenRect=w.bounds;
    self.savedNativeBarWindow=bar;
    self.savedNativeBarFrame=bar.frame;
    self.savedNativeBarHidden=bar.hidden;
    self.hostFullscreen=NO;
    self.nativeChromeModified=NO;
    self.attached=YES;
    if (![self writeLiveReceiverAck:w]) {
        [self detach];return NO; // No sender handoff without valid acknowledgement.
    }
    return YES;
}
// Native12-equivalent geometry state: the Apple-owned window/root stays
// full display; only the hosted pane region changes. Do NOT crop UIWindow.
// Fullscreen hides the existing native chrome; exit restores its saved state.
- (BOOL)applyHostFullscreen:(BOOL)fullscreen {
    if (![NSThread isMainThread] || !self.attached)return NO;
    if (self.hostFullscreen==fullscreen)return YES;
    UIWindow *w=nil;
    if (!MTCPDashboardWindow(self.dashboardRoot,&w))return NO;
    if (fullscreen) {
        CGRect usable=CGRectNull;UIWindow *bar=nil;
        if (!MTCPNativeBarContent(w,&usable,&bar) || !bar || bar.hidden)return NO;
        if (!MTCPNativeContentIsWithinScreen(w.bounds,usable))return NO;
        self.savedNormalContentRect=usable;
        self.savedNormalScreenRect=w.bounds;
        self.savedNativeBarWindow=bar;
        self.savedNativeBarFrame=bar.frame;
        self.savedNativeBarHidden=bar.hidden;
        CGRect full=w.bounds;
        CGRect rootRect=[self.dashboardRoot.view convertRect:full fromView:w];
        if (!MTCPNativeContentIsWithinScreen(self.dashboardRoot.view.bounds,rootRect))return NO;
        // Same two-part transition as Native12/Airaw: real content region
        // screenBounds + native system bar hidden. Do not touch rootWindow.frame.
        bar.hidden=YES;
        if (!bar.hidden)return NO;
        self.nativeChromeModified=YES;
        self.contentView.frame=rootRect;
        self.contentRect=full;
        self.hostFullscreen=YES;
        if (![self writeLiveReceiverAck:w]) {
            [self applyHostFullscreen:NO];return NO;
        }
        NSLog(@"[DuoFaceNativeGeometry] enter normal=%@ full=%@ barHidden=%d",
              NSStringFromCGRect(usable),NSStringFromCGRect(full),bar.hidden);
        return YES;
    }
    // Exit: restore Chrome first; only if it is still hidden by our own
    // transition. If Apple changed the state/owner, never fight it.
    if(self.nativeChromeModified && self.savedNativeBarWindow &&
       self.savedNativeBarWindow.hidden)
        self.savedNativeBarWindow.hidden=self.savedNativeBarHidden;
    self.nativeChromeModified=NO;
    CGRect usable=CGRectNull;UIWindow *bar=nil;
    BOOL live=MTCPNativeBarContent(w,&usable,&bar);
    if (!live && CGRectEqualToRect(w.bounds,self.savedNormalScreenRect) &&
        MTCPNativeContentIsWithinScreen(w.bounds,self.savedNormalContentRect))
        usable=self.savedNormalContentRect;
    else if (!live)return NO;
    CGRect local=[self.dashboardRoot.view convertRect:usable fromView:w];
    if (!MTCPNativeContentIsWithinScreen(self.dashboardRoot.view.bounds,local))return NO;
    self.contentView.frame=local;
    self.contentRect=usable;
    self.hostFullscreen=NO;
    if (![self writeLiveReceiverAck:w])return NO;
    NSLog(@"[DuoFaceNativeGeometry] restore normal=%@ full=%@ barHidden=%d",
          NSStringFromCGRect(usable),NSStringFromCGRect(w.bounds),
          self.savedNativeBarWindow.hidden);
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
    UIWindow *bar=nil;
    if (self.hostFullscreen) {
        // Native bar is deliberately hidden; do not fail the geometry check.
        if (!self.savedNativeBarWindow || self.savedNativeBarWindow.screen!=w.screen ||
            !self.savedNativeBarWindow.hidden) {[self detach];return;}
        usable=w.bounds;
    } else if (!MTCPNativeBarContent(w,&usable,&bar)) {
        [self detach];return;
    }
    CGRect local=[self.dashboardRoot.view convertRect:usable fromView:w];
    if (!MTCPNativeContentIsWithinScreen(self.dashboardRoot.view.bounds,local)) {
        [self detach];return;
    }
    self.contentView.frame=local;
    self.contentRect=usable;
    if (!self.hostFullscreen) {
        self.savedNormalContentRect=usable;
        self.savedNormalScreenRect=w.bounds;
        self.savedNativeBarWindow=bar;
        self.savedNativeBarFrame=bar.frame;
        self.savedNativeBarHidden=bar.hidden;
    }
    if (![self writeLiveReceiverAck:w]) [self detach];
}
- (void)detach {
    // Exact owner/chrome state restoration before the receiver disappears.
    if (self.nativeChromeModified && self.savedNativeBarWindow &&
        self.savedNativeBarWindow.hidden)
        self.savedNativeBarWindow.hidden=self.savedNativeBarHidden;
    self.hostFullscreen=NO;
    self.nativeChromeModified=NO;
    self.savedNativeBarWindow=nil;
    self.savedNormalContentRect=CGRectNull;
    self.savedNormalScreenRect=CGRectNull;
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
