#import "DFDeepTrace.h"
// Independently maintained first-party DuoFace module, ported from the
// project's own prior scene-host experiments; no vendor binary or license.
// DuoFace independent scene host for jailbroken iOS 16 SpringBoard.
// Experimental: SB/FrontBoard selectors are private and verified only at runtime.
// No vendor-licensed application bridge or entitlement overrides.
#import "DFSceneHost.h"
#import "DFNative12MediaGeometry.h"
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
    // Sample repetitive frame churn; all lifecycle/error events remain lossless.
    static NSTimeInterval lastResizeTrace;
    BOOL repetitive=[event isEqualToString:@"resize"] || [event isEqualToString:@"media-viewport-ui-only"];
    NSTimeInterval now=NSProcessInfo.processInfo.systemUptime;
    if(!repetitive || now-lastResizeTrace>=.25){DFDeepTrace(@"scene",line);if(repetitive)lastResizeTrace=now;}
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

// A remote FBS scene frame is separate from its enclosing UIKit viewport.
// Both original Native12 0xadc74 and OmniCar 0xf210 write this scene size.
static BOOL DFSceneHasCGRectABI(id object, SEL selector, BOOL setter) {
    if (!object || ![object respondsToSelector:selector]) return NO;
    NSMethodSignature *sig=[object methodSignatureForSelector:selector];
    if (!sig || sig.numberOfArguments!=(setter?3:2)) return NO;
    const char *rectABI=setter?[sig getArgumentTypeAtIndex:2]:sig.methodReturnType;
    return rectABI && strcmp(rectABI,@encode(CGRect))==0 &&
        (!setter || strcmp(sig.methodReturnType,@encode(void))==0);
}
static BOOL DFReadOwnedSceneFrame(id scene, CGRect *output) {
    if (!scene || !output) return NO;
    id settings=DFCall0(scene,@"settings");
    if (!settings) settings=DFCall0(scene,@"mutableSettings");
    SEL getter=NSSelectorFromString(@"frame");
    if (!DFSceneHasCGRectABI(settings,getter,NO)) return NO;
    CGRect frame=((CGRect (*)(id,SEL))objc_msgSend)(settings,getter);
    if (CGRectIsNull(frame) || CGRectIsInfinite(frame) ||
        !isfinite(frame.origin.x) || !isfinite(frame.origin.y) ||
        !isfinite(frame.size.width) || !isfinite(frame.size.height) ||
        frame.size.width<=0 || frame.size.height<=0) return NO;
    *output=frame;
    return YES;
}
static BOOL DFSceneFrameMatches(CGRect observed,CGSize native) {
    return fabs(observed.origin.x)<.6 && fabs(observed.origin.y)<.6 &&
        fabs(observed.size.width-native.width)<.6 &&
        fabs(observed.size.height-native.height)<.6;
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
@property(nonatomic) NSTimeInterval lastSceneSettledAt;
@property(nonatomic) BOOL layingOutScene;
@property(nonatomic) BOOL committingSceneGeometry;
@property(nonatomic) BOOL geometrySuspended;
@property(nonatomic) NSUInteger sceneGeneration;
@property(nonatomic) NSUInteger tries;
@property(nonatomic) CGSize lastApplied;
// UIKit viewport moves immediately; remote media content-reference commits
// only after split/zoom stops changing, to avoid FrontBoard churn.
@property(nonatomic) CGSize pendingReferenceSize;
@property(nonatomic) CGSize committedReferenceSize;
// One attempted FBScene transaction per native size and scene generation.
// Requested is not accepted: only an observed scene frame can commit.
@property(nonatomic) CGSize requestedSceneFrameSize;
@property(nonatomic) NSUInteger requestedSceneFrameGeneration;
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
- (void)diagnoseScene:(NSString *)phase {
    // Probe current ownership without asking FrontBoard to mutate settings.
    // A nonnil handle never proves a rendered player or a safe scene diff.
    @try {
        id handle=DFCall0(self.appController,@"sceneHandle");
        id observed=DFCall0(handle,@"sceneIfExists");
        UIView *child=self.appController.isViewLoaded?self.appController.view:nil;
        DFDiagnosticSnapshot(@"scene-audit",phase,@{
            @"bundle":self.bundleID?:@"-",
            @"started":@(self.started),@"ready":@(self.ready),
            @"stopped":@(self.stopped),
            @"generation":@(self.sceneGeneration),
            @"hosting":@(DFHostingFlag(self.appController,@"isHostingAnApp",NO)),
            @"sceneMatches":@(observed && observed==self.scene),
            @"attached":@(child && child.window && child.window==self.window),
            @"controller":NSStringFromClass(self.appController.class)?:@"-",
            @"sceneType":NSStringFromClass([observed class])?:@"-",
            @"pane":NSStringFromCGRect(self.bounds),
            @"window":self.window?NSStringFromCGRect(self.window.bounds):@"none",
            @"childFrame":child?NSStringFromCGRect(child.frame):@"none",
            @"childBounds":child?NSStringFromCGRect(child.bounds):@"none",
            @"pending":NSStringFromCGSize(self.pendingReferenceSize),
            @"committed":NSStringFromCGSize(self.committedReferenceSize),
            @"requested":NSStringFromCGSize(self.requestedSceneFrameSize)
        });
    } @catch(NSException *e) {
        DFDeepTrace(@"scene-audit",[NSString stringWithFormat:
            @"checkpoint=%@ read-failed=%@",phase,e.name]);
    }
}
- (void)tracePhase:(NSString *)phase {
    DFDeepTrace(@"scene-phase",[NSString stringWithFormat:@"surface=%p bundle=%@ phase=%@ started=%d ready=%d stopped=%d generation=%lu controller=%@ bounds=%@ scene=%p",
        self,self.bundleID,phase,self.started,self.ready,self.stopped,(unsigned long)self.sceneGeneration,
        NSStringFromClass(self.appController.class),NSStringFromCGRect(self.bounds),self.scene]);
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
        [self tracePhase:@"before-add-child"];
        [parent addChildViewController:self.appController];
        [self tracePhase:@"after-add-child"];
        [self tracePhase:@"before-load-controller-view"];
        UIView *appView = self.appController.view;
        [self tracePhase:@"after-load-controller-view"];
        appView.clipsToBounds = YES;
        [self addSubview:appView];
        [self tracePhase:@"before-did-move-parent"];
        [self.appController didMoveToParentViewController:parent];
        [self tracePhase:@"after-did-move-parent"];
        DFHostBool(self.appController, @"setIgnoresOcclusions:", NO);
        DFHostBool(self.appController, @"setAutomatesLifecycle:", NO);
        [self layoutScene];
        // Seed one initial remote content frame before mode=2. This is
        // required by some scene owners; later resizes are debounced.
        self.pendingReferenceSize=self.bounds.size;
        [self tracePhase:@"before-initial-reference-seed"];
        [self commitSceneGeometry:nil];
        [self tracePhase:@"after-initial-reference-seed"];
        [self tracePhase:@"before-begin-appearance"];
        [self.appController beginAppearanceTransition:YES animated:NO];
        [self tracePhase:@"after-begin-appearance"];
        [self tracePhase:@"before-requested-mode-2"];
        DFHostInt(self.appController, @"setRequestedMode:", 2);
        [self tracePhase:@"after-requested-mode-2"];
        [self tracePhase:@"before-end-appearance"];
        [self.appController endAppearanceTransition];
        [self tracePhase:@"after-end-appearance"];
        DFSceneLog(@"mode-2-requested",self.bundleID,NSStringFromCGRect(self.bounds));
        [self diagnoseScene:@"mode2-requested"];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.35 target:self
                  selector:@selector(pollScene:) userInfo:nil repeats:YES];
        [self pollScene:self.timer];
    } @catch (NSException *e) {
        DFDeepTrace(@"scene-exception",[NSString stringWithFormat:@"surface=%p bundle=%@ name=%@ reason=%@ stack=%@",self,self.bundleID,e.name,e.reason,e.callStackSymbols]);
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
    if (!self.started || self.stopped || self.geometrySuspended || self.layingOutScene || self.committingSceneGeometry) return;
    CGSize size=self.bounds.size;
    if (size.width<=0 || size.height<=0 || !isfinite(size.width) || !isfinite(size.height)) return;
    if (CGSizeEqualToSize(size,self.lastApplied)) return;
    // A divider drag can produce dozens of intermediate frames. Scale the
    // existing UIKit scene immediately and leave the remote player intact.
    // Original CBBridgedUIAppView.updateLayout @accf4, ad03c-ad0c8:
    // roundf(2*slot), uniform min(width/nativeW,height/nativeH),
    // original threshold .05 and corner policy <600. No guessed rotation.
    // Restore the exact source viewport ratio used by the playable .37 build.
    CGSize logical=CGSizeMake(round(size.width*2),round(size.height*2));
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
        // On-device .47 screenshots show mobile portrait content occupying
        // only a fraction of a landscape CarPlay pane. Record read-only UIKit
        // dimensions so the next audit can distinguish wrong source-window
        // geometry from an app intrinsically enforcing portrait. Never
        // mutate FrontBoard/host scene settings to collect diagnostics.
        DFSceneLog(@"media-pane-frame-readback",self.bundleID,
            [NSString stringWithFormat:@"pane=%@ externalWindow=%@ hostFrame=%@ hostBounds=%@",
                NSStringFromCGRect(self.bounds),
                NSStringFromCGRect(self.window.frame),
                NSStringFromCGRect(self.appController.view.frame),
                NSStringFromCGRect(self.appController.view.bounds)]);
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
    if (self.stopped || self.geometrySuspended || self.committingSceneGeometry || !self.window || !self.appController ||
        (!self.ready && !CGSizeEqualToSize(self.committedReferenceSize,CGSizeZero))) return;
    CGSize size=self.pendingReferenceSize;
    if (CGSizeEqualToSize(size,self.committedReferenceSize) ||
        !CGSizeEqualToSize(size,self.bounds.size) ||
        size.width<=0 || size.height<=0 || !isfinite(size.width) || !isfinite(size.height)) return;
    // A live scene is still changing ownership for several FrontBoard
    // callbacks after attach/resume. The owner check alone is insufficient:
    // on-device SpringBoard aborts occurred inside didUpdateSettingsWithDiff.
    // Defer private reference-size writes until the SAME scene has been
    // continuously hosted for at least 1.25 seconds. Preserve the UIKit
    // layout immediately and coalesce resizes, rather than disabling media.
    if(self.ready){
        NSTimeInterval age=NSDate.date.timeIntervalSince1970-self.lastSceneSettledAt;
        if(!isfinite(age)||age<1.25){
            NSTimeInterval wait=isfinite(age)?MAX(.1,1.25-age):1.25;
            self.geometryCommitTimer=[NSTimer scheduledTimerWithTimeInterval:wait
                target:self selector:@selector(commitSceneGeometry:) userInfo:nil repeats:NO];
            DFSceneLog(@"private-geometry-delayed-scene-not-stable",self.bundleID,
                       [NSString stringWithFormat:@"settledAge=%.2f wait=%.2f",age,wait]);
            return;
        }
    }
    // Original Native12 refreshSceneLayout @ade58 negotiates the REAL app
    // reference size after the UIView layout. Prior .66 exited here as soon
    // as hosting was ready, so a large split pane retained a phone viewport.
    // A live scene is more dangerous than the initial pre-mode2 seed:
    // perform exactly ONE coalesced child-reference dispatch only after the
    // present scene is stably hosted, not one write per divider movement.
    // Only the owned scene-frame transaction below may modify settings,
    // gated by ABI/generation. Old +440 SpringBoard SIGABRT remains a risk.
    if(self.ready){
        NSUInteger generation=self.sceneGeneration;
        id handle=DFCall0(self.appController,@"sceneHandle");
        id currentScene=DFCall0(handle,@"sceneIfExists");
        BOOL viewAttached=(self.appController.view.window==self.window);
        if(self.stopped || self.geometrySuspended || !currentScene ||
           currentScene!=self.scene || !viewAttached ||
           !DFHostingFlag(self.appController,@"isHostingAnApp",NO) ||
           self.sceneGeneration!=generation){
            DFSceneLog(@"live-viewport-owner-mismatch",self.bundleID,
                       @"defer; current generation/hosting/window not stable");
            return;
        }
        id deviceController=nil;
        @try {
            deviceController=[self.appController valueForKey:@"_deviceAppViewController"];
        } @catch(NSException *kvcError) {
            DFSceneLog(@"live-viewport-kvc-fallback",self.bundleID,kvcError.name);
            Ivar ivar=class_getInstanceVariable([self.appController class],
                                               "_deviceAppViewController");
            if(ivar) deviceController=object_getIvar(self.appController,ivar);
        }
        SEL sz3=NSSelectorFromString(
            @"setContentReferenceSize:withContentOrientation:andContainerOrientation:");
        NSMethodSignature *sig=(deviceController &&
                                [deviceController respondsToSelector:sz3]) ?
             [deviceController methodSignatureForSelector:sz3] : nil;
        const char *sizeType=(sig && sig.numberOfArguments==5) ?
             [sig getArgumentTypeAtIndex:2] : NULL;
        const char *contentType=(sig && sig.numberOfArguments==5) ?
             [sig getArgumentTypeAtIndex:3] : NULL;
        const char *containerType=(sig && sig.numberOfArguments==5) ?
             [sig getArgumentTypeAtIndex:4] : NULL;
        // The original 3-argument UIKit ABI is CGSize + NSInteger +
        // NSInteger on arm64. Reject unknown ABI instead of messaging an
        // inappropriate receiver and crashing SpringBoard on the device.
        BOOL sizeABI=(sizeType &&
                     (strcmp(sizeType,@encode(CGSize))==0 ||
                      strncmp(sizeType,"{CGSize=",8)==0));
        BOOL abiValid=sig && sig.numberOfArguments==5 && sizeABI &&
             strcmp(sig.methodReturnType,@encode(void))==0 &&
             contentType && strcmp(contentType,@encode(NSInteger))==0 &&
             containerType && strcmp(containerType,@encode(NSInteger))==0;
        // Native12 HUD8 original updateLayout @acf98-ad004 and
        // updateSceneSettingsFrame @ad66c-ad708 SEND BOTH optional child
        // signatures and then the controller two-argument fallback.
        // .68 mistakenly requires child3 as a gate for ALL scene writes:
        // when the actual child implements only child2, the player never
        // receives any reference size, and this entire method returns.
        SEL sz2=NSSelectorFromString(@"setContentReferenceSize:withInterfaceOrientation:");
        NSMethodSignature *sig2=(deviceController &&
                                [deviceController respondsToSelector:sz2]) ?
                                [deviceController methodSignatureForSelector:sz2]:nil;
        NSMethodSignature *mainSig=([self.appController respondsToSelector:sz2]) ?
                                [self.appController methodSignatureForSelector:sz2]:nil;
        BOOL child2Valid=sig2 && sig2.numberOfArguments==4 &&
              strcmp(sig2.methodReturnType,@encode(void))==0 &&
              (strcmp([sig2 getArgumentTypeAtIndex:2],@encode(CGSize))==0 ||
               strncmp([sig2 getArgumentTypeAtIndex:2],"{CGSize=",8)==0) &&
              strcmp([sig2 getArgumentTypeAtIndex:3],@encode(NSInteger))==0;
        BOOL main2Valid=mainSig && mainSig.numberOfArguments==4 &&
              strcmp(mainSig.methodReturnType,@encode(void))==0 &&
              (strcmp([mainSig getArgumentTypeAtIndex:2],@encode(CGSize))==0 ||
               strncmp([mainSig getArgumentTypeAtIndex:2],"{CGSize=",8)==0) &&
              strcmp([mainSig getArgumentTypeAtIndex:3],@encode(NSInteger))==0;
        if(!abiValid && !child2Valid && !main2Valid){
            [self diagnoseScene:@"live-reference-abi-rejected"];
            DFSceneLog(@"live-viewport-abi-rejected",self.bundleID,
                [NSString stringWithFormat:@"child=%@ child2=%d child3=%d main2=%d",
                   NSStringFromClass([deviceController class]),
                   child2Valid,abiValid,main2Valid]);
            return;
        }
        // The 0.30s quiet period + 1.25s stable owner check above are part
        // of the contract. A newer pan, replacement or Close revokes it.
        if(self.stopped || self.geometrySuspended ||
           self.sceneGeneration!=generation ||
           !CGSizeEqualToSize(size,self.pendingReferenceSize) ||
           !CGSizeEqualToSize(size,self.bounds.size) ||
           DFCall0(DFCall0(self.appController,@"sceneHandle"),
                   @"sceneIfExists")!=currentScene)return;
        CGSize logical=CGSizeMake(round(size.width*2),round(size.height*2));
        self.committingSceneGeometry=YES;
        @try {
            [self diagnoseScene:@"before-live-reference-send"];
            DFSceneLog(@"live-viewport-reference-before",self.bundleID,
              [NSString stringWithFormat:@"generation=%lu scene=%p size=%@",
                  (unsigned long)generation,currentScene,
                  NSStringFromCGSize(logical)]);
            // Preserve original Native12 call order. No orientation
            // guessing: the verified ARM64 uses 1 (Portrait) for both.
            // This is a single coalesced resize after ownership settles,
            // not a new process-wide hook or a new scene owner.
            if(child2Valid)
                ((void (*)(id,SEL,CGSize,NSInteger))objc_msgSend)(
                    deviceController,sz2,logical,UIInterfaceOrientationPortrait);
            if(abiValid)
                ((void (*)(id,SEL,CGSize,NSInteger,NSInteger))objc_msgSend)(
                    deviceController,sz3,logical,
                    UIInterfaceOrientationPortrait,UIInterfaceOrientationPortrait);
            if(main2Valid)
                ((void (*)(id,SEL,CGSize,NSInteger))objc_msgSend)(
                    self.appController,sz2,logical,UIInterfaceOrientationPortrait);
            DFSceneLog(@"live-reference-native12-selector-coverage",self.bundleID,
                [NSString stringWithFormat:@"child2=%d child3=%d main2=%d size=%@",
                 child2Valid,abiValid,main2Valid,NSStringFromCGSize(logical)]);
            // Recover the user's actually playable .37 media host ordering:
            // after the three original Native12 reference setters, resize
            // the INNER app controller view too and restore the HomeGrabber
            // display mode. .68 resized the outer UIKit host only.
            //
            // Signed .37 source a8cdec6252 / DFSceneHost.m d394e19:
            // original lines 231-237. Preserve later owner/generation gates
            // and don't call synchronous layoutIfNeeded (post-.37 crash risk).
            if(!self.stopped && !self.geometrySuspended &&
               self.sceneGeneration==generation && self.scene==currentScene &&
               CGSizeEqualToSize(self.bounds.size,size)){
                UIView *inner=DFCall0(deviceController,@"view");
                if([inner isKindOfClass:UIView.class] &&
                   inner!=self.appController.view) {
                    inner.transform=CGAffineTransformIdentity;
                    inner.frame=(CGRect){CGPointZero,logical};
                    inner.autoresizingMask=UIViewAutoresizingFlexibleWidth|
                                           UIViewAutoresizingFlexibleHeight;
                    DFSceneLog(@"media37-inner-reference-restored",
                               self.bundleID,NSStringFromCGRect(inner.frame));
                }
                DFHostInt(deviceController,@"setHomeGrabberDisplayMode:",1);
            }
            // Dispatch is not a renderer ACK.
            if(!self.stopped && !self.geometrySuspended &&
               self.sceneGeneration==generation &&
               DFCall0(DFCall0(self.appController,@"sceneHandle"),
                       @"sceneIfExists")==currentScene) {
                [self diagnoseScene:@"after-live-reference-dispatch-not-video-ack"];
                DFSceneLog(@"live-scene-reference-size-dispatched",self.bundleID,
                    [NSString stringWithFormat:@"generation=%lu size=%@",
                        (unsigned long)generation,NSStringFromCGSize(logical)]);
                CGRect actual=CGRectNull;
                if(!DFReadOwnedSceneFrame(currentScene,&actual)) {
                    // Unknown getter ABI: never make a blind FBScene write.
                    self.requestedSceneFrameSize=logical;
                    self.requestedSceneFrameGeneration=generation;
                    DFSceneLog(@"live-viewport-scene-frame-abi-unavailable",
                        self.bundleID,@"no trusted CGRect getter");
                } else if(DFSceneFrameMatches(actual,logical)) {
                    self.committedReferenceSize=size;
                    self.requestedSceneFrameSize=logical;
                    self.requestedSceneFrameGeneration=generation;
                    DFSceneLog(@"live-viewport-scene-frame-already-matches",
                        self.bundleID,NSStringFromCGRect(actual));
                } else if(self.requestedSceneFrameGeneration!=generation ||
                          !CGSizeEqualToSize(self.requestedSceneFrameSize,logical)) {
                    // No wholesale vendor private flags or ivar pokes.
                    id mutableSettings=DFCall0(currentScene,@"mutableSettings");
                    SEL setter=NSSelectorFromString(@"setFrame:");
                    SEL update=NSSelectorFromString(@"updateSettingsWithBlock:");
                    NSMethodSignature *updateABI=
                        [currentScene respondsToSelector:update]?
                        [currentScene methodSignatureForSelector:update]:nil;
                    BOOL verifiedUpdateABI=updateABI &&
                        updateABI.numberOfArguments==3 &&
                        strcmp(updateABI.methodReturnType,@encode(void))==0;
                    const char *blockABI=verifiedUpdateABI?
                        [updateABI getArgumentTypeAtIndex:2]:NULL;
                    verifiedUpdateABI=verifiedUpdateABI && blockABI &&
                        (strcmp(blockABI,"@?")==0 || strcmp(blockABI,"@")==0);
                    // iOS 16.7.x target: fail closed on other OS/ABIs.
                    NSOperatingSystemVersion os=NSProcessInfo.processInfo.operatingSystemVersion;
                    if(os.majorVersion!=16 || !verifiedUpdateABI ||
                       !DFSceneHasCGRectABI(mutableSettings,setter,YES)) {
                        self.requestedSceneFrameSize=logical;
                        self.requestedSceneFrameGeneration=generation;
                        DFSceneLog(@"live-viewport-scene-transaction-abi-rejected",
                            self.bundleID,@"no compatible FBScene writer");
                    } else {
                        self.requestedSceneFrameSize=logical;
                        self.requestedSceneFrameGeneration=generation;
                        CGRect desired=CGRectMake(0,0,logical.width,logical.height);
                        __weak typeof(self) weakSurface=self;
                        DFSceneLog(@"live-viewport-scene-frame-before",self.bundleID,
                            [NSString stringWithFormat:@"old=%@ target=%@ generation=%lu",
                              NSStringFromCGRect(actual),NSStringFromCGRect(desired),
                              (unsigned long)generation]);
                        ((void (*)(id,SEL,id))objc_msgSend)(currentScene,update,
                            ^(id settings) {
                                DFSceneSurface *surface=weakSurface;
                                // The block may run after a Close/Swap/reconnect.
                                if(!surface || surface.stopped ||
                                   surface.geometrySuspended ||
                                   surface.sceneGeneration!=generation ||
                                   surface.scene!=currentScene ||
                                   !CGSizeEqualToSize(surface.requestedSceneFrameSize,logical) ||
                                   !CGSizeEqualToSize(surface.bounds.size,size) ||
                                   DFCall0(DFCall0(surface.appController,@"sceneHandle"),
                                           @"sceneIfExists")!=currentScene ||
                                   !DFSceneHasCGRectABI(settings,setter,YES))return;
                                ((void (*)(id,SEL,CGRect))objc_msgSend)(
                                    settings,setter,desired);
                            });
                        // A completed call is a request, NOT a video ACK.
                        DFSceneLog(@"live-viewport-scene-frame-requested",
                            self.bundleID,NSStringFromCGRect(desired));
                    }
                } else {
                    DFSceneLog(@"live-viewport-scene-frame-request-pending",
                        self.bundleID,NSStringFromCGRect(actual));
                }
            } else {
                DFSceneLog(@"live-viewport-owner-changed-after-send",
                           self.bundleID,@"not committed");
            }
        } @catch(NSException *e) {
            DFSceneLog(@"live-viewport-reference-exception",
                       self.bundleID,e.reason?:@"unknown");
        } @finally { self.committingSceneGeometry=NO; }
        return;
    }
    // The following private selector path is pre-requestedMode only.
    // Never enter FBScene.settings mutation for an already hosted app.
    CGSize logical=CGSizeMake(round(size.width*2),round(size.height*2));
    self.committingSceneGeometry=YES;
    @try {
    // The scene captured at first readiness may have been replaced by the
    // app. Re-resolve ownership before any private content-size mutation.
    // An initial pre-mode reference seed has no scene yet and stays separate.
    if(self.ready){
        id handle=DFCall0(self.appController,@"sceneHandle");
        id current=DFCall0(handle,@"sceneIfExists");
        BOOL attached=self.appController.view.window==self.window;
        if(!current || current!=self.scene || !attached ||
           !DFHostingFlag(self.appController,@"isHostingAnApp",NO)){
            DFSceneLog(@"geometry-deferred-owner-changed",self.bundleID,@"waiting for current hosted scene");
            return;
        }
    }
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
        DFSceneLog(@"geometry-before-reference-setters",self.bundleID,NSStringFromCGSize(logical));
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
        // Only wire the independently validated scene frame mutation here.
        // DO NOT yet force original foreground/lock/occlusion flags: their
        // teardown and rollback ownership is not device-verified.
        if (self.ready && self.scene) {
            id hostedScene=self.scene;
            SEL update=NSSelectorFromString(@"updateSettingsWithBlock:");
            // Physical iOS 16.7.16 crash reports repeatedly terminate in
            // SBAppViewController sceneHandle:didUpdateSettingsWithDiff:.
            // Suppress unverified private scene FRAME writes by default
            // while retaining the original content-reference-size pathway.
            // This is containment, not proven restoration of video playback.
            BOOL enablePrivateFrame=[[NSUserDefaults standardUserDefaults]
                boolForKey:@"DFEnableExperimentalPrivateSceneFrame"];
            if (!enablePrivateFrame)
                DFSceneLog(@"private-scene-frame-write-disabled-device-safety",
                           self.bundleID,NSStringFromCGSize(logical));
            if (enablePrivateFrame && [hostedScene respondsToSelector:update]) {
                CGRect nativeFrame=CGRectMake(0,0,logical.width,logical.height);
                NSUInteger generation=self.sceneGeneration;
                __weak typeof(self) weakSurface=self;
                void (^setVerifiedNative12Frame)(id)=^(id settings) {
                    DFSceneSurface *surface=weakSurface;
                    // A queued settings block must not revive a closed or
                    // replaced scene after Close, app relaunch, or reconnect.
                    if(!surface || surface.stopped || surface.geometrySuspended ||
                       surface.sceneGeneration!=generation || surface.scene!=hostedScene)return;
                    id currentHandle=DFCall0(surface.appController,@"sceneHandle");
                    if(DFCall0(currentHandle,@"sceneIfExists")!=hostedScene)return;
                    SEL frameSelector=NSSelectorFromString(@"setFrame:");
                    if (settings && [settings respondsToSelector:frameSelector]) {
                        ((void (*)(id,SEL,CGRect))objc_msgSend)(
                            settings,frameSelector,nativeFrame);
                    }
                    // Original _frame ivar write and other private setters
                    // are deliberately withheld until safe scene rollback is
                    // proven. A successful IPC call is NOT a device media ACK.
                };
                DFSceneLog(@"geometry-before-scene-frame",self.bundleID,NSStringFromCGRect(nativeFrame));
                ((void (*)(id,SEL,id))objc_msgSend)(
                    hostedScene,update,setVerifiedNative12Frame);
                DFSceneLog(@"native12-scene-settings-frame-requested",
                           self.bundleID,NSStringFromCGRect(nativeFrame));
            } else {
                DFSceneLog(@"native12-scene-settings-selector-unavailable",
                           self.bundleID,@"updateSettingsWithBlock: unavailable");
            }
        }
        if (applied) {
            // v0.0.37: no extra UIKit invalidation from the private scene update.
            self.committedReferenceSize=size;
            DFSceneLog(@"media-reference-committed-after-stable-viewport",
                       self.bundleID,NSStringFromCGSize(size));
        } else {
            DFSceneLog(@"media-reference-abi-unavailable",self.bundleID,@"private resize selector unavailable");
        }
    } @catch (NSException *e) {
        DFSceneLog(@"media-geometry-commit-warning",self.bundleID,e.reason);
    } @finally { self.committingSceneGeometry=NO; }
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
            self.tries=0; // Consecutive unavailable polls, never lifetime misses.
            BOOL sceneChanged=(self.scene!=scene);
            BOOL resumed=self.geometrySuspended;
            self.geometrySuspended=NO;
            if (sceneChanged || resumed)self.lastSceneSettledAt=NSDate.date.timeIntervalSince1970;
            if (sceneChanged) {
                ++self.sceneGeneration;
                [self.geometryCommitTimer invalidate];self.geometryCommitTimer=nil;
                self.scene=scene;
                self.sceneSettingsBefore=[DFCall0(scene,@"mutableSettings") copy];
                DFSceneLog(@"scene-attached",self.bundleID,NSStringFromClass([scene class]));
                [self diagnoseScene:@"scene-attached"];
            }
            if(self.ready && !sceneChanged && !resumed &&
               self.requestedSceneFrameGeneration==self.sceneGeneration &&
               self.requestedSceneFrameSize.width>0) {
                CGSize requested=self.requestedSceneFrameSize;
                CGSize expected=CGSizeMake(round(self.bounds.size.width*2),
                                           round(self.bounds.size.height*2));
                if(CGSizeEqualToSize(requested,expected) &&
                   CGSizeEqualToSize(self.committedReferenceSize,CGSizeZero)) {
                    CGRect observed=CGRectNull;
                    if(DFReadOwnedSceneFrame(scene,&observed) &&
                       DFSceneFrameMatches(observed,requested)) {
                        self.committedReferenceSize=self.bounds.size;
                        DFSceneLog(@"live-viewport-scene-frame-readback-accepted",
                            self.bundleID,NSStringFromCGRect(observed));
                        [self diagnoseScene:@"scene-frame-readback-accepted"];
                    }
                }
            }
            if(self.ready && (sceneChanged || resumed)){
                self.lastApplied=CGSizeZero;
                self.committedReferenceSize=CGSizeZero;
                self.requestedSceneFrameSize=CGSizeZero;
                self.requestedSceneFrameGeneration=0;
                [self layoutScene];
                DFSceneLog(@"scene-geometry-owner-resynchronized",self.bundleID,
                    sceneChanged?@"scene replaced":@"hosting resumed");
            }
            if (!self.ready) {
                self.ready=YES;
                self.lastApplied=CGSizeZero;
                self.committedReferenceSize=CGSizeZero;
                self.requestedSceneFrameSize=CGSizeZero;
                self.requestedSceneFrameGeneration=0;
                [self layoutScene];
                DFSceneLog(@"scene-handle-observed-render-unverified",self.bundleID,NSStringFromCGRect(self.bounds));
                [self diagnoseScene:@"ready-render-unverified"];
                [[NSNotificationCenter defaultCenter] postNotificationName:DFSceneHostDidBecomeReadyNotification object:self userInfo:@{@"bundleID":self.bundleID?:@""}];
            }
            return;
        }
        if(self.ready && !self.geometrySuspended){
            self.geometrySuspended=YES;
            self.requestedSceneFrameSize=CGSizeZero;
            self.requestedSceneFrameGeneration=0;
            ++self.sceneGeneration;
            [self.geometryCommitTimer invalidate];self.geometryCommitTimer=nil;
            DFSceneLog(@"scene-geometry-suspended",self.bundleID,@"hosting or attachment unavailable");
            [self diagnoseScene:@"hosting-suspended"];
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
    [self diagnoseScene:@"scene-failed-before-stop"];
    DFSceneLog(@"scene-failed",self.bundleID,error.localizedDescription);
    UIView *target=self;
    [self stop];
    [[NSNotificationCenter defaultCenter] postNotificationName:DFSceneHostDidFailNotification
                object:target userInfo:@{@"error":error}];
}
- (void)stop {
    if (self.stopped) return;
    [self diagnoseScene:@"before-close-invalidate"];
    self.stopped=YES;
    self.geometrySuspended=YES;
    self.requestedSceneFrameSize=CGSizeZero;
    self.requestedSceneFrameGeneration=0;
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
        [self diagnoseScene:@"controller-invalidated"];
    } @catch (NSException *e) { DFSceneLog(@"invalidate-warning",self.bundleID,e.reason); }
    // Do not send a fabricated/nil FrontBoard transition context during close.
    // Request mode 0 + invalidate above; iPhone exitmode crash risk is monitored.
    DFSceneLog(@"close-no-private-settings-restore",self.bundleID,@"");
    [self diagnoseScene:@"before-wrapper-removal"];

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

