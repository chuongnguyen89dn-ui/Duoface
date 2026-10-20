// Independent DuoFace native CarPlay scene-entry proof. NO vendor bridge code.
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <fcntl.h>
#import <unistd.h>

static NSString *const DFCarPlayRole=@"UIWindowSceneSessionRoleCarPlay";
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
