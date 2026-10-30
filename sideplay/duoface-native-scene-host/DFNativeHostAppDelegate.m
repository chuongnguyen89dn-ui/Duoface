// Independent DuoFace native CarPlay scene-entry proof. NO vendor bridge code.
#import <UIKit/UIKit.h>
#import "DFDeepTrace.h"
#import "DFGeometrySnapshot119.h"
#import <CarPlay/CarPlay.h>
#import "DFNative12BasicController.h"
#import <Foundation/Foundation.h>
#import <fcntl.h>
#import <unistd.h>
#import <notify.h>
#import <math.h>

static NSString *const DFCarPlayRole=@"UIWindowSceneSessionRoleCarPlay";
static NSString *const DFTemplateRole=@"CPTemplateApplicationSceneSessionRoleApplication";
static NSString *const DFAckPath=@"/var/mobile/Library/Preferences/com.duoface.nativehost.touchowner.ack.plist";
static const char *const DFAckNotify="com.duoface.nativehost.touchowner.ack.v1";
void DFNativeHostLog(NSString *message) {
    DFDeepTrace(@"native-cpwindow",message?:@"-");
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
@property(nonatomic,copy) NSString *geometrySample;
@property(nonatomic,assign) NSTimeInterval geometrySampleTime;
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
        // Commit an inactive session tombstone BEFORE the Darwin stop notify.
        // A queued start callback must not read the previous fresh Active=YES
        // heartbeat and recreate the external UI after CarPlay Home.
        NSString *path=@"/var/mobile/Library/Preferences/com.duoface.nativehost.touchowner.session.plist";
        NSDictionary *record=[NSDictionary dictionaryWithContentsOfFile:path];
        BOOL revoked=YES;
        if([record[@"Session"] isEqualToString:self.touchSession]){
            NSDictionary *inactive=@{@"Version":@1,@"Session":self.touchSession,
                                     @"Active":@NO,@"Timestamp":@0};
            revoked=[inactive writeToFile:path atomically:YES];
            if(!revoked)
                [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        }
        int rc=notify_post("com.duoface.nativehost.touchowner.stop.v1");
        notify_cancel(self.touchRelayToken);
        DFNativeHostLog([NSString stringWithFormat:
             @"touchowner-stop reason=%@ revoked=%d notify=%d",
             reason?:@"unknown",revoked,rc]);
    }
    self.touchSession=nil;
    self.geometrySample=nil;self.geometrySampleTime=0;
    self.lastTouchSequence=0;
    [[NSFileManager defaultManager] removeItemAtPath:DFAckPath error:nil];
}
- (void)renewTouchOwnerHeartbeat:(NSTimer *)timer {
    if(timer!=self.touchHeartbeat || !self.touchSession)return;
    // QA124: resign is a transition, not proof of CarPlay Home/disconnect.
    // Only BACKGROUND/disconnect terminates this owner. The system can put a
    // still-connected external CarPlay scene into ForegroundInactive briefly
    // while the iPhone display changes lock state. Do not revoke the very
    // heartbeat the under-lock host policy needs to authenticate its scene.
    UISceneActivationState state=self.touchOwnerScene.activationState;
    BOOL mayRenew=state==UISceneActivationStateForegroundActive ||
                  state==UISceneActivationStateForegroundInactive;
    if(!self.carWindow || !self.basicController || !self.touchOwnerScene ||
       !mayRenew || self.carWindow.hidden ||
       !self.carWindow.screen || self.carWindow.screen==UIScreen.mainScreen){
        [self stopTouchOwnerWithReason:@"scene-background-or-external-window-lost"];
        return;
    }
    CPWindow *w=self.carWindow;
    CGRect frame=w.frame,safe=w.safeAreaLayoutGuide.layoutFrame;
    if(CGRectIsEmpty(safe))safe=w.bounds;
    CGRect content=CGRectMake(frame.origin.x+safe.origin.x,
         frame.origin.y+safe.origin.y,safe.size.width,safe.size.height);
    NSTimeInterval now=NSDate.date.timeIntervalSince1970;
    BOOL newSample=!self.geometrySample || now-self.geometrySampleTime>=3.0;
    if(newSample){self.geometrySample=NSUUID.UUID.UUIDString;self.geometrySampleTime=now;}
    NSDictionary *pulse=@{@"Version":@1,@"Session":self.touchSession,
            @"Active":@YES,@"Timestamp":@(NSDate.date.timeIntervalSince1970),
            @"ContentRect":NSStringFromCGRect(content),
            @"GeometrySample":self.geometrySample,@"GeometrySampleTime":@(self.geometrySampleTime)};
    if(newSample)DFGWrite(pulse,@{@"CPWindow":DFGWindow(w),
        @"PreClampContentRect":NSStringFromCGRect(content),
        @"EmptySafeFrameFallback":@(CGRectIsEmpty(w.safeAreaLayoutGuide.layoutFrame))});
    NSString *path=@"/var/mobile/Library/Preferences/com.duoface.nativehost.touchowner.session.plist";
    if(![pulse writeToFile:path atomically:YES])
        [self stopTouchOwnerWithReason:@"heartbeat-write-failed"];
}
- (void)startTouchOwnerForScene:(CPTemplateApplicationScene *)scene {
    if(self.touchSession || !self.carWindow || !self.basicController)return;
    self.touchOwnerScene=scene;
    // CPTemplate can be CONNECTED while CarPlay Home owns the foreground.
    // ForegroundInactive must NOT create standalone overlay windows:
    // sceneDidBecomeActive: is the only authority to start the chrome.
    if(scene.activationState!=UISceneActivationStateForegroundActive){
        DFNativeHostLog(@"touchowner-deferred-until-carplay-foreground-active");
        return;
    }
    self.touchSession=[NSUUID UUID].UUIDString;
    self.lastTouchSequence=0;
    [[NSFileManager defaultManager] removeItemAtPath:DFAckPath error:nil];
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
    if(scene==self.touchOwnerScene) {
        // QA124: UIKit's willResignActive is not a Home/disconnect event.
        // Home is explicitly handled by sceneDidEnterBackground: below;
        // disconnect has its own callback. No duplicate teardown here.
        DFNativeHostLog(@"qa124-scene-resign-retained-await-background");
    }
}
- (void)sceneDidEnterBackground:(UIScene *)scene {
    if(scene!=self.touchOwnerScene)return;
    // QA125 read-only evidence before normal teardown. The system CarPlay
    // process retaining its scenes does NOT prove this CPTemplate scene
    // remains foreground or that Home was not pressed. Never hold the overlay
    // across an unverified Home transition.
    BOOL exterior=self.carWindow && self.carWindow.screen &&
                  self.carWindow.screen!=UIScreen.mainScreen;
    DFNativeHostLog([NSString stringWithFormat:
        @"qa125-background-boundary own-state=%ld app-state=%ld protected-data=%d external-window=%d connected-scenes=%lu teardown=1",
        (long)scene.activationState,
        (long)UIApplication.sharedApplication.applicationState,
        UIApplication.sharedApplication.protectedDataAvailable,
        exterior,(unsigned long)UIApplication.sharedApplication.connectedScenes.count]);
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
    if(![record[@"Version"] isEqual:@2] ||
       ![session isKindOfClass:NSString.class] ||
       ![session isEqualToString:self.touchSession] ||
       ![sequence isKindOfClass:NSNumber.class] ||
       [sequence unsignedLongLongValue]<=self.lastTouchSequence ||
       [sequence unsignedLongLongValue]>1000000000ULL ||
       ![timestamp isKindOfClass:NSNumber.class] ||
       ![action isKindOfClass:NSString.class])return;
    NSTimeInterval age=NSDate.date.timeIntervalSince1970-[timestamp doubleValue];
    if(!isfinite(age) || age<0 || age>2.0)return;
    if(![@[@"App",@"Zoom",@"Style",@"Close",@"SWAP",@"Ratio",@"FocusLeft",@"FocusRight",@"FocusSlot2",@"FocusSlot3",@"Restore"] containsObject:action])return;
    id ratio=record[@"Ratio"];
    if([action isEqualToString:@"Ratio"]) {
        if(![ratio isKindOfClass:NSNumber.class] ||
           !isfinite([ratio doubleValue]) ||
           [ratio doubleValue]<1.0/3.0 ||
           [ratio doubleValue]>2.0/3.0)return;
    }else if([action isEqualToString:@"App"] ||
             [action isEqualToString:@"Close"]){
        if(![ratio isKindOfClass:NSNumber.class] ||
           ([(NSNumber *)ratio integerValue]<0 ||
            [(NSNumber *)ratio integerValue]>3))return;
    }else if(ratio!=nil)return;
    // CarPlay only acknowledges the REAL post-action SpringBoard state.
    // It must never execute a second, fake split manager or mutate CPWindow.
    NSDictionary *state=record[@"State"];
    if(![state isKindOfClass:NSDictionary.class] ||
       ![state[@"Version"] isEqual:@2] ||
       ![state[@"Owner"] isEqualToString:@"SpringBoard"])return;
    for(NSString *key in @[@"Ratio",@"Vertical",@"Swapped",@"Focus",
                             @"SelectedSlot",@"SlotCount",@"RunningScenes",
                             @"PendingScenes",@"StartupActive",@"PickerVisible",
                             @"ActiveSlots",@"Preset",@"SplitPreset",@"SplitMode"]){
        if(![state[key] isKindOfClass:NSNumber.class])return;
    }
    double currentRatio=[state[@"Ratio"] doubleValue];
    NSInteger focus=[state[@"Focus"] integerValue];
    NSInteger count=[state[@"SlotCount"] integerValue];
    NSInteger selected=[state[@"SelectedSlot"] integerValue];
    NSInteger active=[state[@"ActiveSlots"] integerValue];
    NSInteger preset=[state[@"Preset"] integerValue];
    NSInteger splitPreset=[state[@"SplitPreset"] integerValue];
    NSInteger splitMode=[state[@"SplitMode"] integerValue];
    // Original presetSelected: @0xaa4f0 propagates the SAME chosen tag to
    // both splitPreset and splitMode before notifying Dashboard.
    if(splitPreset!=preset || splitMode!=preset)return;
    if(!isfinite(currentRatio) || currentRatio<1.0/3.0 ||
       currentRatio>2.0/3.0 || count!=4 || active<1 || active>4 ||
       preset<0 || preset>8 || focus< -1 || focus>=active ||
       selected<0 || selected>=active ||
       [state[@"RunningScenes"] integerValue]<0 ||
       [state[@"RunningScenes"] integerValue]>count ||
       [state[@"PendingScenes"] integerValue]<0 ||
       [state[@"PendingScenes"] integerValue]>count)return;
    if([action isEqualToString:@"Ratio"] &&
       fabs(currentRatio-[ratio doubleValue])>0.06)return;
    if([action isEqualToString:@"Restore"] && focus!= -1)return;
    if([action isEqualToString:@"FocusLeft"] && focus!=0)return;
    if([action isEqualToString:@"FocusRight"] && focus!=1)return;
    if([action isEqualToString:@"FocusSlot2"] && focus!=2)return;
    if([action isEqualToString:@"FocusSlot3"] && focus!=3)return;
    // Zoom is accepted ONLY when the CarPlay-process native AppDock owner
    // actually returned its receipt AND the independent SpringBoard host
    // applied its own geometry. UI tap alone is never a success signal.
    BOOL isWholeHostZoom=[action isEqualToString:@"Zoom"];
    NSDictionary *zr=record[@"ZoomReceipt"];
    BOOL verified=NO;
    NSString *zoomReason=@"missing-real-native-dock-and-host-receipt";
    if(isWholeHostZoom && [zr isKindOfClass:NSDictionary.class]){
        BOOL expanded=[zr[@"Expanded"] boolValue];
        BOOL stateExpanded=[state[@"HostFullscreenGeometry"] boolValue];
        BOOL matchingSession=[zr[@"Session"] isEqualToString:self.touchSession];
        BOOL owner=[zr[@"DockOwnerVerified"] isEqual:@YES] &&
                   [zr[@"Applied"] isEqual:@YES];
        BOOL dock=[zr[@"DockHidden"] isEqual:@(expanded)];
        BOOL geometry=[zr[@"HostFullscreenGeometry"] isEqual:@(expanded)] &&
                      stateExpanded==expanded;
        BOOL request=[zr[@"RequestID"] isKindOfClass:NSString.class] &&
                     [[NSUUID alloc] initWithUUIDString:zr[@"RequestID"]]!=nil;
        verified=matchingSession && owner && dock && geometry && request;
        if(!verified && [zr[@"Reason"] isKindOfClass:NSString.class])
            zoomReason=zr[@"Reason"];
        DFNativeHostLog(verified?
           (expanded?@"native12-zoom-enter-verified-two-owner":
                      @"native12-zoom-exit-verified-two-owner"):
                      @"native12-zoom-rejected-no-two-owner-proof");
    }
    BOOL accepted=!isWholeHostZoom || verified;
    self.lastTouchSequence=[sequence unsignedIntegerValue];
    NSDictionary *ack=@{@"Version":@2,@"Session":session,
                         @"Sequence":sequence,@"Accepted":@(accepted),
                         @"Reason":(isWholeHostZoom && !verified)?zoomReason:@"",
                         @"Action":action,@"Owner":@"SpringBoard",
                         @"Timestamp":@(NSDate.date.timeIntervalSince1970)};
    if(![ack writeToFile:DFAckPath atomically:YES]){
        DFNativeHostLog(@"touchowner-state-ack-write-failed");
        return;
    }
    int ackResult=notify_post(DFAckNotify);
    DFNativeHostLog([NSString stringWithFormat:
       @"touchowner-state-ack session=%@ seq=%lu action=%@ ratio=%@ focus=%ld scenes=%@ notify=%d",
       session,(unsigned long)self.lastTouchSequence,action,
       state[@"Ratio"],(long)focus,state[@"RunningScenes"],ackResult]);
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
    // Revoke the sole external SpringBoard owner FIRST. Native12's
    // disconnect order must not leave a live overlay after CPWindow retires.
    [self stopTouchOwnerWithReason:@"template-disconnected"];
    if(window && window==self.carWindow)window.rootViewController=nil;
    self.interfaceController=nil;
    self.carWindow=nil;
    self.basicController=nil;
    self.touchCount=0;
    self.touchOwnerScene=nil;
    DFNativeHostLog(@"native-carplay-template-scene-disconnected");
}
@end
