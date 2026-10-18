// MyTweak independent scene host for jailbroken iOS 16 SpringBoard.
// Experimental: SB/FrontBoard selectors are private and verified only at runtime.
// No vendor-license coupling or replacement for Apple authorization.
#import "MTSceneHost.h"
#import <objc/message.h>
#import <objc/runtime.h>
#import <math.h>
#import <fcntl.h>
#import <unistd.h>

NSString *const MTSceneHostDidFailNotification = @"com.mytweak.scene.failure";
static NSString *const MTSceneErrorDomain = @"com.mytweak.scene";

static void MTSceneLog(NSString *event, NSString *bundleID, NSString *detail) {
    NSString *line = [NSString stringWithFormat:@"[MyTweakScene] event=%@ bundle=%@ %@",
                      event ?: @"unknown", bundleID ?: @"-", detail ?: @""];
    NSLog(@"%@", line);
    // One short app-scoped diagnostic file for iPhone X testing; no secrets.
    int fd = open("/var/mobile/Library/Logs/MyTweakSceneHost.log",
                  O_WRONLY | O_APPEND | O_CREAT, 0644);
    if (fd >= 0) {
        NSData *data = [[line stringByAppendingString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding];
        (void)write(fd, data.bytes, data.length);
        close(fd);
    }
}
static NSError *MTError(NSInteger code, NSString *details) {
    return [NSError errorWithDomain:MTSceneErrorDomain code:code
                          userInfo:@{NSLocalizedDescriptionKey:details ?: @"Scene host unavailable"}];
}
static id MTCall0(id target, NSString *method) {
    SEL sel = NSSelectorFromString(method);
    return target && [target respondsToSelector:sel]
      ? ((id (*)(id, SEL))objc_msgSend)(target, sel) : nil;
}
static id MTCall1(id target, NSString *method, id arg) {
    SEL sel = NSSelectorFromString(method);
    return target && [target respondsToSelector:sel]
      ? ((id (*)(id, SEL, id))objc_msgSend)(target, sel, arg) : nil;
}
static void MTBool(id obj, NSString *method, BOOL value) {
    SEL sel = NSSelectorFromString(method);
    if (obj && [obj respondsToSelector:sel])
        ((void (*)(id, SEL, BOOL))objc_msgSend)(obj, sel, value);
}
static void MTInt(id obj, NSString *method, NSInteger value) {
    SEL sel = NSSelectorFromString(method);
    if (obj && [obj respondsToSelector:sel])
        ((void (*)(id, SEL, NSInteger))objc_msgSend)(obj, sel, value);
}

@class MTSceneSurface;
@interface MTSceneHost ()
@property(nonatomic,strong) NSMutableDictionary<NSString *,MTSceneSurface *> *live;
- (void)didFinishSurface:(MTSceneSurface *)surface;
@end

@interface MTSceneSurface : UIView
@property(nonatomic,copy) NSString *bundleID;
@property(nonatomic,strong) UIViewController *appController;
@property(nonatomic,strong) id entity;
@property(nonatomic,strong) id scene;
@property(nonatomic,strong) id sceneSettingsBefore;
@property(nonatomic,strong) NSTimer *timer;
@property(nonatomic,weak) UIViewController *parentController;
@property(nonatomic,weak) MTSceneHost *owner;
@property(nonatomic) BOOL started;
@property(nonatomic) BOOL stopped;
@property(nonatomic) BOOL ready;
@property(nonatomic) NSUInteger tries;
@property(nonatomic) CGSize lastApplied;
- (void)start;
- (void)layoutScene;
- (void)pollScene:(NSTimer *)timer;
- (void)stop;
- (void)failed:(NSError *)error;
@end

@implementation MTSceneSurface
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
    if (!parent) { [self failed:MTError(110, @"Không tìm thấy UIViewController chủ ô ứng dụng")]; return; }
    self.parentController = parent;
    @try {
        self.started = YES;
        [parent addChildViewController:self.appController];
        UIView *appView = self.appController.view;
        appView.clipsToBounds = YES;
        [self addSubview:appView];
        [self.appController didMoveToParentViewController:parent];
        MTBool(self.appController, @"setIgnoresOcclusions:", NO);
        MTBool(self.appController, @"setAutomatesLifecycle:", NO);
        [self layoutScene];
        [self.appController beginAppearanceTransition:YES animated:NO];
        MTInt(self.appController, @"setRequestedMode:", 2);
        [self.appController endAppearanceTransition];
        MTSceneLog(@"mode-2-requested",self.bundleID,NSStringFromCGRect(self.bounds));
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.35 target:self
                  selector:@selector(pollScene:) userInfo:nil repeats:YES];
        [self pollScene:self.timer];
    } @catch (NSException *e) {
        [self failed:MTError(111, [@"Scene attach exception: " stringByAppendingString:e.reason ?: @"unknown"])];
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
    if (CGSizeEqualToSize(size,self.lastApplied) && self.ready) return;
    // The independent QA reference and original v1.0.4 arithmetic both use 2x
    // source pixels and 0.5x host scale; must be confirmed on real iPhone X.
    CGSize logical=CGSizeMake(round(size.width*2),round(size.height*2));
    UIView *host=self.appController.view;
    host.transform=CGAffineTransformIdentity;
    host.frame=(CGRect){CGPointZero,logical};
    @try {
        id deviceController=[self.appController valueForKey:@"_deviceAppViewController"];
        SEL sz=NSSelectorFromString(@"setContentReferenceSize:withInterfaceOrientation:");
        SEL sz3=NSSelectorFromString(@"setContentReferenceSize:withContentOrientation:andContainerOrientation:");
        if ([deviceController respondsToSelector:sz])
            ((void (*)(id,SEL,CGSize,NSInteger))objc_msgSend)(deviceController,sz,logical,UIInterfaceOrientationPortrait);
        else if ([deviceController respondsToSelector:sz3])
            ((void (*)(id,SEL,CGSize,NSInteger,NSInteger))objc_msgSend)(deviceController,sz3,logical,UIInterfaceOrientationPortrait,UIInterfaceOrientationPortrait);
        UIView *inner=MTCall0(deviceController,@"view");
        if ([inner isKindOfClass:UIView.class] && inner!=host) {
            inner.transform=CGAffineTransformIdentity;
            inner.frame=(CGRect){CGPointZero,logical};
            inner.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        }
        MTInt(deviceController,@"setHomeGrabberDisplayMode:",1);
    } @catch (NSException *e) {
        MTSceneLog(@"geometry-warning",self.bundleID,e.reason);
    }
    host.transform=CGAffineTransformMakeScale(size.width/logical.width,size.height/logical.height);
    host.center=CGPointMake(size.width/2,size.height/2);
    if (self.scene) {
        @try {
            id settings=MTCall0(self.scene,@"mutableSettings");
            SEL setFrame=NSSelectorFromString(@"setFrame:");
            SEL update=NSSelectorFromString(@"updateSettings:withTransitionContext:completion:");
            if (settings && [settings respondsToSelector:setFrame] && [self.scene respondsToSelector:update]) {
                ((void (*)(id,SEL,CGRect))objc_msgSend)(settings,setFrame,(CGRect){CGPointZero,logical});
                MTBool(settings,@"setForeground:",YES);
                MTBool(settings,@"setBackgrounded:",NO);
                ((void (*)(id,SEL,id,id,id))objc_msgSend)(self.scene,update,settings,nil,nil);
            }
        } @catch (NSException *e) { MTSceneLog(@"scene-resize-warning",self.bundleID,e.reason); }
    }
    self.lastApplied=size;
    MTSceneLog(@"resize",self.bundleID,NSStringFromCGSize(size));
}
- (void)pollScene:(NSTimer *)timer {
    (void)timer;
    if (self.stopped) return;
    @try {
        id handle=MTCall0(self.appController,@"sceneHandle");
        id scene=MTCall0(handle,@"sceneIfExists");
        if (scene) {
            if (!self.scene) {
                self.scene=scene;
                self.sceneSettingsBefore=[MTCall0(scene,@"mutableSettings") copy];
                MTSceneLog(@"scene-attached",self.bundleID,NSStringFromClass([scene class]));
            }
            if (!self.ready) {
                self.ready=YES;
                self.lastApplied=CGSizeZero;
                [self layoutScene];
                MTSceneLog(@"scene-ready",self.bundleID,NSStringFromCGRect(self.bounds));
            }
            return;
        }
        if (++self.tries>=36) {
            [self failed:MTError(112,@"Hết thời gian chờ scene của ứng dụng trên CarPlay")];
        }
    } @catch (NSException *e) {
        [self failed:MTError(113, [@"Scene poll exception: " stringByAppendingString:e.reason?:@"unknown"])];
    }
}
- (void)failed:(NSError *)error {
    MTSceneLog(@"scene-failed",self.bundleID,error.localizedDescription);
    UIView *target=self;
    [self stop];
    [[NSNotificationCenter defaultCenter] postNotificationName:MTSceneHostDidFailNotification
                object:target userInfo:@{@"error":error}];
}
- (void)stop {
    if (self.stopped) return;
    self.stopped=YES;
    [self.timer invalidate]; self.timer=nil;
    @try {
        if (self.started) {
            [self.appController beginAppearanceTransition:NO animated:NO];
            [self.appController endAppearanceTransition];
            MTInt(self.appController,@"setRequestedMode:",0);
            [self.appController willMoveToParentViewController:nil];
            [self.appController.view removeFromSuperview];
            [self.appController removeFromParentViewController];
        }
    } @catch (NSException *e) { MTSceneLog(@"close-warning",self.bundleID,e.reason); }
    @try {
        SEL invalidate=NSSelectorFromString(@"invalidate");
        if ([self.appController respondsToSelector:invalidate])
            ((void (*)(id,SEL))objc_msgSend)(self.appController,invalidate);
        MTSceneLog(@"invalidate-done",self.bundleID,@"");
    } @catch (NSException *e) { MTSceneLog(@"invalidate-warning",self.bundleID,e.reason); }
    // Restore original scene background/foreground state where that API exists.
    @try {
        id settings=[self.sceneSettingsBefore mutableCopy];
        SEL update=NSSelectorFromString(@"updateSettings:withTransitionContext:completion:");
        if (settings && [self.scene respondsToSelector:update]) {
            MTBool(settings,@"setForeground:",NO);
            MTBool(settings,@"setBackgrounded:",YES);
            ((void (*)(id,SEL,id,id,id))objc_msgSend)(self.scene,update,settings,nil,nil);
            MTSceneLog(@"scene-settings-restored",self.bundleID,@"");
        }
    } @catch (NSException *e) { MTSceneLog(@"scene-restore-warning",self.bundleID,e.reason); }
    [self removeFromSuperview];
    [self.owner didFinishSurface:self];
    self.scene=nil; self.sceneSettingsBefore=nil; self.entity=nil; self.appController=nil;
}
@end

