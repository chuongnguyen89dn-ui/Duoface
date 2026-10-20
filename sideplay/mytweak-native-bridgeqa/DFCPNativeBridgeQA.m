// DuoFace's independent, reversible, opt-in interprocess CarPlay experiment.
// No fake Dock, no SpringBoard entitlement spoof, no LS hooks, no window create.
// V1BC retains ownership of TWO iPhone scenes. This module mirrors an independent
// raster surface (not the original layer), so it NEVER steals UIKit's layer.
#import "DFCPNativeBridgeQA.h"
#import "DFNativeSidebarTrial.h"
#import "../mytweak-independent-v1a/prototype/MTCPBridgeContract.h"
#import "../mytweak-independent-v1a/prototype/MTCPCommandRelay.h"
#import "../mytweak-independent-v1a/prototype/MTCPRemoteLayer.h"
#import "../mytweak-independent-v1a/prototype/MTCPDashboardOwner.h"
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <fcntl.h>
#import <unistd.h>
#import <math.h>

static void DFQAWrite(NSString *event, NSString *detail) {
    NSString *s=[NSString stringWithFormat:@"[DuoFaceNativeBridgeQA] %@ %@\n",event?:@"-",detail?:@""];
    NSLog(@"%@",s);
    const char *path="/var/mobile/Library/Logs/DuoFaceNativeBridgeQA.log";
    int fd=open(path,O_WRONLY|O_APPEND|O_CREAT,0644);
    if(fd>=0){ NSData *d=[s dataUsingEncoding:NSUTF8StringEncoding];
        (void)write(fd,d.bytes,d.length);close(fd); }
}
static id DFQAObj0(id target,SEL sel) {
    if(!target || ![target respondsToSelector:sel])return nil;
    Method m=class_isMetaClass(object_getClass(target))?
       class_getClassMethod((Class)target,sel):
       class_getInstanceMethod(object_getClass(target),sel);
    char encoding[16]={0};
    if(!m)return nil;
    method_getReturnType(m,encoding,sizeof(encoding));
    if(encoding[0]!='@')return nil;
    @try{return ((id(*)(id,SEL))objc_msgSend)(target,sel);}
    @catch(NSException *ex){DFQAWrite(@"getter-exception",ex.name);return nil;}
}
static BOOL DFQAWindowIsGood(UIWindow *w) {
    return w && [w isKindOfClass:UIWindow.class] && !w.hidden &&
      w.rootViewController && w.screen && w.screen!=UIScreen.mainScreen &&
      CGRectGetWidth(w.bounds)>200 && CGRectGetHeight(w.bounds)>120;
}
static BOOL DFQAValidRoot(UIViewController *root) {
    return root && [NSStringFromClass(root.class) isEqualToString:@"MTBridgeRootViewController"] &&
           root.isViewLoaded && root.view.window;
}
@interface DFCPNativeBridgeQA ()
@property(nonatomic,strong) NSTimer *timer;
@property(nonatomic,strong) MTCPRemoteLayerProducer *publisher;
@property(nonatomic,strong) MTCPCommandRelay *relay;
@property(nonatomic,strong) MTCPDashboardOwner *owner;
@property(nonatomic,strong) DFNativeSidebarTrial *sidebarTrial;
@property(nonatomic,strong) CALayer *mirrorLayer;
@property(nonatomic,weak) UIViewController *currentRoot;
@property(nonatomic,weak) UIWindow *currentWindow;
@property(nonatomic,assign) CGPoint tapDown;
@property(nonatomic,assign) BOOL pointerDown;
@property(nonatomic,assign) NSTimeInterval lastImageTime;
@property(nonatomic,assign) NSUInteger ticks;
// Crop only the SpringBoard-owned live source UIWindow, not the rendered image.
// CarPlay supplies a short-lived measured native content rectangle via ACK.
// Trial lasts <=45s and restores the original frame if we still own it.
@property(nonatomic,weak) UIWindow *yieldedSourceWindow;
@property(nonatomic,assign) CGRect savedSourceFrame;
@property(nonatomic,assign) CGRect expectedSourceFrame;
@property(nonatomic,copy) NSString *yieldSession;
@property(nonatomic,copy) NSString *exhaustedYieldSession;
@property(nonatomic,assign) NSTimeInterval yieldSince;
// CarPlay native geometry state; not split-pane focusSlot/zoom.
@property(nonatomic,assign) BOOL wholeHostFullscreen;
@end
@implementation DFCPNativeBridgeQA
+ (instancetype)shared {
    static DFCPNativeBridgeQA *instance;
    static dispatch_once_t once;
    dispatch_once(&once,^{instance=[self new];});
    return instance;
}
- (void)start {
    if(self.timer || !NSThread.isMainThread)return;
    NSString *process=NSProcessInfo.processInfo.processName;
    if(![@[@"SpringBoard",@"CarPlay",@"CarPlayApp"] containsObject:process])return;
    DFQAWrite(@"start",@"version=0.0.6~dockcrop1; trial=live-source-window-native-content-crop; no-automatic-UI");
    self.timer=[NSTimer scheduledTimerWithTimeInterval:1.0 target:self
                     selector:@selector(tick) userInfo:nil repeats:YES];
}
- (void)stopPublisher {
    [self restoreYieldedSourceWindow:@"publisher-stopped"];
    if (self.publisher.session)MTCPBridgeInvalidateHostFullscreen(self.publisher.session);
    self.wholeHostFullscreen=NO;
    [self.relay stop];self.relay=nil;
    [self.publisher invalidate];self.publisher=nil;
    self.mirrorLayer=nil;self.currentRoot=nil;self.currentWindow=nil;
    self.pointerDown=NO;self.lastImageTime=0;
}
- (void)toggleWholeHostFullscreen {
    NSString *session=self.publisher.session;
    if(!session || !MTCPBridgeExplicitOptIn())return;
    BOOL next=!self.wholeHostFullscreen;
    if(!MTCPBridgeWriteHostFullscreen(session,next)) {
        DFQAWrite(@"whole-host-geometry-command-rejected",@"live session required");
        return;
    }
    // Reflect remote Zoom back to the iPhone control app. The app is only
    // another user-authorized writer; the SpringBoard owner still owns scene.
    NSString *prefs=@"/var/mobile/Library/Preferences/com.duoface.mytweak.carplay-bridge.plist";
    NSMutableDictionary *cfg=[[NSDictionary dictionaryWithContentsOfFile:prefs] mutableCopy];
    if (!cfg)cfg=[NSMutableDictionary new];
    cfg[@"HostFullscreen"]=@(next);
    [cfg writeToFile:prefs atomically:YES];
    self.wholeHostFullscreen=next;
    DFQAWrite(@"whole-host-geometry-request",
       next?@"fullscreen-content+hide-native-chrome":@"normal-content+restore-native-chrome");
}
- (void)deliverPacket:(NSDictionary *)packet toRoot:(UIViewController *)root {
    if(!DFQAValidRoot(root) || !MTCPBridgeExplicitOptIn())return;
    NSString *action=packet[@"Action"];
    if([action isEqualToString:@"pointer"]) {
        NSString *phase=packet[@"Phase"];
        CGPoint p=CGPointMake([packet[@"X"] doubleValue],[packet[@"Y"] doubleValue]);
        if(!isfinite(p.x)||!isfinite(p.y)||p.x<0||p.x>1||p.y<0||p.y>1)return;
        if([phase isEqualToString:@"begin"]) {
            self.tapDown=p;self.pointerDown=YES;return;
        }
        if([phase isEqualToString:@"cancel"]) {self.pointerDown=NO;return;}
        if(![phase isEqualToString:@"end"] || !self.pointerDown)return;
        self.pointerDown=NO;
        if(hypot(p.x-self.tapDown.x,p.y-self.tapDown.y)>0.025)return;
        CGPoint pos=CGPointMake(CGRectGetWidth(root.view.bounds)*p.x,
                                 CGRectGetHeight(root.view.bounds)*p.y);
        UIView *hit=[root.view hitTest:pos withEvent:nil];
        // Do not replay touch to arbitrary iPhone app scenes. Only V1BC's
        // original FIVE already-wired menu buttons are safe to trigger.
        if(![hit isKindOfClass:UIButton.class])return;
        UIButton *button=(UIButton *)hit;
        NSString *title=button.currentTitle;
        if(![@[@"App",@"Split 2",@"Single",@"Swap",@"Zoom",@"Close"] containsObject:title])return;
        if(!button.enabled || button.hidden || button.alpha<0.95)return;
        // Native12 host Zoom is NOT CBBridgedSplitApp.focusSlot:.
        // In the native CarPlay receiver, route only this menu action to
        // whole-host bounds + chrome; leave source V1BC per-slot code intact.
        if([title isEqualToString:@"Zoom"]) {
            [self toggleWholeHostFullscreen];
            return;
        }
        [button sendActionsForControlEvents:UIControlEventTouchUpInside];
        DFQAWrite(@"menu-tap",title);
    } else if([@[@"swap",@"split",@"zoom",@"close"] containsObject:action]) {
        SEL sel=NSSelectorFromString([@{@"swap":@"swapApps",
            @"split":@"toggleSplit",@"zoom":@"toggleZoom",
            @"close":@"closeTrial"} objectForKey:action]);
        if([action isEqualToString:@"zoom"]) {
            [self toggleWholeHostFullscreen];
            return;
        }
        if([root respondsToSelector:sel]) {
            @try{((void(*)(id,SEL))objc_msgSend)(root,sel);
                 DFQAWrite(@"menu-command",action);}
            @catch(NSException *ex){DFQAWrite(@"command-rejected",ex.name);}
        }
    }
}
- (UIViewController *)activeV1BCRootWithWindow:(UIWindow * __autoreleasing *)outWindow {
    Class cls=NSClassFromString(@"MTBridgeCoordinator");
    id coordinator=DFQAObj0(cls,NSSelectorFromString(@"sharedCoordinator"));
    id raw=DFQAObj0(coordinator,NSSelectorFromString(@"bridgeWindow"));
    if(![raw isKindOfClass:UIWindow.class])return nil;
    UIWindow *w=(UIWindow *)raw;
    if(!DFQAWindowIsGood(w) || !DFQAValidRoot(w.rootViewController))return nil;
    if(outWindow)*outWindow=w;
    return w.rootViewController;
}
- (BOOL)capture:(UIViewController *)root {
    UIView *view=root.view;
    if(!view.window || CGRectGetWidth(view.bounds)>1400 ||
        CGRectGetHeight(view.bounds)>800)return NO;
    UIGraphicsBeginImageContextWithOptions(view.bounds.size,YES,1.0);
    BOOL ok=NO;
    @try{ ok=[view drawViewHierarchyInRect:view.bounds afterScreenUpdates:NO]; }
    @catch(NSException *ex){DFQAWrite(@"capture-exception",ex.name);}
    UIImage *snap=ok?UIGraphicsGetImageFromCurrentImageContext():nil;
    UIGraphicsEndImageContext();
    if(!snap.CGImage)return NO;
    self.mirrorLayer.contents=(__bridge id)snap.CGImage;
    self.mirrorLayer.contentsScale=1.0;
    self.mirrorLayer.bounds=(CGRect){CGPointZero,view.bounds.size};
    return YES;
}
// System owner in the user's native log: Dashboard UIWindowLevel=-1,
// DBStatusBarWindow level=0. V1BC's external window uses UIWindowLevelNormal
// (0), which may occlude native Dashboard chrome even after receiver attach.
// This two-phase, ACK-bounded test yields BELOW Dashboard root (-2), instead
// of changing Apple-owned windows or stealing iPhone app scene layers.
- (BOOL)sourceYieldExperimentEnabled {
    NSDictionary *cfg=[NSDictionary dictionaryWithContentsOfFile:
       @"/var/mobile/Library/Preferences/com.duoface.mytweak.carplay-bridge.plist"];
    return MTCPBridgeExplicitOptIn() &&
           [cfg[@"NativeSidebarTrial"] isKindOfClass:NSNumber.class] &&
           [cfg[@"NativeSidebarTrial"] boolValue];
}
// Use the already authenticated receiver-ACK geometry, never search for Dock
// inside SpringBoard's UIApplication.windows (native Dock is in CarPlay).
// A separate UIWindow can obscure native chrome even when its split UIView shrinks.
static BOOL DFQAFrameNear(CGRect a,CGRect b) {
    return fabs(a.origin.x-b.origin.x)<1.0 && fabs(a.origin.y-b.origin.y)<1.0 &&
           fabs(a.size.width-b.size.width)<1.0 && fabs(a.size.height-b.size.height)<1.0;
}
- (void)restoreYieldedSourceWindow:(NSString *)reason {
    UIWindow *w=self.yieldedSourceWindow;
    if(w && DFQAFrameNear(w.frame,self.expectedSourceFrame)) {
        @try {
            w.frame=self.savedSourceFrame;
            [w.rootViewController.view setNeedsLayout];
            DFQAWrite(@"source-window-crop-restored",
                [NSString stringWithFormat:@"reason=%@ frame=%@",reason,
                 NSStringFromCGRect(w.frame)]);
        } @catch(NSException *ex) {
            DFQAWrite(@"source-window-restore-exception",ex.name);
        }
    } else if(w) {
        DFQAWrite(@"source-window-restore-skipped",@"system-or-other-owner-changed-frame");
    }
    self.yieldedSourceWindow=nil;
    self.yieldSession=nil;
    self.yieldSince=0;
    self.savedSourceFrame=CGRectNull;
    self.expectedSourceFrame=CGRectNull;
}
- (void)tickNativeDashboardSourceYield:(UIWindow *)w {
    NSString *session=self.publisher.session;
    NSDictionary *ack=session?MTCPBridgeReadReceiverAck(session):nil;
    BOOL canTry=[self sourceYieldExperimentEnabled] && w && session && ack &&
                 !self.wholeHostFullscreen && w==self.currentWindow &&
                 !w.hidden && w.alpha>=0.95 && w.screen!=UIScreen.mainScreen &&
                 [w.rootViewController isKindOfClass:NSClassFromString(@"MTBridgeRootViewController")];
    if(self.yieldedSourceWindow) {
        BOOL expired=(NSDate.date.timeIntervalSince1970-self.yieldSince>45);
        BOOL changed=!DFQAFrameNear(self.yieldedSourceWindow.frame,self.expectedSourceFrame);
        if(!canTry || expired || changed || w!=self.yieldedSourceWindow ||
           ![session isEqualToString:self.yieldSession]) {
            if(self.yieldSession)self.exhaustedYieldSession=self.yieldSession;
            [self restoreYieldedSourceWindow:expired?@"45sec-lease-expired":
               changed?@"native-system-changed-frame":@"native-ack-or-mode-lost"];
        }
        return;
    }
    if(!canTry || [session isEqualToString:self.exhaustedYieldSession])return;
    // A live receiver authenticated both the actual native bar and its
    // drawable content bounds. ACK is *not* proof of Dock/Home functionality.
    double x=[ack[@"X"] doubleValue], y=[ack[@"Y"] doubleValue];
    double width=[ack[@"Width"] doubleValue],height=[ack[@"Height"] doubleValue];
    if(!isfinite(x)||!isfinite(y)||!isfinite(width)||!isfinite(height) ||
       x<0 || y<0 || x>0.30 || y>0.30 || width<0.70 || height<0.70 ||
       width>1 || height>1 || x+width>1.001 || y+height>1.001 ||
       (x<0.005 && y<0.005 && width>0.995 && height>0.995))return;
    CGRect original=w.frame;
    CGRect carBounds=w.screen.bounds;
    // Reject mismatched display units/orientation: never crop an unknown screen.
    if(!DFQAFrameNear(original,carBounds) ||
       fabs(w.windowLevel-UIWindowLevelNormal)>0.10)return;
    CGRect target=CGRectMake(original.origin.x+x*original.size.width,
       original.origin.y+y*original.size.height,
       width*original.size.width,height*original.size.height);
    if(!CGRectContainsRect(original,target) ||
       target.size.width<160 || target.size.height<80)return;
    @try {
        w.frame=target;
        if(!DFQAFrameNear(w.frame,target)) {
            // Reject unsupported root-scene window sizing and revert immediately.
            if(DFQAFrameNear(w.frame,original)==NO)w.frame=original;
            DFQAWrite(@"source-window-crop-rejected",@"external-root-window-did-not-accept-frame");
            self.exhaustedYieldSession=session;
            return;
        }
        self.savedSourceFrame=original;
        self.expectedSourceFrame=target;
        self.yieldedSourceWindow=w;
        self.yieldSession=[session copy];
        self.yieldSince=NSDate.date.timeIntervalSince1970;
        [w.rootViewController.view setNeedsLayout];
        DFQAWrite(@"source-window-cropped-after-native-ack",
            [NSString stringWithFormat:@"session=%@ original=%@ live=%@ level=%.2f max=45s",
               session,NSStringFromCGRect(original),NSStringFromCGRect(w.frame),
               (double)w.windowLevel]);
    } @catch(NSException *ex) {
        self.exhaustedYieldSession=session;
        DFQAWrite(@"source-window-crop-exception",ex.name);
        if(DFQAFrameNear(w.frame,target))w.frame=original;
    }
}
- (void)tickSpringBoard {
    UIWindow *w=nil;UIViewController *root=[self activeV1BCRootWithWindow:&w];
    if(!root) {
        if(self.publisher)[self stopPublisher];
        return;
    }
    if(self.publisher && (root!=self.currentRoot || w!=self.currentWindow)) {
        [self stopPublisher];return; // no reuse of a stale session
    }
    if(!self.publisher) {
        self.mirrorLayer=[CALayer layer];
        if(![self capture:root]){self.mirrorLayer=nil;return;}
        MTCPRemoteLayerProducer *publisher=[MTCPRemoteLayerProducer new];
        if(![publisher publishLayer:self.mirrorLayer
                      normalizedContentBounds:CGRectMake(0,0,1,1)]) {
            DFQAWrite(@"publisher-unavailable",@"CAContext missing/rejected");
            self.mirrorLayer=nil;return;
        }
        self.publisher=publisher;
        self.wholeHostFullscreen=NO;
        MTCPBridgeWriteHostFullscreen(publisher.session,NO);
        self.currentRoot=root;self.currentWindow=w;
        __weak typeof(self) weakSelf=self;
        MTCPCommandRelay *relay=[MTCPCommandRelay new];
        if(![relay startForSession:publisher.session handler:^(NSDictionary *packet) {
            typeof(self) strongSelf=weakSelf;
            UIViewController *live=strongSelf.currentRoot;
            if(strongSelf && live && strongSelf.publisher.session)
                [strongSelf deliverPacket:packet toRoot:live];
        }]) {
            [self stopPublisher];return;
        }
        self.relay=relay;
        DFQAWrite(@"publisher-connected",
          [NSString stringWithFormat:@"session=%@ size=%@",publisher.session,
                                      NSStringFromCGSize(root.view.bounds.size)]);
    }
    if(NSDate.date.timeIntervalSince1970-self.lastImageTime>0.4) {
        self.lastImageTime=NSDate.date.timeIntervalSince1970;
        if(![self capture:root]) {
            DFQAWrite(@"capture-failed",@"stopped safely");
            [self stopPublisher];
            return;
        }
    }
    // The visible DuoFace QA iPhone app sets Desired HostFullscreen in the
    // same preferences. Read it once per tick and send the existing session
    // lease to the Dashboard owner. Never reinterpret per-slot Zoom as host.
    id requested=[NSDictionary dictionaryWithContentsOfFile:
         @"/var/mobile/Library/Preferences/com.duoface.mytweak.carplay-bridge.plist"][@"HostFullscreen"];
    if([requested isKindOfClass:NSNumber.class] &&
       self.wholeHostFullscreen!=[requested boolValue]) {
        self.wholeHostFullscreen=[requested boolValue];
        DFQAWrite(@"qa-control-app-fullscreen-mode",
            self.wholeHostFullscreen?@"full-screen-requested":@"normal-requested");
    }
    if(self.publisher.session &&
       !MTCPBridgeWriteHostFullscreen(self.publisher.session,self.wholeHostFullscreen) &&
       self.ticks%30==0)
        DFQAWrite(@"whole-host-mode-lease-failed",@"no live publisher/bridge");
    [self tickNativeDashboardSourceYield:w];
}
- (UIViewController *)nativeDashboardRoot {
    NSUInteger inspected=0;
    for(UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if(![scene isKindOfClass:UIWindowScene.class] ||
           scene.activationState!=UISceneActivationStateForegroundActive)continue;
        for(UIWindow *w in ((UIWindowScene *)scene).windows) {
            if(++inspected>40)return nil;
            UIViewController *root=w.rootViewController;
            if(!root || w.hidden || !w.screen || w.screen==UIScreen.mainScreen)continue;
            if([NSStringFromClass(root.class) isEqualToString:@"DBDashboardRootViewController"])
                return root;
        }
    }
    return nil;
}
- (void)tickCarPlay {
    if(self.owner.attached) {
        NSNumber *mode=MTCPBridgeReadHostFullscreen(self.owner.receiverSession);
        BOOL requested=mode ? mode.boolValue : NO;
        if(self.owner.isHostFullscreen!=requested) {
            if([self.owner applyHostFullscreen:requested]) {
                DFQAWrite(@"native-host-geometry-applied",
                    [NSString stringWithFormat:@"mode=%@ content=%@",
                       requested?@"FULL-screen-no-insets":@"NORMAL-saved-insets",
                       NSStringFromCGRect(self.owner.activeContentRect)]);
            } else if(self.ticks%15==0) {
                DFQAWrite(@"native-host-geometry-rejected",
                          requested?@"enter-fullscreen":@"restore-normal");
            }
        }
    }
    if(!self.sidebarTrial)self.sidebarTrial=[DFNativeSidebarTrial new];
    [self.sidebarTrial tickWithSurface:MTCPBridgeReadSurface(nil)];
    if(self.owner.attached) {[self.owner refresh];return;}
    UIViewController *dashboard=[self nativeDashboardRoot];
    if(!dashboard)return;
    if(!self.owner)self.owner=[MTCPDashboardOwner new];
    if([self.owner attachToDashboardRoot:dashboard]) {
        DFQAWrite(@"native-receiver-attached",@"real Dashboard-owned viewport");
    } else if(self.ticks%30==0) {
        DFQAWrite(@"native-receiver-not-ready",
                  @"real system bar may still be offscreen; no fake Dock/overlay");
    }
}
- (void)tick {
    if(!NSThread.isMainThread)return;
    self.ticks++;
    if(!MTCPBridgeExplicitOptIn()) {
        [self restoreYieldedSourceWindow:@"explicit-opt-out"];
        if(self.publisher)[self stopPublisher];
        if(self.owner.attached)[self.owner detach];
        [self.sidebarTrial stop];
        return;
    }
    NSString *process=NSProcessInfo.processInfo.processName;
    if([process isEqualToString:@"SpringBoard"]) [self tickSpringBoard];
    else if([process isEqualToString:@"CarPlay"] ||
            [process isEqualToString:@"CarPlayApp"]) [self tickCarPlay];
}
@end
