// Independent DuoFace native CarPlay scene-entry proof. NO vendor bridge code.
#import <UIKit/UIKit.h>
#import <CarPlay/CarPlay.h>
#import "DFNative12BasicController.h"
#import <Foundation/Foundation.h>
#import <fcntl.h>
#import <unistd.h>
#import <notify.h>
#import <math.h>

static NSString *const DFCarPlayRole=@"UIWindowSceneSessionRoleCarPlay";
static NSString *const DFTemplateRole=@"CPTemplateApplicationSceneSessionRoleApplication";
void DFNativeHostLog(NSString *message) {
    NSString *line=[NSString stringWithFormat:@"[DuoFaceNativeHost] %@\n",message];
    NSLog(@"%@",line);
    int fd=open("/var/mobile/Library/Logs/DuoFaceNativeSceneJoin.log",
                O_WRONLY|O_APPEND|O_CREAT,0644);
    if(fd>=0){NSData *b=[line dataUsingEncoding:NSUTF8StringEncoding];
        (void)write(fd,b.bytes,b.length);close(fd);}
}
@interface DFNativeHostRootController : UIViewController
@property(nonatomic,assign) BOOL carPlay;
- (instancetype)initWithCarPlay:(BOOL)carPlay;
@end
@interface DFNativeHostPhoneSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic,strong) UIWindow *window;
@end
@interface DFNativeHostCarSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic,strong) UIWindow *window;
@end
// An independent CarPlay template entry point, separate from the earlier
// generic UIKit role. CarPlay provides the CPWindow; we never create one.
@interface DFNativeHostTemplateSceneDelegate : UIResponder <CPTemplateApplicationSceneDelegate>
@property(nonatomic,strong) CPInterfaceController *interfaceController;
@property(nonatomic,strong) CPWindow *carWindow;
@property(nonatomic,strong) DFNative12BasicController *basicController;
@property(nonatomic,assign) NSUInteger touchCount;
@property(nonatomic,copy) NSString *touchSession;
@property(nonatomic,assign) int touchRelayToken;
@property(nonatomic,assign) NSUInteger lastTouchSequence;
@property(nonatomic,strong) NSTimer *touchHeartbeat;
@property(nonatomic,weak) CPTemplateApplicationScene *touchOwnerScene;
- (void)consumeTouchCommand;
- (void)startTouchOwnerForScene:(CPTemplateApplicationScene *)scene;
- (void)stopTouchOwnerWithReason:(NSString *)reason;
- (void)renewTouchOwnerHeartbeat:(NSTimer *)timer;
@end
@interface DFNativeHostAppDelegate : UIResponder <UIApplicationDelegate>
@end
@implementation DFNativeHostAppDelegate
- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)options {
    (void)app;(void)options;
    DFNativeHostLog(@"application-launched, waiting for system-issued window scenes");
    return YES;
}
- (UISceneConfiguration *)application:(UIApplication *)app
 configurationForConnectingSceneSession:(UISceneSession *)session
 options:(UISceneConnectionOptions *)options API_AVAILABLE(ios(13.0)) {
    (void)app;(void)options;
    NSString *role=session.role;
    if([role isEqualToString:DFTemplateRole]){
        DFNativeHostLog(@"CarPlay-template-role-issued-by-system");
        UISceneConfiguration *config=[UISceneConfiguration
            configurationWithName:@"DuoFace Template CarPlay Scene" sessionRole:role];
        config.sceneClass=CPTemplateApplicationScene.class;
        config.delegateClass=DFNativeHostTemplateSceneDelegate.class;
        return config;
    }
    if([role isEqualToString:DFCarPlayRole]){
        DFNativeHostLog(@"CarPlay-role-request-received native-scene-no-window-created-yet");
        UISceneConfiguration *config=[UISceneConfiguration
            configurationWithName:@"DuoFace Native CarPlay Scene" sessionRole:role];
        config.sceneClass=UIWindowScene.class;
        config.delegateClass=DFNativeHostCarSceneDelegate.class;
        return config;
    }
    if([role isEqualToString:UIWindowSceneSessionRoleApplication]){
        UISceneConfiguration *config=[UISceneConfiguration
            configurationWithName:@"DuoFace iPhone Status" sessionRole:role];
        config.sceneClass=UIWindowScene.class;
        config.delegateClass=DFNativeHostPhoneSceneDelegate.class;
        return config;
    }
    // A template-role CarPlay scene is NOT an ordinary UIWindowScene.
    // Never change its role AFTER UIKit construction; fail closed.
    DFNativeHostLog([NSString stringWithFormat:@"unsupported-scene-role=%@; no scene hijack",role]);
    return [UISceneConfiguration configurationWithName:@"Unsupported" sessionRole:role];
}
@end

