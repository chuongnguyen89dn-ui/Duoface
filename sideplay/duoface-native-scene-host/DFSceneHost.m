#import "DFDeepTrace.h"
// .74: media host restored from nativehost .47 source 7cd4004d. Current touch wake retained.
// Independently maintained first-party DuoFace module, ported from the
// project's own prior scene-host experiments; no vendor binary or license.
// DuoFace independent scene host for jailbroken iOS 16 SpringBoard.
// Experimental: SB/FrontBoard selectors are private and verified only at runtime.
// No vendor-licensed application bridge or entitlement overrides.
#import "DFSceneHost.h"
#import "DFSceneLifecycle.h"
#import "DFSceneOrientationPolicy.h"
#import "DFHostedMapRenderSize.h"
#import <objc/message.h>
#import <objc/runtime.h>
#import <math.h>
#import <fcntl.h>
#import <unistd.h>

NSString *const DFSceneHostDidFailNotification = @"com.duoface.scene.failure";
NSString *const DFSceneHostDidBecomeReadyNotification = @"com.duoface.scene.ready";
NSString *const DFSceneHostDidObserveTouchNotification = @"com.duoface.scene.actual.touch";
static NSString *const DFSceneErrorDomain = @"com.duoface.scene";

static void DFSceneLog(NSString *event, NSString *bundleID, NSString *detail) {
    NSString *line = [NSString stringWithFormat:@"[DuoFaceScene] event=%@ bundle=%@ %@",
                      event ?: @"unknown", bundleID ?: @"-", detail ?: @""];
    DFDeepTrace(@"scene",line);
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

// Observation only. A scene's server-side foreground flag is not the same
// thing as UIWindow.hidden or the host controller's requested Live mode.
// Never write foreground, mutate private transition context or override
// SpringBoard's observer to silence a framework assertion.
static NSInteger DFObservedSceneForeground(id scene) {
    id settings=DFCall0(scene,@"settings");
    if(!settings)return -1;
    SEL flag=NSSelectorFromString(@"isForeground");
    if(![settings respondsToSelector:flag])
        flag=NSSelectorFromString(@"foreground");
    if(![settings respondsToSelector:flag])return -1;
    return ((BOOL(*)(id,SEL))objc_msgSend)(settings,flag)?1:0;
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
@property(nonatomic) BOOL layingOutScene;
@property(nonatomic) BOOL committingSceneGeometry;
@property(nonatomic) NSUInteger tries;
@property(nonatomic) NSUInteger sceneGeneration;
@property(nonatomic,weak) id policySceneHandle;
@property(nonatomic,weak) id policyDeviceController;
// -2 = new scene (no sample); -1 = selector not available; 0/1 = observed.
@property(nonatomic) NSInteger lastObservedForeground;
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
- (void)revokeOrientationPolicy;
- (void)registerOwnedOrientationForDeviceController:(id)deviceController;
- (void)pollScene:(NSTimer *)timer;
- (void)stop;
- (void)failed:(NSError *)error;
@end

@implementation DFSceneSurface
- (void)revokeOrientationPolicy {
    DFSceneOrientationPolicyUnregister(self.policySceneHandle,self.policyDeviceController);
    self.policySceneHandle=nil;
    self.policyDeviceController=nil;
}
// .85: initial remote-app owner and orientation need to agree before the
// first delayed geometry transaction. Native12 registration occurs at the
// qualified bridge scene boundary; a first-time fullscreen must not be the
// only event causing UIKit to evaluate direction. Only live owned scenes.
// When the host device controller arrives later, register its size setters.
- (void)registerOwnedOrientationForDeviceController:(id)deviceController {
    if(!NSThread.isMainThread || !self.ready || !self.scene || self.stopped ||
       !self.window || self.appController.viewIfLoaded.window!=self.window ||
       !DFHostingFlag(self.appController,@"isHostingAnApp",NO))return;
    id handle=DFCall0(self.appController,@"sceneHandle");
    if(!handle || DFCall0(handle,@"sceneIfExists")!=self.scene ||
       self.owner.live[self.bundleID]!=self)return;
    if(self.policySceneHandle && self.policySceneHandle!=handle)
        [self revokeOrientationPolicy];
    if(self.policyDeviceController && deviceController &&
       self.policyDeviceController!=deviceController)
        [self revokeOrientationPolicy];
    if(self.policySceneHandle==handle &&
       (!deviceController || self.policyDeviceController==deviceController))return;
    if(!DFSceneOrientationPolicyInstall())return;
    NSUInteger generation=self.sceneGeneration;
    id currentScene=self.scene;
    __weak typeof(self) weakOwner=self;
    DFSceneOrientationPolicyRegister(handle,deviceController,self.bundleID,^CGSize{
        DFSceneSurface *surface=weakOwner;
        if(!NSThread.isMainThread || !surface || surface.stopped ||
           !surface.started || !surface.ready ||
           surface.sceneGeneration!=generation || surface.scene!=currentScene ||
           !surface.window || surface.window.hidden ||
           surface.appController.viewIfLoaded.window!=surface.window ||
           !DFHostingFlag(surface.appController,@"isHostingAnApp",NO) ||
           DFCall0(surface.appController,@"sceneHandle")!=handle ||
           DFCall0(handle,@"sceneIfExists")!=currentScene ||
           surface.owner.live[surface.bundleID]!=surface)return CGSizeZero;
        return DFHostedLogicalSizeForBundle(surface.bounds.size,surface.bundleID);
    });
    self.policySceneHandle=handle;
    if(deviceController)self.policyDeviceController=deviceController;
    DFSceneLog(@"orientation-early-owned-registered",self.bundleID,
        [NSString stringWithFormat:@"generation=%lu handle=%p device=%p scale=%.2f",
            (unsigned long)generation,handle,deviceController,
            (double)DFHostedViewportScaleForBundle(self.bundleID)]);
}
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
        // UIKit containment is committed only after the native scene host has
        // selected Live. Native12 original start @0xae538 requests mode 2 and
        // only later completes didMoveToParentViewController: @0xaebf0.
        // This changes no geometry, UI, focus, dock or media orientation.
        // Native12 original start IMP 0xadf30, guarded call at 0xae450.
        DFHostBool(self.appController, @"setIgnoresOcclusions:", YES);
        DFHostBool(self.appController, @"setAutomatesLifecycle:", NO);
        [self layoutScene];
        // Defer initial remote scene frame until the real mode-2 owner
        // attaches; video layout still uses the original logical scale.
        self.pendingReferenceSize=self.bounds.size;
        // Perform initial media sizing only after the hosted scene is ready.
        __weak typeof(self) weakOwner=self;
        DFSceneLifecycleRegister(self.appController,^id{
            DFSceneSurface *surface=weakOwner;
            if(!surface || surface.stopped || !surface.started || !surface.window || surface.window.hidden ||
               surface.appController.viewIfLoaded.window!=surface.window)return nil;
            id current=DFCall0(DFCall0(surface.appController,@"sceneHandle"),@"sceneIfExists");
            // Reject a replaced scene until pollScene accepts its generation.
            if(surface.scene && surface.scene!=current)return nil;
            return current;
        });
        [self.appController beginAppearanceTransition:YES animated:NO];
        // Install guarded hook before requesting Live; never force a
        // nonowned process to portrait. Ownership registers on first poll.
        (void)DFSceneOrientationPolicyInstall();
        DFHostInt(self.appController, @"setRequestedMode:", 2);
        [self.appController didMoveToParentViewController:parent];
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
    if (!self.started || self.stopped || self.layingOutScene || self.committingSceneGeometry) return;
    CGSize size=self.bounds.size;
    if (size.width<=0 || size.height<=0 || !isfinite(size.width) || !isfinite(size.height)) return;
    if (CGSizeEqualToSize(size,self.lastApplied)) return;
    // A divider drag can produce dozens of intermediate frames. Scale the
    // existing UIKit scene immediately and leave the remote player intact.
    CGSize logical=DFHostedLogicalSizeForBundle(size,self.bundleID);
    if(logical.width<=0 || logical.height<=0)return;
    self.layingOutScene=YES;
    @try {
    UIView *host=self.appController.view;
    host.transform=CGAffineTransformIdentity;
    host.frame=(CGRect){CGPointZero,logical};
    host.transform=CGAffineTransformMakeScale(size.width/logical.width,size.height/logical.height);
    host.center=CGPointMake(size.width/2,size.height/2);
    self.lastApplied=size;
    } @finally { self.layingOutScene=NO; }
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
    if (timer && self.geometryCommitTimer!=timer) return;
    self.geometryCommitTimer=nil;
    if (self.stopped || self.committingSceneGeometry || !self.window || !self.appController ||
        !self.ready) return;
    CGSize size=self.pendingReferenceSize;
    if (CGSizeEqualToSize(size,self.committedReferenceSize) ||
        !CGSizeEqualToSize(size,self.bounds.size) ||
        size.width<=0 || size.height<=0) return;
    // Guard actual SpringBoard scene ownership before private geometry writes.
    // A reused SBAppViewController can swap sceneHandle after an app restart;
    // the old FBScene must never receive an updateSettingsWithBlock: request.
    if (self.ready) {
        id handle=DFCall0(self.appController,@"sceneHandle");
        id observedScene=DFCall0(handle,@"sceneIfExists");
        BOOL hosting=DFHostingFlag(self.appController,@"isHostingAnApp",NO);
        BOOL attached=(self.appController.view.window==self.window);
        if (!self.scene || observedScene!=self.scene || !hosting || !attached) {
            DFSceneLog(@"scene-geometry-stale-owner-skip",self.bundleID,
                [NSString stringWithFormat:@"sceneSame=%d hosting=%d attached=%d",
                    observedScene!=nil && observedScene==self.scene,hosting,attached]);
            return;
        }
    }
    CGSize logical=DFHostedLogicalSizeForBundle(size,self.bundleID);
    self.committingSceneGeometry=YES;
    DFSceneLog(@"geometry-before-reference-setters",self.bundleID,NSStringFromCGSize(size));
    @try {
        // Native12 original CBBridgedUIAppView.updateSceneSettingsFrame
        // IMP 0xad5bc: KVC exception handler adb18..adb94 performs
        // class_getInstanceVariable("_deviceAppViewController") + object_getIvar
        // then branches back to ad668 for the same guarded 2/3/main setters.
        // A KVC failure must not abort all viewport commits.
        id deviceController=nil;
        @try {
            deviceController=[self.appController valueForKey:@"_deviceAppViewController"];
        } @catch (NSException *kvcError) {
            DFSceneLog(@"original-native12-kvc-ivar-fallback",self.bundleID,kvcError.name);
            Ivar deviceIvar=class_getInstanceVariable([self.appController class],
                                                      "_deviceAppViewController");
            if (deviceIvar) deviceController=object_getIvar(self.appController,deviceIvar);
        }
        // The .85 policy was installed BEFORE mode-2 request and registered
        // at first owned scene readiness; add the device controller when
        // discovered. Geometry-only commits do not toggle ownership.
        [self registerOwnedOrientationForDeviceController:deviceController];
        // Readiness and stable-geometry gate. Do not guess orientation from
        // CarPlay aspect ratio; actual remote video orientation needs device
        // evidence before changing the portrait compatibility contract.
        SEL sz=NSSelectorFromString(@"setContentReferenceSize:withInterfaceOrientation:");
        SEL sz3=NSSelectorFromString(@"setContentReferenceSize:withContentOrientation:andContainerOrientation:");
        // Original Native12 CBBridgedUIAppView.updateSceneSettingsFrame
        // IMP 0xad5bc: two INDEPENDENT child selector guards (ad688/ad6bc),
        // followed by a separate main-controller guard (ad6ec). All original
        // orientations are 1 (Portrait). This changes only the verified
        // sizing selector dispatch; NO speculative scene settings block.
        BOOL child2Applied=NO,child3Applied=NO,main2Applied=NO;
        if (deviceController && [deviceController respondsToSelector:sz]) {
            ((void (*)(id,SEL,CGSize,NSInteger))objc_msgSend)(deviceController,sz,
                             logical,UIInterfaceOrientationPortrait);
            child2Applied=YES;
        }
        if (deviceController && [deviceController respondsToSelector:sz3]) {
            ((void (*)(id,SEL,CGSize,NSInteger,NSInteger))objc_msgSend)(deviceController,sz3,
                       logical,UIInterfaceOrientationPortrait,UIInterfaceOrientationPortrait);
            child3Applied=YES;
        }
        if (self.appController && [self.appController respondsToSelector:sz]) {
            ((void (*)(id,SEL,CGSize,NSInteger))objc_msgSend)(self.appController,sz,
                             logical,UIInterfaceOrientationPortrait);
            main2Applied=YES;
        }
        BOOL applied=child2Applied||child3Applied||main2Applied;
        DFSceneLog(@"original-native12-scene-size-dispatch",self.bundleID,
           [NSString stringWithFormat:@"child2=%d child3=%d main2=%d",child2Applied,child3Applied,main2Applied]);
        UIView *inner=DFCall0(deviceController,@"view");
        if ([inner isKindOfClass:UIView.class] && inner!=self.appController.view) {
            inner.transform=CGAffineTransformIdentity;
            inner.frame=(CGRect){CGPointZero,logical};
            inner.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        }
        DFHostInt(deviceController,@"setHomeGrabberDisplayMode:",1);
        // Original Native12 updateSceneSettingsFrame@ad5bc constructs the
        // settings block at adaa8 (invoke 0xadc74), then calls the REAL hosted
        // scene's updateSettingsWithBlock: at adacc. The invoke uses x1 as
        // settings; adcb4..adcc8 sets CGRect origin (0,0) and logical size.
        // .77 device fatal evidence: Live host got foreground=NO.
        // Original independent bridges set foreground/background with frame.
        // .81 tests guarded foreground contract in this SAME transaction;
        // never force lock, idle, occlusion, orientation or app viewport.
        if (self.ready && self.scene) {
            id hostedScene=self.scene;
            SEL update=NSSelectorFromString(@"updateSettingsWithBlock:");
            if ([hostedScene respondsToSelector:update]) {
                CGRect nativeFrame=CGRectMake(0,0,logical.width,logical.height);
                // Compare the current remote frame before submitting a duplicate
                // scene settings update. A differing frame remains writable.
                BOOL unchanged=NO;
                id remoteSettings=DFCall0(hostedScene,@"settings");
                SEL readFrame=NSSelectorFromString(@"frame");
                if (remoteSettings && [remoteSettings respondsToSelector:readFrame]) {
                    CGRect observed=((CGRect (*)(id,SEL))objc_msgSend)(remoteSettings,readFrame);
                    unchanged=CGRectEqualToRect(observed,nativeFrame);
                    DFSceneLog(@"scene-frame-readback",self.bundleID,
                        [NSString stringWithFormat:@"actual=%@ target=%@ same=%d",
                         NSStringFromCGRect(observed),NSStringFromCGRect(nativeFrame),unchanged]);
                }
                NSUInteger generation=self.sceneGeneration;
                __weak typeof(self) weakSurface=self;
                void (^setVerifiedNative12Frame)(id)=^(id settings) {
                    DFSceneSurface *surface=weakSurface;
                    if (!surface || surface.stopped || !surface.ready ||
                        surface.sceneGeneration!=generation || surface.scene!=hostedScene ||
                        DFCall0(DFCall0(surface.appController,@"sceneHandle"),@"sceneIfExists")!=hostedScene ||
                        !DFHostingFlag(surface.appController,@"isHostingAnApp",NO) ||
                        !surface.window || surface.appController.view.window!=surface.window) return;
                    SEL frameSelector=NSSelectorFromString(@"setFrame:");
                    if (settings && [settings respondsToSelector:frameSelector]) {
                        ((void (*)(id,SEL,CGRect))objc_msgSend)(
                            settings,frameSelector,nativeFrame);
                    }
                    // Original independent DuoNavi/OmniCar ARM64 sources guard
                    // foreground/background setters in a Live scene transaction.
                    // Dispatch only for our CURRENT owned scene and only if
                    // the runtime settings type exposes each selector.
                    SEL fgSelector=NSSelectorFromString(@"setForeground:");
                    if (settings && [settings respondsToSelector:fgSelector]) {
                        ((void (*)(id,SEL,BOOL))objc_msgSend)(settings,fgSelector,YES);
                    }
                    SEL bgSelector=NSSelectorFromString(@"setBackgrounded:");
                    if (settings && [settings respondsToSelector:bgSelector]) {
                        ((void (*)(id,SEL,BOOL))objc_msgSend)(settings,bgSelector,NO);
                    }
                    // No lock/idle/occlusion, frame ivar writes or global hooks.
                    // A successful IPC call is NOT a device media ACK.
                };
                if (!unchanged) {
                    ((void (*)(id,SEL,id))objc_msgSend)(
                        hostedScene,update,setVerifiedNative12Frame);
                    DFSceneLog(@"native12-scene-settings-live-contract-requested",
                               self.bundleID,NSStringFromCGRect(nativeFrame));
                } else {
                    DFSceneLog(@"scene-frame-unchanged-no-duplicate-diff",
                               self.bundleID,NSStringFromCGRect(nativeFrame));
                }
            } else {
                DFSceneLog(@"native12-scene-settings-selector-unavailable",
                           self.bundleID,@"updateSettingsWithBlock: unavailable");
            }
        }
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
    @finally { self.committingSceneGeometry=NO; }
    // Never fake a nil FrontBoard transition or invalidate a playing scene
    // as a stand-in for a valid media rotation state change.
    DFSceneLog(@"native-app-geometry-reference-only-no-nil-frontboard-transition",
               self.bundleID,NSStringFromCGSize(size));
}
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *target=[super hitTest:point withEvent:event];
    // Passive routing observation only; do not steal gestures from the player.
    BOOL began=NO;
    if(event.type==UIEventTypeTouches)
        for(UITouch *touch in event.allTouches)
            if(touch.phase==UITouchPhaseBegan){began=YES;break;}
    if (self.ready && target && began) {
        NSTimeInterval now=NSDate.date.timeIntervalSince1970;
        if (now-self.lastHitLogAt>0.8) {
            self.lastHitLogAt=now;
            DFSceneLog(@"media-pane-hit-test-target",
                       self.bundleID,NSStringFromClass(target.class));
            __weak typeof(self) weakSurface=self;
            dispatch_async(dispatch_get_main_queue(), ^{
                DFSceneSurface *surface=weakSurface;
                if(!surface || surface.stopped || !surface.ready)return;
                [[NSNotificationCenter defaultCenter]
                     postNotificationName:DFSceneHostDidObserveTouchNotification
                     object:surface userInfo:nil];
            });
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
            // SceneHandle may be replaced across app restarts, even while the
            // containing pane and SBAppViewController remain unchanged.
            if (self.scene && self.scene!=scene) {
                [self revokeOrientationPolicy];
                ++self.sceneGeneration;
                DFSceneLog(@"scene-instance-changed",self.bundleID,
                           @"invalidate-old-reference-without-writing-old-scene");
                [self.geometryCommitTimer invalidate];
                self.geometryCommitTimer=nil;
                self.ready=NO;
                self.scene=nil;
                self.committedReferenceSize=CGSizeZero;
            }
            self.tries=0;
            if (!self.scene) {
                self.scene=scene;
                self.lastObservedForeground=-2;
                self.sceneSettingsBefore=[DFCall0(scene,@"mutableSettings") copy];
                DFSceneLog(@"scene-attached",self.bundleID,NSStringFromClass([scene class]));
            }
            // Read-only lifecycle telemetry. The crash IPS proves that
            // SpringBoard receives foreground=NO while the host is Live,
            // but it does not identify the writer of that setting.
            // Never treat a sampled flag as an authorization to write it.
            @try {
                NSInteger fg=DFObservedSceneForeground(scene);
                if(fg!=self.lastObservedForeground) {
                    self.lastObservedForeground=fg;
                    DFSceneLog(@"scene-foreground-observed-only",self.bundleID,
                        [NSString stringWithFormat:
                           @"generation=%lu scene=%p foreground=%ld hosting=%d",
                           (unsigned long)self.sceneGeneration,scene,(long)fg,isHosting]);
                }
            } @catch (NSException *readError) {
                // Diagnostics must never kill or invalidate a playing app.
                DFSceneLog(@"scene-foreground-readback-unavailable",self.bundleID,
                           readError.name);
            }
            if (!self.ready) {
                self.ready=YES;
                self.lastApplied=CGSizeZero;
                self.committedReferenceSize=CGSizeZero;
                [self registerOwnedOrientationForDeviceController:nil];
                [self layoutScene];
                DFSceneLog(@"scene-handle-observed-render-unverified",self.bundleID,NSStringFromCGRect(self.bounds));
                [[NSNotificationCenter defaultCenter] postNotificationName:DFSceneHostDidBecomeReadyNotification object:self userInfo:@{@"bundleID":self.bundleID?:@""}];
            }
            return;
        }
        if (self.ready || self.scene) {
            [self revokeOrientationPolicy];
            ++self.sceneGeneration;
            [self.geometryCommitTimer invalidate]; self.geometryCommitTimer=nil;
            self.ready=NO; self.scene=nil; self.sceneSettingsBefore=nil;
            self.lastObservedForeground=-2;
            self.committedReferenceSize=CGSizeZero;
            self.lastApplied=CGSizeZero;
            DFSceneLog(@"scene-geometry-suspended",self.bundleID,@"hosting-or-window-ownership-lost");
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
    [self revokeOrientationPolicy];
    DFSceneLifecycleUnregister(self.appController);
    ++self.sceneGeneration;
    [self.timer invalidate]; self.timer=nil;
    [self.geometryCommitTimer invalidate]; self.geometryCommitTimer=nil;
    @try {
        if (self.started) {
            [self.appController beginAppearanceTransition:NO animated:NO];
            [self.appController endAppearanceTransition];
            DFHostInt(self.appController,@"setRequestedMode:",0);
            // Original Native12 dismiss IMP 0xaf01c: child view
            // removeFromSuperview @af0fc PRECEDES willMove:nil @af130.
            // Only reorder our OWN SBAppViewController child calls;
            // bridge-object setInvalidated:/setHosting: do not apply here.
            [self.appController.view removeFromSuperview];
            [self.appController willMoveToParentViewController:nil];
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
    if(!DFSceneLifecycleInstall()) {
        if(error)*error=DFSceneError(114,@"Scene lifecycle boundary ABI/hook unavailable");
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
