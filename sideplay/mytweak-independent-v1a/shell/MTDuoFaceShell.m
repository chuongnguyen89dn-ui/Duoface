// A NEW independent app, whose real UIWindowScene is created by CarPlay.
// It neither embeds upstream binaries nor draws any Apple system Dock.
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <math.h>
static NSString *const kShellScenePath=@"/var/mobile/Library/Preferences/com.duoface.mytweak.shell-scene.plist";
static NSString *const kShellLog=@"/var/mobile/Library/Logs/MyTweakShell.log";
static void MTShellLog(NSString *reason,NSString *details) {
    NSString *line=[NSString stringWithFormat:@"[MyTweakShell] %@ %@\n",reason,details?:@""];
    NSLog(@"%@",line);
    [[NSFileManager defaultManager] createDirectoryAtPath:[kShellLog stringByDeletingLastPathComponent]
          withIntermediateDirectories:YES attributes:nil error:nil];
    NSFileHandle *f=[NSFileHandle fileHandleForWritingAtPath:kShellLog];
    if (!f) {
        [[NSFileManager defaultManager] createFileAtPath:kShellLog contents:nil attributes:nil];
        f=[NSFileHandle fileHandleForWritingAtPath:kShellLog];
    }
    @try {
        [f seekToEndOfFile];
        [f writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
        [f closeFile];
    } @catch(NSException *e) { NSLog(@"[MyTweakShell] log write %@",e.name); }
}
@interface MTDuoFaceShellScene : UIResponder <UIWindowSceneDelegate>
@property(nonatomic,strong) UIWindow *window;
@property(nonatomic,strong) NSTimer *geometryTimer;
@end
@implementation MTDuoFaceShellScene
- (void)publishGeometry {
    UIWindow *window=self.window;
    UIScreen *display=window.screen;
    if (!window || !display)return;
    CGRect screen=display.bounds,windowRect=window.frame;
    UIEdgeInsets insets=window.safeAreaInsets;
    CGRect usable=UIEdgeInsetsInsetRect(windowRect,insets);
    BOOL valid=CGRectGetWidth(screen)>200 && CGRectGetHeight(screen)>100 &&
               CGRectGetWidth(usable)>CGRectGetWidth(screen)*0.50 &&
               CGRectGetHeight(usable)>CGRectGetHeight(screen)*0.50 &&
               CGRectContainsRect(CGRectInset(screen,-3,-3),usable);
    NSString *role=window.windowScene.session.role ?: @"unknown";
    BOOL nativeRole=[role isEqualToString:@"UIWindowSceneSessionRoleCarPlay"];
    BOOL hasInsets=insets.left>0.1 || insets.right>0.1 ||
                   insets.top>0.1 || insets.bottom>0.1;
    // The native scene proves Dashboard admission; layout must ALSO be
    // guaranteed by a non-zero system-provided safe area to avoid hiding Dock.
    NSDictionary *data=@{
       @"Producer":@"IndependentDuoFaceShell",@"Kind":@"NativeCarPlayWindowScene",
       @"CarPlayRole":@(nativeRole),@"GeometryValid":@(valid),
       @"HasNonzeroInsets":@(hasInsets),
       @"X":@(usable.origin.x/screen.size.width),
       @"Y":@(usable.origin.y/screen.size.height),
       @"Width":@(usable.size.width/screen.size.width),
       @"Height":@(usable.size.height/screen.size.height),
       @"DisplayAspect":@(screen.size.width/screen.size.height),
       @"Timestamp":@(NSDate.date.timeIntervalSince1970)
    };
    if (![data writeToFile:kShellScenePath atomically:YES])
        MTShellLog(@"record-write-failed",kShellScenePath);
    MTShellLog(@"scene-geometry",[NSString stringWithFormat:
       @"role=%@ window=%@ bounds=%@ insets=%@ valid=%d nonzero=%d",
       role,NSStringFromCGRect(windowRect),NSStringFromCGRect(screen),
       NSStringFromUIEdgeInsets(insets),valid,hasInsets]);
}
- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session
                                   options:(UISceneConnectionOptions *)connectionOptions {
    (void)connectionOptions;
    if (![scene isKindOfClass:UIWindowScene.class])return;
    UIWindowScene *ws=(UIWindowScene *)scene;
    self.window=[[UIWindow alloc] initWithWindowScene:ws];
    UIViewController *vc=[UIViewController new];
    vc.view.backgroundColor=UIColor.blackColor;
    // Minimal native app scene to keep Dashboard roster/window lifecycle real.
    UILabel *label=[UILabel new];
    label.text=@"DuoFace";label.textColor=UIColor.whiteColor;
    label.font=[UIFont boldSystemFontOfSize:18];
    label.textAlignment=NSTextAlignmentCenter;
    label.frame=CGRectMake(0,0,160,40);
    label.center=vc.view.center;
    label.autoresizingMask=UIViewAutoresizingFlexibleLeftMargin|
                            UIViewAutoresizingFlexibleRightMargin|
                            UIViewAutoresizingFlexibleTopMargin|
                            UIViewAutoresizingFlexibleBottomMargin;
    [vc.view addSubview:label];
    self.window.rootViewController=vc;
    [self.window makeKeyAndVisible];
    MTShellLog(@"scene-connected",[NSString stringWithFormat:
       @"role=%@ scene=%@",session.role,NSStringFromClass(ws.class)]);
    [self publishGeometry];
}
- (void)refreshGeometry:(NSTimer *)timer { (void)timer; [self publishGeometry]; }
- (void)sceneDidBecomeActive:(UIScene *)scene {
    (void)scene;
    if (!self.geometryTimer)
        self.geometryTimer=[NSTimer scheduledTimerWithTimeInterval:1.2 target:self
             selector:@selector(refreshGeometry:) userInfo:nil repeats:YES];
    [self publishGeometry];
}
- (void)sceneDidEnterBackground:(UIScene *)scene {
    (void)scene;
    [self.geometryTimer invalidate];self.geometryTimer=nil;
    [[NSFileManager defaultManager] removeItemAtPath:kShellScenePath error:nil];
    MTShellLog(@"native-scene-background",@"external-host-must-hide");
}
- (void)windowScene:(UIWindowScene *)windowScene didUpdateCoordinateSpace:(id<UICoordinateSpace>)previousCoordinateSpace
           interfaceOrientation:(UIInterfaceOrientation)previousInterfaceOrientation
                 traitCollection:(UITraitCollection *)previousTraitCollection {
    (void)windowScene;(void)previousCoordinateSpace;
    (void)previousInterfaceOrientation;(void)previousTraitCollection;
    [self publishGeometry];
}
- (void)sceneDidDisconnect:(UIScene *)scene {
    (void)scene;
    [[NSFileManager defaultManager] removeItemAtPath:kShellScenePath error:nil];
    [self.geometryTimer invalidate];self.geometryTimer=nil;
    self.window.hidden=YES;self.window=nil;
    MTShellLog(@"scene-disconnected",@"native-scene-closed");
}
@end
@interface MTDuoFaceShellApp : UIResponder <UIApplicationDelegate>
@end
@implementation MTDuoFaceShellApp
- (UISceneConfiguration *)application:(UIApplication *)application
 configurationForConnectingSceneSession:(UISceneSession *)session
                              options:(UISceneConnectionOptions *)options {
    (void)application;(void)options;
    UISceneConfiguration *configuration=[[UISceneConfiguration alloc]
            initWithName:@"DuoFaceCarPlay" sessionRole:session.role];
    configuration.sceneClass=UIWindowScene.class;
    configuration.delegateClass=MTDuoFaceShellScene.class;
    return configuration;
}
@end
int main(int argc,char **argv) {
    @autoreleasepool {
        return UIApplicationMain(argc,argv,nil,NSStringFromClass(MTDuoFaceShellApp.class));
    }
}