@implementation DFNativeHostPhoneSceneDelegate
- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session
  options:(UISceneConnectionOptions *)options {
    (void)session;(void)options;
    if(![scene isKindOfClass:UIWindowScene.class])return;
    UIWindowScene *ws=(UIWindowScene *)scene;
    if(ws.screen!=UIScreen.mainScreen)return;
    self.window=[[UIWindow alloc] initWithWindowScene:ws];
    self.window.rootViewController=[[DFNativeHostRootController alloc] initWithCarPlay:NO];
    [self.window makeKeyAndVisible];
    DFNativeHostLog(@"phone-scene-connected");
}
- (void)sceneDidDisconnect:(UIScene *)scene {
    (void)scene;self.window.hidden=YES;self.window=nil;
    DFNativeHostLog(@"phone-scene-disconnected");
}
@end

@implementation DFNativeHostCarSceneDelegate
- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session
  options:(UISceneConnectionOptions *)options {
    (void)options;
    if(![scene isKindOfClass:UIWindowScene.class] ||
       ![session.role isEqualToString:DFCarPlayRole]){
        DFNativeHostLog(@"car-scene-refused-role-or-type");return;
    }
    UIWindowScene *ws=(UIWindowScene *)scene;
    if(!ws.screen || ws.screen==UIScreen.mainScreen){
        DFNativeHostLog(@"car-scene-refused-main-screen");return;
    }
    // A CarPlay-owned UIWindowScene must be provided by UIKit FIRST.
    // Do not create any foreign-display window or change the native system chrome.
    self.window=[[UIWindow alloc] initWithWindowScene:ws];
    self.window.rootViewController=[[DFNativeHostRootController alloc] initWithCarPlay:YES];
    [self.window makeKeyAndVisible];
    DFNativeHostLog([NSString stringWithFormat:
      @"native-carplay-scene-connected session=%@ display=%@ bounds=%@ safe=%@",
      session.persistentIdentifier,ws.screen,NSStringFromCGRect(ws.coordinateSpace.bounds),
      NSStringFromUIEdgeInsets(self.window.safeAreaInsets)]);
}
- (void)sceneDidBecomeActive:(UIScene *)scene {
    if(self.window && self.window.windowScene==scene)
      DFNativeHostLog(@"native-carplay-scene-active natural-system-Dock-unchanged");
}
- (void)sceneWillResignActive:(UIScene *)scene {
    if(self.window && self.window.windowScene==scene)
      DFNativeHostLog(@"native-carplay-scene-inactive");
}
- (void)sceneDidDisconnect:(UIScene *)scene {
    if(self.window && self.window.windowScene==scene){
        self.window.hidden=YES;self.window.rootViewController=nil;self.window=nil;
        DFNativeHostLog(@"native-carplay-scene-disconnected release-owned-window");
    }
}
@end

