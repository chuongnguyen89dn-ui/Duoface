#import "MTBridgeCoordinator.h"
#import "MTBridgeRootViewController.h"
#import "MTSceneHost.h"
#import "MTTrialLog.h"
#import "MTDashboardContext.h"
#import "MTDashboardUsableRect.h"
#import "MTDashboardActivation.h"
#import "MTNativeShellGeometry.h"
#import <objc/message.h>
#import <objc/runtime.h>
@interface MTBridgeCoordinator ()
@property(nonatomic,strong,nullable) UIWindow *bridgeWindow;
@property(nonatomic,strong,nullable) NSTimer *pollTimer;
@property(nonatomic,assign,readwrite,getter=isCarPlayConnected) BOOL carPlayConnected;
@property(nonatomic,assign) BOOL observing;
@property(nonatomic,assign) BOOL attemptedForThisConnection;
@property(nonatomic,assign) BOOL hadDisplay;
@property(nonatomic,assign) BOOL lastEnabled;
@property(nonatomic,assign) CGRect mtUnobstructedFrame;
@property(nonatomic,copy) NSString *lastDockLayoutMode;
@property(nonatomic,assign) NSUInteger nativeShellRequests;
@property(nonatomic,assign) NSTimeInterval lastShellRequestTime;
@end
@implementation MTBridgeCoordinator
+ (instancetype)sharedCoordinator {
    static MTBridgeCoordinator *instance;
    static dispatch_once_t once;
    dispatch_once(&once,^{instance=[MTBridgeCoordinator new];});
    return instance;
}
static id MTGetObject(id object,NSString *selectorName) {
    if (!object) return nil;
    SEL sel=NSSelectorFromString(selectorName);
    if (![object respondsToSelector:sel]) return nil;
    BOOL classTarget=class_isMetaClass(object_getClass(object));
    Method method=classTarget ? class_getClassMethod((Class)object,sel)
                              : class_getInstanceMethod([object class],sel);
    char ret[16]={0};
    if (method) method_getReturnType(method,ret,sizeof(ret));
    if (!method || ret[0]!='@') return nil;
    @try { return ((id (*)(id,SEL))objc_msgSend)(object,sel); }
    @catch (NSException *exception) {
        MTTrialLog(@"getter-exception",[NSString stringWithFormat:@"sel=%@ type=%@",selectorName,NSStringFromClass(exception.class)]);
        return nil;
    }
}
static id MTCarPlayDisplay(void) {
    id device=MTGetObject(NSClassFromString(@"AVExternalDevice"),@"currentCarPlayExternalDevice");
    id screenIDs=MTGetObject(device,@"screenIDs");
    id displays=MTGetObject(NSClassFromString(@"CADisplay"),@"displays");
    if (![screenIDs isKindOfClass:NSArray.class] || ![displays isKindOfClass:NSArray.class]) return nil;
    for (id display in displays) {
        id unique=MTGetObject(display,@"uniqueId");
        if (unique && [screenIDs containsObject:unique]) return display;
    }
    return nil;
}
+ (BOOL)trialEnabled {
    NSDictionary *config=[NSDictionary dictionaryWithContentsOfFile:MTTrialConfigurationPath()];
    return [config[@"Enabled"] respondsToSelector:@selector(boolValue)] && [config[@"Enabled"] boolValue];
}
+ (void)setTrialEnabled:(BOOL)enabled {
    NSString *path=MTTrialConfigurationPath();
    NSDictionary *current=[NSDictionary dictionaryWithContentsOfFile:path];
    NSMutableDictionary *p=current ? [current mutableCopy] : [NSMutableDictionary dictionary];
    p[@"Enabled"]=@(enabled);
    if (![p writeToFile:path atomically:YES]) MTTrialLog(@"config-write-failed",path);
    else MTTrialLog(@"config-updated",enabled ? @"enabled=1" : @"enabled=0");
}
- (void)start {
    if (self.observing) return;
    if (![NSProcessInfo.processInfo.processName isEqualToString:@"SpringBoard"]) return;
    self.observing=YES;
    NSString *path=MTTrialConfigurationPath();
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:[path stringByDeletingLastPathComponent]
                                  withIntermediateDirectories:YES attributes:nil error:nil];
        [[self class] setTrialEnabled:NO];
    }
    MTTrialLog(@"coordinator-start",[NSString stringWithFormat:@"config=%@ enabled=%d",path,[[self class] trialEnabled]]);
    // iOS 16 deprecates UIScreenDidConnect/UIScreen.screens; v1a validated
    // CarPlay AVExternalDevice↔CADisplay. Polling permits Filza opt-in
    // without a second DEB or respring and detects disconnect to close hosts.
    self.pollTimer=[NSTimer scheduledTimerWithTimeInterval:1.2
                    target:self selector:@selector(poll:) userInfo:nil repeats:YES];
    [self poll:self.pollTimer];
}
- (void)poll:(NSTimer *)timer {
    (void)timer;
    BOOL enabled=[[self class] trialEnabled];
    id display=MTCarPlayDisplay();
    BOOL present=(display!=nil);
    if (enabled!=self.lastEnabled || present!=self.hadDisplay) {
        MTTrialLog(@"state",[NSString stringWithFormat:@"enabled=%d carplayMatched=%d window=%d",enabled,present,(self.bridgeWindow!=nil)]);
    }
    if (!enabled || !present) {
        if (self.bridgeWindow) [self detach];
        self.attemptedForThisConnection=NO;
        self.nativeShellRequests=0;
        self.lastShellRequestTime=0;
        self.lastEnabled=enabled;
        self.hadDisplay=present;
        return;
    }
    self.lastEnabled=enabled;
    self.hadDisplay=present;
    NSDictionary *shell=[NSDictionary dictionaryWithContentsOfFile:MTNativeShellRecordPath()];
    NSNumber *timestamp=shell[@"Timestamp"];
    NSTimeInterval age=[timestamp respondsToSelector:@selector(doubleValue)] ?
          NSDate.date.timeIntervalSince1970-[timestamp doubleValue] : 1e9;
    BOOL nativeReady=([shell[@"Producer"] isEqualToString:@"IndependentDuoFaceShell"] &&
                      [shell[@"Kind"] isEqualToString:@"NativeCarPlayWindowScene"] &&
                      [shell[@"CarPlayRole"] isEqual:@YES] &&
                      [shell[@"GeometryValid"] isEqual:@YES] &&
                      [shell[@"HasNonzeroInsets"] isEqual:@YES] &&
                      age>=0 && age<4.0);
    if (!nativeReady) {
        if (self.bridgeWindow)[self detach];
        NSTimeInterval now=NSDate.date.timeIntervalSince1970;
        if (self.nativeShellRequests<8 && now-self.lastShellRequestTime>=3.0) {
            self.nativeShellRequests++;
            self.lastShellRequestTime=now;
            [MTDashboardActivation requestDuoFaceShellFromSpringBoard];
            MTTrialLog(@"native-shell-awaiting",
              [NSString stringWithFormat:@"request=%lu CarPlay-scene-not-yet-verified",
              (unsigned long)self.nativeShellRequests]);
        }
        return;
    }
    if (self.bridgeWindow) { [self refreshDashboardContentGeometry]; return; }
    if (self.attemptedForThisConnection) return;
    self.attemptedForThisConnection=YES;
    [self attachToCarPlayDisplay:display];
}
- (void)attachToCarPlayDisplay:(id)display {
    if (self.bridgeWindow) return;
    Class config=NSClassFromString(@"FBSDisplayConfiguration");
    Class rootWindow=NSClassFromString(@"UIRootSceneWindow");
    SEL configInit=NSSelectorFromString(@"initWithCADisplay:isMainDisplay:");
    SEL windowInit=NSSelectorFromString(@"initWithDisplayConfiguration:");
    if (!config || !rootWindow ||
        ![config instancesRespondToSelector:configInit] ||
        ![rootWindow instancesRespondToSelector:windowInit]) {
        MTTrialLog(@"window-preflight-failed",@"missing FBSDisplayConfiguration or UIRootSceneWindow");
        return;
    }
    @try {
        id cfg=((id (*)(id,SEL,id,BOOL))objc_msgSend)([config alloc],configInit,display,NO);
        UIWindow *window=((id (*)(id,SEL,id))objc_msgSend)([rootWindow alloc],windowInit,cfg);
        if (!window) { MTTrialLog(@"window-failed",@"nil window"); return; }
        MTBridgeRootViewController *root=[MTBridgeRootViewController new];
        window.rootViewController=root;
        window.backgroundColor=UIColor.clearColor;
        window.opaque=NO;
        window.windowLevel=UIWindowLevelNormal;
        self.bridgeWindow=window;
        self.carPlayConnected=YES;
        self.mtUnobstructedFrame=window.frame;
        CGRect nativeContent=CGRectZero;
        NSDictionary *shell=[NSDictionary dictionaryWithContentsOfFile:MTNativeShellRecordPath()];
        if (!MTNativeShellUsableRect(window.frame,shell,&nativeContent)) {
            MTTrialLog(@"native-shell-frame-rejected",
              @"native scene geometry unavailable: refusing full-cover external window");
            [self detach];
            return;
        }
        window.frame=nativeContent;
        window.hidden=NO;
        MTTrialLog(@"native-shell-window-attached",
          [NSString stringWithFormat:@"shell-role=CarPlay content=%@",
          NSStringFromCGRect(nativeContent)]);
        MTTrialLog(@"window-shown",[NSString stringWithFormat:@"class=%@ frame=%@ bounds=%@",NSStringFromClass(window.class),NSStringFromCGRect(window.frame),NSStringFromCGRect(window.bounds)]);
    } @catch (NSException *ex) {
        MTTrialLog(@"window-exception",ex.reason ?: @"?");
        [self detach];
    }
}
// Native CarPlay shell is the ONLY accepted external presentation owner.
// Even Zoom is constrained inside its OS-owned scene's actual usable rectangle.
- (void)refreshDashboardContentGeometry {
    UIWindow *w=self.bridgeWindow;
    if (!w) return;
    CGRect full=self.mtUnobstructedFrame;
    if (CGRectIsEmpty(full))return;
    NSDictionary *shell=[NSDictionary dictionaryWithContentsOfFile:MTNativeShellRecordPath()];
    CGRect desired=CGRectZero;
    if (!MTNativeShellUsableRect(full,shell,&desired)) {
        MTTrialLog(@"native-shell-lost",@"scene disappeared/stale; stop external host");
        [self detach];
        self.attemptedForThisConnection=NO;
        return;
    }
    NSString *mode=@"native-CarPlay-app-usable-bounds";
    if (![self.lastDockLayoutMode isEqualToString:mode]) {
        self.lastDockLayoutMode=mode;
        MTTrialLog(@"dashboard-layout",[NSString stringWithFormat:
          @"mode=%@ nativeFrame=%@ shell=%@",
          mode,NSStringFromCGRect(desired),shell[@"Kind"]?:@"missing"]);
    }
    if (!CGRectEqualToRect(w.frame,desired)) {
        w.frame=desired;
        [w.rootViewController.view setNeedsLayout];
        [w.rootViewController.view layoutIfNeeded];
    }
}
- (void)detach {
    [[MTSceneHost sharedHost] stopAllHosts];
    if (self.bridgeWindow) {
        self.bridgeWindow.hidden=YES;
        self.bridgeWindow.rootViewController=nil;
        self.bridgeWindow=nil;
    }
    self.carPlayConnected=NO;
    self.mtUnobstructedFrame=CGRectZero;
    self.lastDockLayoutMode=nil;
    MTTrialLog(@"detached",@"all-hosts-stopped");
}
- (void)stopAndDisable {
    [[self class] setTrialEnabled:NO];
    // Ask Apple DashBoard for its real Home transition, then remove our host.
    [MTDashboardActivation requestNativeHomeFromSpringBoard];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self detach];
        self.attemptedForThisConnection=NO;
        self.lastEnabled=NO;
    });
}
- (void)stop {
    [self.pollTimer invalidate];self.pollTimer=nil;
    [self detach];self.observing=NO;
}
@end
