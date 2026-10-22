// Independently maintained first-party DuoFace module, ported from the
// project's own prior scene-host experiments; no vendor binary or license.
// DuoFace independent scene host for jailbroken iOS 16 SpringBoard.
// Experimental: SB/FrontBoard selectors are private and verified only at runtime.
// No vendor-licensed application bridge or entitlement overrides.
#import "DFSceneHost.h"
#import <objc/message.h>
#import <objc/runtime.h>
#import <math.h>
#import <fcntl.h>
#import <unistd.h>

NSString *const DFSceneHostDidFailNotification = @"com.duoface.scene.failure";
NSString *const DFSceneHostDidBecomeReadyNotification = @"com.duoface.scene.ready";
static NSString *const DFSceneErrorDomain = @"com.duoface.scene";

static void DFSceneLog(NSString *event, NSString *bundleID, NSString *detail) {
    NSString *line = [NSString stringWithFormat:@"[DuoFaceScene] event=%@ bundle=%@ %@",
                      event ?: @"unknown", bundleID ?: @"-", detail ?: @""];
    NSLog(@"%@", line);
    // One short app-scoped diagnostic file for iPhone X testing; no secrets.
    int fd = open("/var/mobile/Library/Logs/DuoFaceSceneHost.log",
                  O_WRONLY | O_APPEND | O_CREAT, 0644);
    if (fd >= 0) {
        NSData *data = [[line stringByAppendingString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding];
        (void)write(fd, data.bytes, data.length);
        close(fd);
    }
}
static NSError *DFSceneError(NSInteger code, NSString *details) {
    return [NSError errorWithDomain:DFSceneErrorDomain code:code
                          userInfo:@{NSLocalizedDescriptionKey:details ?: @"Scene host unavailable"}];
}
static id DFCall0(id target, NSString *method) {
    SEL sel = NSSelectorFromString(method);
    return target && [target respondsToSelector:sel]
      ? ((id (*)(id, SEL))objc_msgSend)(target, sel) : nil;
}
static id DFCall1(id target, NSString *method, id arg) {
    SEL sel = NSSelectorFromString(method);
    return target && [target respondsToSelector:sel]
      ? ((id (*)(id, SEL, id))objc_msgSend)(target, sel, arg) : nil;
}
static void DFHostBool(id obj, NSString *method, BOOL value) {
    SEL sel = NSSelectorFromString(method);
    if (obj && [obj respondsToSelector:sel])
        ((void (*)(id, SEL, BOOL))objc_msgSend)(obj, sel, value);
}
// SBAppViewController exposes both canHostAnApp and isHostingAnApp on the
// public Theos headers. Guard the optional private selectors and do not
// infer live app hosting solely from a nonnil sceneHandle.
static BOOL DFHostingFlag(id target, NSString *method, BOOL fallback) {
    SEL sel=NSSelectorFromString(method);
    if(!target || ![target respondsToSelector:sel])return fallback;
    return ((BOOL(*)(id,SEL))objc_msgSend)(target,sel);
}
static void DFHostInt(id obj, NSString *method, NSInteger value) {
    SEL sel = NSSelectorFromString(method);
    if (obj && [obj respondsToSelector:sel])
        ((void (*)(id, SEL, NSInteger))objc_msgSend)(obj, sel, value);
}

@class DFSceneSurface;
@interface DFSceneHost ()
@property(nonatomic,strong) NSMutableDictionary<NSString *,DFSceneSurface *> *live;
- (void)didFinishSurface:(DFSceneSurface *)surface;
@end

@interface DFSceneSurface : UIView
@property(nonatomic,copy) NSString *bundleID;
@property(nonatomic,strong) UIViewController *appController;
@property(nonatomic,strong) id entity;
@property(nonatomic,strong) id scene;
@property(nonatomic,strong) id sceneSettingsBefore;
@property(nonatomic,strong) NSTimer *timer;
@property(nonatomic,weak) UIViewController *parentController;
@property(nonatomic,weak) DFSceneHost *owner;
@property(nonatomic) BOOL started;
@property(nonatomic) BOOL stopped;
@property(nonatomic) BOOL ready;
@property(nonatomic) NSUInteger tries;
@property(nonatomic) CGSize lastApplied;
// UIKit viewport moves immediately; remote media content-reference commits
// only after split/zoom stops changing, to avoid FrontBoard churn.
@property(nonatomic) CGSize pendingReferenceSize;
@property(nonatomic) CGSize committedReferenceSize;
@property(nonatomic,strong) NSTimer *geometryCommitTimer;
@property(nonatomic) NSTimeInterval lastViewportLogAt;
@property(nonatomic) NSTimeInterval lastHitLogAt;
- (void)start;
- (void)layoutScene;
- (void)commitSceneGeometry:(NSTimer *)timer;
- (void)pollScene:(NSTimer *)timer;
- (void)stop;
- (void)failed:(NSError *)error;
@end

@implementation DFSceneSurface
- (UIViewController *)findParentController {
    UIResponder *next = self.nextResponder;
    while (next) {
        if ([next isKindOfClass:UIViewController.class]) return (UIViewController *)next;
        next = next.nextResponder;
    }
    return nil;
}
- (void)didMoveToWindow {
    [super didMoveToWindow];
    if (self.window && !self.started && !self.stopped) [self start];
}
- (void)start {
    if (self.started || self.stopped) return;
    if (!self.window || CGRectIsEmpty(self.bounds)) {
        [self setNeedsLayout];
        return;
    }
    UIViewController *parent = [self findParentController];
    if (!parent) { [self failed:DFSceneError(110, @"Không tìm thấy UIViewController chủ ô ứng dụng")]; return; }
    self.parentController = parent;
    @try {
        self.started = YES;
        [parent addChildViewController:self.appController];
        UIView *appView = self.appController.view;
        appView.clipsToBounds = YES;
        [self addSubview:appView];
        [self.appController didMoveToParentViewController:parent];
        DFHostBool(self.appController, @"setIgnoresOcclusions:", NO);
        DFHostBool(self.appController, @"setAutomatesLifecycle:", NO);
        [self layoutScene];
        [self.appController beginAppearanceTransition:YES animated:NO];
        DFHostInt(self.appController, @"setRequestedMode:", 2);
        [self.appController endAppearanceTransition];
        DFSceneLog(@"mode-2-requested",self.bundleID,NSStringFromCGRect(self.bounds));
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.35 target:self
                  selector:@selector(pollScene:) userInfo:nil repeats:YES];
        [self pollScene:self.timer];
    } @catch (NSException *e) {
        [self failed:DFSceneError(111, [@"Scene attach exception: " stringByAppendingString:e.reason ?: @"unknown"])];
    }
}
- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.stopped) return;
    if (!self.started && self.window && !CGRectIsEmpty(self.bounds)) [self start];
    else if (self.started) [self layoutScene];
}
- (void)layoutScene {
    if (!self.started || self.stopped) return;
    CGSize size=self.bounds.size;
    if (size.width<=0 || size.height<=0 || !isfinite(size.width) || !isfinite(size.height)) return;
    if (CGSizeEqualToSize(size,self.lastApplied)) return;
    // A divider drag can produce dozens of intermediate frames. Scale the
    // existing UIKit scene immediately and leave the remote player intact.
    CGSize logical=CGSizeMake(round(size.width*2),round(size.height*2));
    UIView *host=self.appController.view;
    host.transform=CGAffineTransformIdentity;
    host.frame=(CGRect){CGPointZero,logical};
    host.transform=CGAffineTransformMakeScale(size.width/logical.width,size.height/logical.height);
    host.center=CGPointMake(size.width/2,size.height/2);
    self.lastApplied=size;
    NSTimeInterval now=NSDate.date.timeIntervalSince1970;
    if (now-self.lastViewportLogAt>0.5) {
        self.lastViewportLogAt=now;
        DFSceneLog(@"media-viewport-ui-only",self.bundleID,NSStringFromCGSize(size));
    }
    DFSceneLog(@"resize",self.bundleID,NSStringFromCGSize(size));
    if (!self.ready) return;
    self.pendingReferenceSize=size;
    [self.geometryCommitTimer invalidate];
    self.geometryCommitTimer=[NSTimer scheduledTimerWithTimeInterval:0.30
        target:self selector:@selector(commitSceneGeometry:) userInfo:nil repeats:NO];
}
- (void)commitSceneGeometry:(NSTimer *)timer {
    if (self.geometryCommitTimer!=timer) return;
    self.geometryCommitTimer=nil;
    if (self.stopped || !self.ready || !self.window || !self.appController) return;
    CGSize size=self.pendingReferenceSize;
    if (CGSizeEqualToSize(size,self.committedReferenceSize) ||
        !CGSizeEqualToSize(size,self.bounds.size) ||
        size.width<=0 || size.height<=0) return;
    CGSize logical=CGSizeMake(round(size.width*2),round(size.height*2));
    @try {
        id deviceController=[self.appController valueForKey:@"_deviceAppViewController"];
        // Readiness and stable-geometry gate. Do not guess orientation from
        // CarPlay aspect ratio; actual remote video orientation needs device
        // evidence before changing the portrait compatibility contract.
        SEL sz=NSSelectorFromString(@"setContentReferenceSize:withInterfaceOrientation:");
        SEL sz3=NSSelectorFromString(@"setContentReferenceSize:withContentOrientation:andContainerOrientation:");
        BOOL applied=NO;
        if ([deviceController respondsToSelector:sz]) {
            ((void (*)(id,SEL,CGSize,NSInteger))objc_msgSend)(deviceController,sz,
                             logical,UIInterfaceOrientationPortrait);
            applied=YES;
        } else if ([deviceController respondsToSelector:sz3]) {
            ((void (*)(id,SEL,CGSize,NSInteger,NSInteger))objc_msgSend)(deviceController,sz3,
                       logical,UIInterfaceOrientationPortrait,UIInterfaceOrientationPortrait);
            applied=YES;
        }
        UIView *inner=DFCall0(deviceController,@"view");
        if ([inner isKindOfClass:UIView.class] && inner!=self.appController.view) {
            inner.transform=CGAffineTransformIdentity;
            inner.frame=(CGRect){CGPointZero,logical};
            inner.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        }
        DFHostInt(deviceController,@"setHomeGrabberDisplayMode:",1);
        if (applied) {
            self.committedReferenceSize=size;
            DFSceneLog(@"media-reference-committed-after-stable-viewport",
                       self.bundleID,NSStringFromCGSize(size));
        } else {
            DFSceneLog(@"media-reference-abi-unavailable",self.bundleID,@"private resize selector unavailable");
        }
    } @catch (NSException *e) {
        DFSceneLog(@"media-geometry-commit-warning",self.bundleID,e.reason);
    }
    // Never fake a nil FrontBoard transition or invalidate a playing scene
    // as a stand-in for a valid media rotation state change.
    DFSceneLog(@"native-app-geometry-reference-only-no-nil-frontboard-transition",
               self.bundleID,NSStringFromCGSize(size));
}
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *target=[super hitTest:point withEvent:event];
    // Passive routing observation only; do not steal gestures from the player.
    if (self.ready && target && event && event.type==UIEventTypeTouches) {
        NSTimeInterval now=NSDate.date.timeIntervalSince1970;
        if (now-self.lastHitLogAt>0.8) {
            self.lastHitLogAt=now;
            DFSceneLog(@"media-pane-hit-test-target",
                       self.bundleID,NSStringFromClass(target.class));
        }
    }
    return target;
}
- (void)pollScene:(NSTimer *)timer {
    (void)timer;
    if (self.stopped) return;
    @try {
        id handle=DFCall0(self.appController,@"sceneHandle");
        id scene=DFCall0(handle,@"sceneIfExists");
        // The scene handle can exist before hosting begins. For an
        // implementation which exposes isHostingAnApp, require BOTH.
        // A sceneHandle may exist even when no remote app content is hosted.
        // Fail closed if the private capability is missing or the host has
        // not been attached to THIS CarPlay app container's window.
        // This is a readiness safety gate, NOT a media crash fix.
        BOOL supportsHosting=[self.appController respondsToSelector:
                                       NSSelectorFromString(@"isHostingAnApp")];
        BOOL isHosting=DFHostingFlag(self.appController,@"isHostingAnApp",NO);
        BOOL viewAttached=(self.appController.view.window!=nil &&
                           self.appController.view.window==self.window);
        if(scene && supportsHosting && isHosting && viewAttached) {
            if (!self.scene) {
                self.scene=scene;
                self.sceneSettingsBefore=[DFCall0(scene,@"mutableSettings") copy];
                DFSceneLog(@"scene-attached",self.bundleID,NSStringFromClass([scene class]));
            }
            if (!self.ready) {
                self.ready=YES;
                self.lastApplied=CGSizeZero;
                self.committedReferenceSize=CGSizeZero;
                [self layoutScene];
                DFSceneLog(@"scene-handle-observed-render-unverified",self.bundleID,NSStringFromCGRect(self.bounds));
                [[NSNotificationCenter defaultCenter] postNotificationName:DFSceneHostDidBecomeReadyNotification object:self userInfo:@{@"bundleID":self.bundleID?:@""}];
            }
            return;
        }
        ++self.tries;
        if(self.tries==3 || self.tries==10 || self.tries==25){
            DFSceneLog(@"scene-awaiting-real-host",self.bundleID,
                [NSString stringWithFormat:
                    @"handle=%d supportsHosting=%d hosting=%d windowAttached=%d attempts=%lu",
                    scene!=nil,supportsHosting,isHosting,viewAttached,
                    (unsigned long)self.tries]);
        }
        if (self.tries>=36) {
            DFSceneLog(@"scene-host-timeout",self.bundleID,
                  [NSString stringWithFormat:
                    @"handle=%d supportsHosting=%d hosting=%d windowAttached=%d",
                    scene!=nil,supportsHosting,isHosting,viewAttached]);
            [self failed:DFSceneError(112,@"Hết thời gian chờ scene và host ứng dụng thật")];
        }
    } @catch (NSException *e) {
        [self failed:DFSceneError(113,[@"Scene poll exception: " stringByAppendingString:e.reason?:@"unknown"])];
    }
}
- (void)failed:(NSError *)error {
    DFSceneLog(@"scene-failed",self.bundleID,error.localizedDescription);
    UIView *target=self;
    [self stop];
    [[NSNotificationCenter defaultCenter] postNotificationName:DFSceneHostDidFailNotification
                object:target userInfo:@{@"error":error}];
}
- (void)stop {
    if (self.stopped) return;
    self.stopped=YES;
    [self.timer invalidate]; self.timer=nil;
    [self.geometryCommitTimer invalidate]; self.geometryCommitTimer=nil;
    @try {
        if (self.started) {
            [self.appController beginAppearanceTransition:NO animated:NO];
            [self.appController endAppearanceTransition];
            DFHostInt(self.appController,@"setRequestedMode:",0);
            [self.appController willMoveToParentViewController:nil];
            [self.appController.view removeFromSuperview];
            [self.appController removeFromParentViewController];
        }
    } @catch (NSException *e) { DFSceneLog(@"close-warning",self.bundleID,e.reason); }
    @try {
        SEL invalidate=NSSelectorFromString(@"invalidate");
        if ([self.appController respondsToSelector:invalidate])
            ((void (*)(id,SEL))objc_msgSend)(self.appController,invalidate);
        DFSceneLog(@"invalidate-done",self.bundleID,@"");
    } @catch (NSException *e) { DFSceneLog(@"invalidate-warning",self.bundleID,e.reason); }
    // Do not send a fabricated/nil FrontBoard transition context during close.
    // Request mode 0 + invalidate above; iPhone exitmode crash risk is monitored.
    DFSceneLog(@"close-no-private-settings-restore",self.bundleID,@"");

    [self removeFromSuperview];
    [self.owner didFinishSurface:self];
    self.scene=nil; self.sceneSettingsBefore=nil; self.entity=nil; self.appController=nil;
}
@end