// Navigation-template acceptance is a distinct path from native UIKit
// UIWindowSceneSessionRoleCarPlay. Never spoof a synthetic scene or system Dock.
@implementation DFNativeHostTemplateSceneDelegate
// CPTemplate can stay connected while CarPlay Home is frontmost.
// A connected window is NOT an active input-owner session.
- (void)stopTouchOwnerWithReason:(NSString *)reason {
    [self.touchHeartbeat invalidate];self.touchHeartbeat=nil;
    if(self.touchSession){
        int rc=notify_post("com.duoface.nativehost.touchowner.stop.v1");
        notify_cancel(self.touchRelayToken);
        NSString *path=@"/var/mobile/Library/Preferences/com.duoface.nativehost.touchowner.session.plist";
        NSDictionary *record=[NSDictionary dictionaryWithContentsOfFile:path];
        if([record[@"Session"] isEqualToString:self.touchSession])
            [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        DFNativeHostLog([NSString stringWithFormat:
             @"touchowner-stop reason=%@ notify=%d",reason?:@"unknown",rc]);
    }
    self.touchSession=nil;
    self.lastTouchSequence=0;
}
- (void)renewTouchOwnerHeartbeat:(NSTimer *)timer {
    if(timer!=self.touchHeartbeat || !self.touchSession)return;
    if(!self.carWindow || !self.basicController || !self.touchOwnerScene ||
       self.touchOwnerScene.activationState!=UISceneActivationStateForegroundActive){
        [self stopTouchOwnerWithReason:@"not-active-or-home"];
        return;
    }
    CPWindow *w=self.carWindow;
    CGRect frame=w.frame,safe=w.safeAreaLayoutGuide.layoutFrame;
    if(CGRectIsEmpty(safe))safe=w.bounds;
    CGRect content=CGRectMake(frame.origin.x+safe.origin.x,
         frame.origin.y+safe.origin.y,safe.size.width,safe.size.height);
    NSDictionary *pulse=@{@"Version":@1,@"Session":self.touchSession,
            @"Active":@YES,@"Timestamp":@(NSDate.date.timeIntervalSince1970),
            @"ContentRect":NSStringFromCGRect(content)};
    NSString *path=@"/var/mobile/Library/Preferences/com.duoface.nativehost.touchowner.session.plist";
    if(![pulse writeToFile:path atomically:YES])
        [self stopTouchOwnerWithReason:@"heartbeat-write-failed"];
}
- (void)startTouchOwnerForScene:(CPTemplateApplicationScene *)scene {
    if(self.touchSession || !self.carWindow || !self.basicController)return;
    self.touchOwnerScene=scene;
    if(scene.activationState==UISceneActivationStateBackground ||
       scene.activationState==UISceneActivationStateUnattached)return;
    self.touchSession=[NSUUID UUID].UUIDString;
    self.lastTouchSequence=0;
    __weak typeof(self) weakOwner=self;
    int token=-1;
    int registered=notify_register_dispatch(
         "com.duoface.nativehost.touchowner.command.v1",&token,
         dispatch_get_main_queue(),^(int received) {
             (void)received;[weakOwner consumeTouchCommand];
         });
    if(registered!=0){
        DFNativeHostLog(@"touchowner-command-listener-failed");
        self.touchSession=nil;return;
    }
    self.touchRelayToken=token;
    NSTimer *timer=[NSTimer timerWithTimeInterval:0.75 target:self
          selector:@selector(renewTouchOwnerHeartbeat:) userInfo:nil repeats:YES];
    self.touchHeartbeat=timer;
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    // First write must be fresh BEFORE requesting external input controls.
    [self renewTouchOwnerHeartbeat:timer];
    if(!self.touchSession)return;
    int rc=notify_post("com.duoface.nativehost.touchowner.start.v1");
    DFNativeHostLog([NSString stringWithFormat:
         @"touchowner-start session=%@ notify=%d",self.touchSession,rc]);
}
- (void)sceneWillResignActive:(UIScene *)scene {
    if(scene==self.touchOwnerScene)
        [self stopTouchOwnerWithReason:@"scene-resigned-carplay-home"];
}
- (void)sceneDidEnterBackground:(UIScene *)scene {
    if(scene==self.touchOwnerScene)
        [self stopTouchOwnerWithReason:@"scene-background"];
}
- (void)sceneDidDisconnect:(UIScene *)scene {
    if(scene==self.touchOwnerScene)
        [self stopTouchOwnerWithReason:@"scene-disconnected"];
}
- (void)sceneDidBecomeActive:(UIScene *)scene {
    if([scene isKindOfClass:CPTemplateApplicationScene.class] &&
       self.carWindow && self.basicController)
        [self startTouchOwnerForScene:(CPTemplateApplicationScene *)scene];
}
// A session-bound audit stream from real hosted-scene controls. The external
// source owner alone performs split, picker, focus, app scene and teardown.
- (void)consumeTouchCommand {
    if(!self.basicController || !self.touchSession)return;
    NSString *path=@"/var/mobile/Library/Preferences/com.duoface.nativehost.touchowner.command.plist";
    NSDictionary *record=[NSDictionary dictionaryWithContentsOfFile:path];
    id session=record[@"Session"], sequence=record[@"Sequence"];
    id timestamp=record[@"Timestamp"],action=record[@"Action"];
    if(![record[@"Version"] isEqual:@1] ||
       ![session isKindOfClass:NSString.class] ||
       ![session isEqualToString:self.touchSession] ||
       ![sequence isKindOfClass:NSNumber.class] ||
       [sequence unsignedLongLongValue]<=self.lastTouchSequence ||
       [sequence unsignedLongLongValue]>1000000000ULL ||
       ![timestamp isKindOfClass:NSNumber.class] ||
       ![action isKindOfClass:NSString.class])return;
    NSTimeInterval age=NSDate.date.timeIntervalSince1970-[timestamp doubleValue];
    if(!isfinite(age) || age<0 || age>2.0)return;
    if(![@[@"App",@"Zoom",@"Style",@"Close",@"SWAP",@"Ratio",@"FocusLeft",@"FocusRight",@"Restore"] containsObject:action])return;
    id ratio=record[@"Ratio"];
    if([action isEqualToString:@"Ratio"]) {
        if(![ratio isKindOfClass:NSNumber.class] ||
           !isfinite([ratio doubleValue]) ||
           [ratio doubleValue]<1.0/3.0 ||
           [ratio doubleValue]>2.0/3.0)return;
    }else if([action isEqualToString:@"App"] ||
             [action isEqualToString:@"Close"]){
        if(![ratio isKindOfClass:NSNumber.class] ||
           ([(NSNumber *)ratio integerValue]!=0 &&
            [(NSNumber *)ratio integerValue]!=1))return;
    }else if(ratio!=nil)return;
    self.lastTouchSequence=[sequence unsignedIntegerValue];
    if([action isEqualToString:@"Ratio"])
        [self.basicController setPresetRatio:(CGFloat)[ratio doubleValue]];
    else if([action isEqualToString:@"App"]||[action isEqualToString:@"Close"])
        [self.basicController performCarPlayControl:action slot:[(NSNumber *)ratio integerValue]];
    else
        [self.basicController performCarPlayControl:action];
    DFNativeHostLog([NSString stringWithFormat:
      @"touchowner-command-applied session=%@ seq=%lu action=%@ ratio=%@",
      session,(unsigned long)self.lastTouchSequence,action,ratio?:@"-"]);
}
- (void)templateApplicationScene:(CPTemplateApplicationScene *)scene
       didConnectInterfaceController:(CPInterfaceController *)controller
                            toWindow:(CPWindow *)window {
    if(![scene.session.role isEqualToString:DFTemplateRole] || !controller || !window) {
        DFNativeHostLog(@"template-scene-rejected-invalid-role-or-window");
        return;
    }
    self.interfaceController=controller;
    self.carWindow=window; // Provided by CarPlay, not created with UIWindow alloc.
    // Do not expose CPMapTemplate dummy buttons: all live actions belong
    // to the one source-owned external native DFNative12Chrome and real scenes.
    DFNative12BasicController *root=[DFNative12BasicController new];
    self.basicController=root;
    window.rootViewController=root;
    CPMapTemplate *map=[CPMapTemplate new];
    map.automaticallyHidesNavigationBar=YES;
    map.hidesButtonsWithNavigationBar=YES;
    map.leadingNavigationBarButtons=@[];
    map.trailingNavigationBarButtons=@[];
    map.mapButtons=@[];
    [controller setRootTemplate:map animated:NO completion:nil];
    [self startTouchOwnerForScene:scene];
    DFNativeHostLog(@"native-carplay-template-scene-connected UIKit-issued CPWindow, not app-host success");
}
- (void)templateApplicationScene:(CPTemplateApplicationScene *)scene
    didDisconnectInterfaceController:(CPInterfaceController *)controller
                           fromWindow:(CPWindow *)window {
    (void)scene;(void)controller;
    // Release only our contents; CarPlay retains ownership of its window.
    if(window && window==self.carWindow)window.rootViewController=nil;
    self.interfaceController=nil;
    self.carWindow=nil;
    self.basicController=nil;
    self.touchCount=0;
    [self stopTouchOwnerWithReason:@"template-disconnected"];
    self.touchOwnerScene=nil;
    DFNativeHostLog(@"native-carplay-template-scene-disconnected");
}
@end
