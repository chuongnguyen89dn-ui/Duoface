#import "MTBridgeCoordinator.h"
#import "MTSceneHost.h"
#import <objc/message.h>
#import "MTBridgeRootViewController.h"

@interface MTBridgeCoordinator ()
@property(nonatomic,strong,nullable) UIWindow *bridgeWindow;
@property(nonatomic,assign,readwrite,getter=isCarPlayConnected) BOOL carPlayConnected;
@property(nonatomic) BOOL observing;
@end

@implementation MTBridgeCoordinator
+ (instancetype)sharedCoordinator {
    static MTBridgeCoordinator *shared=nil;
    static dispatch_once_t once;
    dispatch_once(&once,^{shared=[MTBridgeCoordinator new];});
    return shared;
}
- (void)start {
    if (self.observing) return;
    self.observing=YES;
    NSNotificationCenter *nc=NSNotificationCenter.defaultCenter;
    [nc addObserver:self selector:@selector(screenDidConnect:)
              name:UIScreenDidConnectNotification object:nil];
    [nc addObserver:self selector:@selector(screenDidDisconnect:)
              name:UIScreenDidDisconnectNotification object:nil];
    for (UIScreen *screen in UIScreen.screens)
        if (screen!=UIScreen.mainScreen) { [self attachToScreen:screen]; break; }
    NSLog(@"[MyTweakScene] event=screen-observer-started");
}
- (void)stop {
    if (!self.observing) return;
    self.observing=NO;
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [self detach];
}
- (void)screenDidConnect:(NSNotification *)note {
    UIScreen *screen=note.object;
    if (screen && screen!=UIScreen.mainScreen) [self attachToScreen:screen];
}
- (void)screenDidDisconnect:(NSNotification *)note {
    UIScreen *screen=note.object;
    if (screen && self.bridgeWindow && self.bridgeWindow.screen==screen)
        [self detach];
}
static id MTGet(id target,NSString *name) {
    SEL selector=NSSelectorFromString(name);
    if (!target || ![target respondsToSelector:selector]) return nil;
    return ((id(*)(id,SEL))objc_msgSend)(target,selector);
}
static id MTCarPlayDisplay(void) {
    id external=MTGet(NSClassFromString(@"AVExternalDevice"),@"currentCarPlayExternalDevice");
    NSArray *ids=MTGet(external,@"screenIDs");
    if (![ids isKindOfClass:NSArray.class] || !ids.count) return nil;
    id displays=MTGet(NSClassFromString(@"CADisplay"),@"displays");
    for (id display in displays) {
        id unique=MTGet(display,@"uniqueId");
        if (unique && [ids containsObject:unique]) return display;
    }
    return nil;
}
// Exactly one SpringBoard UIRootSceneWindow. Do not run with a legacy owner.
- (void)attachToScreen:(UIScreen *)screen {
    if (self.bridgeWindow) return;
    id display=MTCarPlayDisplay();
    Class configuration=NSClassFromString(@"FBSDisplayConfiguration");
    Class windowClass=NSClassFromString(@"UIRootSceneWindow");
    SEL initConfig=NSSelectorFromString(@"initWithCADisplay:isMainDisplay:");
    SEL initWindow=NSSelectorFromString(@"initWithDisplayConfiguration:");
    if (!display || ![configuration instancesRespondToSelector:initConfig] ||
        ![windowClass instancesRespondToSelector:initWindow]) {
        NSLog(@"[MyTweakScene] event=display-preflight-failed screen=%@",screen);
        return;
    }
    @try {
        id config=((id(*)(id,SEL,id,BOOL))objc_msgSend)([configuration alloc],initConfig,display,NO);
        UIWindow *window=((id(*)(id,SEL,id))objc_msgSend)([windowClass alloc],initWindow,config);
        if (!window || CGRectIsEmpty(window.bounds)) {
            NSLog(@"[MyTweakScene] event=window-empty");
            return;
        }
        window.rootViewController=[MTBridgeRootViewController new];
        window.backgroundColor=UIColor.clearColor;
        window.opaque=NO;
        window.windowLevel=UIWindowLevelNormal;
        window.hidden=NO;
        self.bridgeWindow=window;
        self.carPlayConnected=YES;
        NSLog(@"[MyTweakScene] event=carplay-window-ready class=%@ bounds=%@",
              NSStringFromClass(window.class),NSStringFromCGRect(window.bounds));
    } @catch (NSException *e) {
        NSLog(@"[MyTweakScene] event=carplay-window-exception reason=%@",e.reason);
    }
}
- (void)detach {
    [[MTSceneHost sharedHost] stopAllHosts];
    self.bridgeWindow.hidden=YES;
    self.bridgeWindow.rootViewController=nil;
    self.bridgeWindow=nil;
    self.carPlayConnected=NO;
    NSLog(@"[MyTweakScene] event=carplay-detached");
}
@end