@implementation DFSceneHost
+ (instancetype)sharedHost {
    static DFSceneHost *shared=nil;
    static dispatch_once_t once;
    dispatch_once(&once,^{shared=[DFSceneHost new];});
    return shared;
}
- (instancetype)init {
    if ((self=[super init])) _live=[NSMutableDictionary dictionary];
    return self;
}
- (UIView *)hostViewForBundleID:(NSString *)bundleID error:(NSError **)error {
    if (![NSThread isMainThread] || ![NSProcessInfo.processInfo.processName isEqualToString:@"SpringBoard"]) {
        if (error) *error=DFSceneError(101,@"Host phải chạy trên luồng chính SpringBoard");
        return nil;
    }
    if (![bundleID isKindOfClass:NSString.class] || bundleID.length==0) {
        if (error) *error=DFSceneError(102,@"bundleID không hợp lệ");
        return nil;
    }
    if (self.live[bundleID]) {
        if (error) *error=DFSceneError(103,@"Ứng dụng đã có ở một ô khác");
        return nil;
    }
    Class controllerClass=NSClassFromString(@"SBAppViewController");
    Class entityClass=NSClassFromString(@"SBDeviceApplicationSceneEntity");
    id registry=DFCall0(NSClassFromString(@"SBApplicationController"),@"sharedInstance");
    id app=DFCall1(registry,@"applicationWithBundleIdentifier:",bundleID);
    SEL entityInit=NSSelectorFromString(@"initWithApplicationForMainDisplay:");
    SEL entityFactory=NSSelectorFromString(@"newEntityWithApplicationForMainDisplay:");
    SEL controllerInit=NSSelectorFromString(@"initWithIdentifier:andApplicationSceneEntity:");
    NSMutableArray *missing=[NSMutableArray array];
    if (!app) [missing addObject:@"SBApplicationController.app missing"];
    if (!entityClass || (![entityClass instancesRespondToSelector:entityInit] && ![entityClass respondsToSelector:entityFactory]))
        [missing addObject:@"SBDeviceApplicationSceneEntity init/factory missing"];
    if (!controllerClass || ![controllerClass instancesRespondToSelector:controllerInit] ||
        ![controllerClass instancesRespondToSelector:NSSelectorFromString(@"setRequestedMode:")] ||
        ![controllerClass instancesRespondToSelector:NSSelectorFromString(@"canHostAnApp")] ||
        ![controllerClass instancesRespondToSelector:NSSelectorFromString(@"isHostingAnApp")] ||
        ![controllerClass instancesRespondToSelector:NSSelectorFromString(@"invalidate")])
        [missing addObject:@"SBAppViewController host API missing"];
    if (missing.count) {
        NSString *reason=[missing componentsJoinedByString:@", "];
        DFSceneLog(@"preflight-failed",bundleID,reason);
        if (error) *error=DFSceneError(104,reason);
        return nil;
    }
    @try {
        id entity=[entityClass instancesRespondToSelector:entityInit]
            ? ((id(*)(id,SEL,id))objc_msgSend)([entityClass alloc],entityInit,app)
            : ((id(*)(id,SEL,id))objc_msgSend)(entityClass,entityFactory,app);
        UIViewController *controller=((id(*)(id,SEL,id,id))objc_msgSend)([controllerClass alloc],controllerInit,bundleID,entity);
        if (!entity || !controller) {
            if (error) *error=DFSceneError(105,@"Không tạo được đối tượng scene host");
            return nil;
        }
        [controller loadViewIfNeeded];
        // Never assume hosting capability YES when a private selector is absent.
        if(!DFHostingFlag(controller,@"canHostAnApp",NO)){
            DFSceneLog(@"host-preflight-denied",bundleID,@"SBAppViewController.canHostAnApp=NO");
            if(error)*error=DFSceneError(107,@"SBAppViewController không thể host ứng dụng này");
            return nil;
        }
        DFSceneSurface *view=[DFSceneSurface new];
        view.bundleID=bundleID; view.entity=entity; view.appController=controller; view.owner=self;
        // The CarPlay renderer should never display a fake black app tile
        // while FrontBoard is still negotiating a real app scene.
        view.backgroundColor=UIColor.clearColor;
        view.clipsToBounds=YES;
        self.live[bundleID]=view;
        DFSceneLog(@"host-created",bundleID,@"pending-window-attach");
        return view;
    } @catch (NSException *e) {
        DFSceneLog(@"host-exception",bundleID,e.reason);
        if (error) *error=DFSceneError(106,e.reason);
        return nil;
    }
}
- (NSString *)bundleIDForHostedView:(UIView *)view {
    if (![view isKindOfClass:DFSceneSurface.class])return nil;
    DFSceneSurface *surface=(DFSceneSurface *)view;
    // Only return identities of actual owned surfaces; do not accept
    // arbitrary views or allow a scene from another process to be replaced.
    return self.live[surface.bundleID]==surface ? surface.bundleID : nil;
}
- (void)didFinishSurface:(DFSceneSurface *)surface {
    if (self.live[surface.bundleID]==surface) [self.live removeObjectForKey:surface.bundleID];
}
- (void)releaseHostedView:(UIView *)view {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self releaseHostedView:view]; });
        return;
    }
    if ([view isKindOfClass:DFSceneSurface.class]) [(DFSceneSurface *)view stop];
}
- (void)stopAllHosts {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self stopAllHosts]; });
        return;
    }
    for (DFSceneSurface *surface in [self.live.allValues copy]) [surface stop];
    DFSceneLog(@"all-hosts-stopped",nil,@"");
}
@end
