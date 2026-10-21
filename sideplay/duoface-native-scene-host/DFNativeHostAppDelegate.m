// Independent DuoFace native CarPlay scene-entry proof. NO vendor bridge code.
#import <UIKit/UIKit.h>
#import <CarPlay/CarPlay.h>
#import "DFNative12BasicController.h"
#import <Foundation/Foundation.h>
#import <fcntl.h>
#import <unistd.h>

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
- (void)templateApplicationScene:(CPTemplateApplicationScene *)scene
       didConnectInterfaceController:(CPInterfaceController *)controller
                            toWindow:(CPWindow *)window {
    if(![scene.session.role isEqualToString:DFTemplateRole] || !controller || !window) {
        DFNativeHostLog(@"template-scene-rejected-invalid-role-or-window");
        return;
    }
    self.interfaceController=controller;
    self.carWindow=window; // Provided by CarPlay, not created with UIWindow alloc.
    // Native12 basic visual test, hosted ONLY in CarPlay-issued CPWindow.
    DFNative12BasicController *root=[DFNative12BasicController new];
    self.basicController=root;
    window.rootViewController=root;
    CPMapTemplate *map=[CPMapTemplate new];
    // CPMapTemplate owns CarPlay touch dispatch. Ordinary UIButton gestures
    // in its map surface are not a supported touch entry point. Probe with
    // system-owned CPMapButtons to distinguish missing input from UI wiring.
    __weak typeof(self) weakSelf=self;
    NSArray *titles=@[@"LEFT",@"RIGHT",@"SWAP"];
    NSMutableArray *buttons=[NSMutableArray array];
    for(NSString *title in titles){
        CPMapButton *button=[[CPMapButton alloc] initWithHandler:^(CPMapButton *pressed){
            (void)pressed;
            __strong typeof(weakSelf) strongSelf=weakSelf;
            if(!strongSelf)return;
            strongSelf.touchCount++;
            DFNativeHostLog([NSString stringWithFormat:@"carplay-template-touch-confirmed button=%@ count=%lu",title,(unsigned long)strongSelf.touchCount]);
            if([title isEqualToString:@"SWAP"]){
                [strongSelf.basicController swap:nil];
            } else {
                strongSelf.basicController.view.accessibilityValue=[NSString stringWithFormat:@"CarPlay touch %@ %lu",title,(unsigned long)strongSelf.touchCount];
            }
        }];
        button.image=[UIImage systemImageNamed:([title isEqualToString:@"SWAP"]?@"arrow.left.arrow.right":@"hand.tap")];
        [buttons addObject:button];
    }
    map.mapButtons=buttons;
    [controller setRootTemplate:map animated:NO completion:nil];
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
    DFNativeHostLog(@"native-carplay-template-scene-disconnected");
}
@end
