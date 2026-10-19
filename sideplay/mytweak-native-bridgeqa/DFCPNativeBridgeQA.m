// DuoFace's independent, reversible, opt-in interprocess CarPlay experiment.
// No fake Dock, no SpringBoard entitlement spoof, no LS hooks, no window create.
// V1BC retains ownership of TWO iPhone scenes. This module mirrors an independent
// raster surface (not the original layer), so it NEVER steals UIKit's layer.
#import "DFCPNativeBridgeQA.h"
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
@property(nonatomic,strong) CALayer *mirrorLayer;
@property(nonatomic,weak) UIViewController *currentRoot;
@property(nonatomic,weak) UIWindow *currentWindow;
@property(nonatomic,assign) CGPoint tapDown;
@property(nonatomic,assign) BOOL pointerDown;
@property(nonatomic,assign) NSTimeInterval lastImageTime;
@property(nonatomic,assign) NSUInteger ticks;
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
    DFQAWrite(@"start",@"disabled-by-default; no window creation");
    self.timer=[NSTimer scheduledTimerWithTimeInterval:1.0 target:self
                     selector:@selector(tick) userInfo:nil repeats:YES];
}
- (void)stopPublisher {
    [self.relay stop];self.relay=nil;
    [self.publisher invalidate];self.publisher=nil;
    self.mirrorLayer=nil;self.currentRoot=nil;self.currentWindow=nil;
    self.pointerDown=NO;self.lastImageTime=0;
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
        [button sendActionsForControlEvents:UIControlEventTouchUpInside];
        DFQAWrite(@"menu-tap",title);
    } else if([@[@"swap",@"split",@"zoom",@"close"] containsObject:action]) {
        SEL sel=NSSelectorFromString([@{@"swap":@"swapApps",
            @"split":@"toggleSplit",@"zoom":@"toggleZoom",
            @"close":@"closeTrial"} objectForKey:action]);
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
        }
    }
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
        if(self.publisher)[self stopPublisher];
        if(self.owner.attached)[self.owner detach];
        return;
    }
    NSString *process=NSProcessInfo.processInfo.processName;
    if([process isEqualToString:@"SpringBoard"]) [self tickSpringBoard];
    else if([process isEqualToString:@"CarPlay"] ||
            [process isEqualToString:@"CarPlayApp"]) [self tickCarPlay];
}
@end