@implementation MTSceneHost
+ (instancetype)sharedHost {
    static MTSceneHost *shared=nil;
    static dispatch_once_t once;
    dispatch_once(&once,^{shared=[MTSceneHost new];});
    return shared;
}
- (instancetype)init {
    if ((self=[super init])) _live=[NSMutableDictionary dictionary];
    return self;
}
- (UIView *)hostViewForBundleID:(NSString *)bundleID error:(NSError **)error {
    if (![NSThread isMainThread] || ![NSProcessInfo.processInfo.processName isEqualToString:@"SpringBoard"]) {
        if (error) *error=MTError(101,@"Host phải chạy trên luồng chính SpringBoard");
        return nil;
    }
    if (![bundleID isKindOfClass:NSString.class] || bundleID.length==0) {
        if (error) *error=MTError(102,@"bundleID không hợp lệ");
        return nil;
    }
    if (self.live[bundleID]) {
        if (error) *error=MTError(103,@"Ứng dụng đã có ở một ô khác");
        return nil;
    }
    Class controllerClass=NSClassFromString(@"SBAppViewController");
    Class entityClass=NSClassFromString(@"SBDeviceApplicationSceneEntity");
    id registry=MTCall0(NSClassFromString(@"SBApplicationController"),@"sharedInstance");
    id app=MTCall1(registry,@"applicationWithBundleIdentifier:",bundleID);
    SEL entityInit=NSSelectorFromString(@"initWithApplicationForMainDisplay:");
    SEL entityFactory=NSSelectorFromString(@"newEntityWithApplicationForMainDisplay:");
    SEL controllerInit=NSSelectorFromString(@"initWithIdentifier:andApplicationSceneEntity:");
    NSMutableArray *missing=[NSMutableArray array];
    if (!app) [missing addObject:@"SBApplicationController.app missing"];
    if (!entityClass || (![entityClass instancesRespondToSelector:entityInit] && ![entityClass respondsToSelector:entityFactory]))
        [missing addObject:@"SBDeviceApplicationSceneEntity init/factory missing"];
    if (!controllerClass || ![controllerClass instancesRespondToSelector:controllerInit] ||
        ![controllerClass instancesRespondToSelector:NSSelectorFromString(@"setRequestedMode:")] ||
        ![controllerClass instancesRespondToSelector:NSSelectorFromString(@"invalidate")])
        [missing addObject:@"SBAppViewController host API missing"];
    if (missing.count) {
        NSString *reason=[missing componentsJoinedByString:@", "];
        MTSceneLog(@"preflight-failed",bundleID,reason);
        if (error) *error=MTError(104,reason);
        return nil;
    }
    @try {
        id entity=[entityClass instancesRespondToSelector:entityInit]
            ? ((id(*)(id,SEL,id))objc_msgSend)([entityClass alloc],entityInit,app)
            : ((id(*)(id,SEL,id))objc_msgSend)(entityClass,entityFactory,app);
        UIViewController *controller=((id(*)(id,SEL,id,id))objc_msgSend)([controllerClass alloc],controllerInit,bundleID,entity);
        if (!entity || !controller) {
            if (error) *error=MTError(105,@"Không tạo được đối tượng scene host");
            return nil;
        }
        [controller loadViewIfNeeded];
        MTSceneSurface *view=[MTSceneSurface new];
        view.bundleID=bundleID; view.entity=entity; view.appController=controller; view.owner=self;
        view.backgroundColor=UIColor.blackColor;
        view.clipsToBounds=YES;
        self.live[bundleID]=view;
        MTSceneLog(@"host-created",bundleID,@"pending-window-attach");
        return view;
    } @catch (NSException *e) {
        MTSceneLog(@"host-exception",bundleID,e.reason);
        if (error) *error=MTError(106,e.reason);
        return nil;
    }
}
- (void)didFinishSurface:(MTSceneSurface *)surface {
    if (self.live[surface.bundleID]==surface) [self.live removeObjectForKey:surface.bundleID];
}
- (void)releaseHostedView:(UIView *)view {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self releaseHostedView:view]; });
        return;
    }
    if ([view isKindOfClass:MTSceneSurface.class]) [(MTSceneSurface *)view stop];
}
- (void)stopAllHosts {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self stopAllHosts]; });
        return;
    }
    for (MTSceneSurface *surface in [self.live.allValues copy]) [surface stop];
    MTSceneLog(@"all-hosts-stopped",nil,@"");
}
@end
