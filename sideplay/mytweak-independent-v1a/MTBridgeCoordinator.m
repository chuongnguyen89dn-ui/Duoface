#import "MTBridgeCoordinator.h"
#import "MTBridgeWindow.h"
#import "MTSceneHost.h"
#import <objc/message.h>
#import "MTBridgeRootViewController.h"

@interface MTBridgeCoordinator ()
@property (nonatomic, strong, nullable) UIWindow *bridgeWindow;
@property (nonatomic, assign, readwrite, getter=isCarPlayConnected) BOOL carPlayConnected;
@property(nonatomic) BOOL observing;
@end

@implementation MTBridgeCoordinator

+ (instancetype)sharedCoordinator {
    static MTBridgeCoordinator *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (void)start {
    if (self.observing) return;
    self.observing=YES;
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(screenDidConnect:)
               name:UIScreenDidConnectNotification
             object:nil];
    [nc addObserver:self
           selector:@selector(screenDidDisconnect:)
               name:UIScreenDidDisconnectNotification
             object:nil];

    // Trường hợp màn ngoài đã kết nối trước khi tweak load xong.
    for (UIScreen *screen in [UIScreen screens]) {
        if (screen != [UIScreen mainScreen]) {
            [self attachToScreen:screen];
            break;
        }
    }
    NSLog(@"[MyTweak] Bridge coordinator started");
}

- (void)stop {
    if (!self.observing) return;
    self.observing=NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self detach];
}

- (void)screenDidConnect:(NSNotification *)note {
    UIScreen *screen = (UIScreen *)note.object;
    if (screen && screen != [UIScreen mainScreen]) {
        [self attachToScreen:screen];
    }
}

- (void)screenDidDisconnect:(NSNotification *)note {
    UIScreen *screen = (UIScreen *)note.object;
    if (screen && self.bridgeWindow && self.bridgeWindow.screen == screen) {
        [self detach];
    }
}

// Resolve *the CarPlay* display, not merely any non-primary UIScreen.
static id MTGet(id target,NSString *name) {
    SEL sel=NSSelectorFromString(name);
    if (!target || ![target respondsToSelector:sel]) return nil;
    return ((id(*)(id,SEL))objc_msgSend)(target,sel);
}
static id MTCarPlayDisplay(void) {
    id external=MTGet(NSClassFromString(@"AVExternalDevice"),@"currentCarPlayExternalDevice");
    NSArray *IDs=MTGet(external,@"screenIDs");
    if (![IDs isKindOfClass:NSArray.class] || !IDs.count) return nil;
    id displays=MTGet(NSClassFromString(@"CADisplay"),@"displays");
    for (id display in displays) {
        id uniqueID=MTGet(display,@"uniqueId");
        if (uniqueID && [IDs containsObject:uniqueID]) return display;
    }
    return nil;
}
// The scene-hosting controller needs SpringBoard's external UIRootSceneWindow
// contract, not a generic UIWindow.screen replacement. No CB* runtime used.
- (void)attachToScreen:(UIScreen *)screen {
    if (self.bridgeWindow) return;
    id display=MTCarPlayDisplay();
    Class config=NSClassFromString(@"FBSDisplayConfiguration");
    Class rootWindow=NSClassFromString(@"UIRootSceneWindow");
    SEL configInit=NSSelectorFromString(@"initWithCADisplay:isMainDisplay:");
    SEL windowInit=NSSelectorFromString(@"initWithDisplayConfiguration:");
    if (!display || ![config instancesRespondToSelector:configInit] ||
        ![rootWindow instancesRespondToSelector:windowInit]) {
        NSLog(@"[MyTweakScene] event=display-preflight-failed screen=%@ CarPlay display or UIRootSceneWindow unavailable",screen);
        return;
    }
    @try {
        id displayConfiguration=((id(*)(id,SEL,id,BOOL))objc_msgSend)([config alloc],configInit,display,NO);
        UIWindow *window=((id(*)(id,SEL,id))objc_msgSend)([rootWindow alloc],windowInit,displayConfiguration);
        if (!window || CGRectIsEmpty(window.bounds)) {
            NSLog(@"[MyTweakScene] event=window-empty"); return;
        }
        MTBridgeRootViewController *root=[MTBridgeRootViewController new];
        window.rootViewController=root;
        window.backgroundColor=UIColor.clearColor;
        window.opaque=NO;
        window.windowLevel=UIWindowLevelNormal;
        window.hidden=NO;
        self.bridgeWindow=window;
        self.carPlayConnected=YES;
        NSLog(@"[MyTweakScene] event=carplay-window-ready class=%@ bounds=%@",NSStringFromClass([window class]),NSStringFromCGRect(window.bounds));
    } @catch(NSException *e) {
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
