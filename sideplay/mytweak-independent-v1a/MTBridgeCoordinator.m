#import "MTBridgeCoordinator.h"
#import "MTBridgeRootViewController.h"
#import "MTSceneHost.h"
#import "MTTrialLog.h"
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
        self.lastEnabled=enabled;
        self.hadDisplay=present;
        return;
    }
    self.lastEnabled=enabled;
    self.hadDisplay=present;
    if (self.bridgeWindow || self.attemptedForThisConnection) return;
    self.attemptedForThisConnection=YES; // Fail closed: no retry storm.
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
        window.hidden=NO;
        MTTrialLog(@"window-shown",[NSString stringWithFormat:@"class=%@ frame=%@ bounds=%@",NSStringFromClass(window.class),NSStringFromCGRect(window.frame),NSStringFromCGRect(window.bounds)]);
    } @catch (NSException *ex) {
        MTTrialLog(@"window-exception",ex.reason ?: @"?");
        [self detach];
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
    MTTrialLog(@"detached",@"all-hosts-stopped");
}
- (void)stopAndDisable {
    [[self class] setTrialEnabled:NO];
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
