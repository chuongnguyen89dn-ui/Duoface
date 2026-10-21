// Standalone, no vendor runtime, no fake CarPlay windows; all scenes are UIKit-issued.
#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>
#import <fcntl.h>
#import <unistd.h>
static NSString *const kRole=@"UIWindowSceneSessionRoleCarPlay";
static NSString *const kPrefs=@"/var/mobile/Library/Preferences/com.duoface.gate1smoke.plist";
static NSString *const kKill=@"/var/mobile/Library/Preferences/.duoface-gate1smoke-disable";
static NSString *const kSB=@"/var/mobile/Library/Logs/DuoFaceGate1SpringBoard.log";
static NSString *const kCP=@"/var/mobile/Library/Logs/DuoFaceGate1CarPlay.log";
static NSString *const kScene=@"/var/mobile/Library/Logs/DuoFaceGate1Scene.log";
static void Log(NSString *message) {
  NSString *row=[NSString stringWithFormat:@"[Gate1] %@\n",message];
  int fd=open(kScene.fileSystemRepresentation,O_CREAT|O_WRONLY|O_APPEND,0644);
  if(fd>=0){NSData *b=[row dataUsingEncoding:NSUTF8StringEncoding];
    (void)write(fd,b.bytes,b.length);close(fd);}
  NSLog(@"%@",row);
}
static void Signal(void) {
  CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
    CFSTR("com.duoface.gate1smoke.refresh"),NULL,NULL,YES);
}
static void Disable(void) {
  [[NSFileManager defaultManager] createFileAtPath:kKill contents:[NSData data] attributes:nil];
  [@{@"Enabled":@NO,@"HostBundleID":@"com.duoface.gate1smoke",
      @"RiskAcknowledged":@NO,@"ExpiresAt":@0} writeToFile:kPrefs atomically:YES];
  Signal();Log(@"test-disabled kill-switch-active");
}
static BOOL Enable(void) {
  NSDictionary *older=[NSDictionary dictionaryWithContentsOfFile:
     @"/var/mobile/Library/Preferences/com.duoface.firstparty-admission.plist"];
  if([older[@"Enabled"] boolValue])return NO;
  NSTimeInterval expires=NSDate.date.timeIntervalSince1970+600;
  NSDictionary *prefs=@{@"Enabled":@YES,@"RiskAcknowledged":@YES,
      @"HostBundleID":@"com.duoface.gate1smoke",@"ExpiresAt":@(expires)};
  // Consent is never changed during install: explicit in-app action only.
  if(![prefs writeToFile:kPrefs atomically:YES])return NO;
  if([[NSFileManager defaultManager] fileExistsAtPath:kKill])
    [[NSFileManager defaultManager] removeItemAtPath:kKill error:nil];
  Signal();Log(@"test-enabled ten-minute-timeout; reconnect-CarPlay");
  return YES;
}
@interface Gate1Status : UIViewController
@property(nonatomic,strong) UITextView *logView;
@end
@implementation Gate1Status
- (void)loadView {
  UIScrollView *view=[UIScrollView new];
  view.backgroundColor=[UIColor colorWithRed:0.06 green:0.10 blue:0.17 alpha:1];
  self.view=view;
}
- (UIButton *)button:(NSString *)label action:(SEL)sel {
  UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];
  [b setTitle:label forState:UIControlStateNormal];
  b.titleLabel.font=[UIFont boldSystemFontOfSize:16];
  [b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
  b.backgroundColor=[UIColor colorWithRed:0.1 green:0.35 blue:0.6 alpha:1];
  b.layer.cornerRadius=9;
  [b addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
  return b;
}
- (void)viewDidLoad {
  [super viewDidLoad];
  UILabel *intro=[UILabel new];
  intro.text=@"DuoFace · CarPlay Gate 1\nChỉ kiểm tra biểu tượng và scene thật.\nKhông chứa Native12 / HUD / hai ô.";
  intro.textColor=UIColor.whiteColor;intro.numberOfLines=0;
  intro.font=[UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
  UIButton *on=[self button:@"BẬT thử nghiệm trong 10 phút" action:@selector(askEnable)];
  UIButton *off=[self button:@"TẮT NGAY / KHÓA AN TOÀN" action:@selector(stopTest)];
  UIButton *refresh=[self button:@"ĐỌC TRẠNG THÁI" action:@selector(readStatus)];
  UITextView *log=[UITextView new];log.editable=NO;log.backgroundColor=UIColor.blackColor;
  log.textColor=UIColor.greenColor;log.font=[UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
  self.logView=log;
  UIStackView *stack=[[UIStackView alloc] initWithArrangedSubviews:@[intro,on,off,refresh,log]];
  stack.axis=UILayoutConstraintAxisVertical;stack.spacing=12;
  stack.translatesAutoresizingMaskIntoConstraints=NO;
  [self.view addSubview:stack];
  [NSLayoutConstraint activateConstraints:@[
    [stack.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
    [stack.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
    [stack.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:18],
    [stack.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-16],
    [on.heightAnchor constraintEqualToConstant:50],
    [off.heightAnchor constraintEqualToConstant:50],
    [refresh.heightAnchor constraintEqualToConstant:50],
    [log.heightAnchor constraintGreaterThanOrEqualToConstant:230],
    [stack.widthAnchor constraintEqualToAnchor:self.view.widthAnchor constant:-32]
  ]];
  [self readStatus];
}
- (void)viewDidAppear:(BOOL)animated {[super viewDidAppear:animated];[self readStatus];}
- (void)askEnable {
  UIAlertController *alert=[UIAlertController alertControllerWithTitle:@"Thử CarPlay jailbreak"
    message:@"Chỉ khi xe đang đỗ. Thao tác này kích hoạt hook giới hạn app Gate1 trong SpringBoard + CarPlay, có thể gây safe mode. Hết hạn sau 10 phút; nút TẮT sẽ khóa ngay. Phải có cách khôi phục jailbreak." preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"HỦY" style:UIAlertActionStyleCancel handler:nil]];
  [alert addAction:[UIAlertAction actionWithTitle:@"Tôi chấp nhận và BẬT"
     style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){
       (void)action;
       if(!Enable()){
         Log(@"enable-refused (old gate enabled or preferences denied)");
       }
       [self readStatus];
     }]];
  [self presentViewController:alert animated:YES completion:nil];
}
- (void)stopTest {(void)self;Disable();[self readStatus];}
- (void)readStatus {
  NSDictionary *p=[NSDictionary dictionaryWithContentsOfFile:kPrefs];
  NSTimeInterval now=NSDate.date.timeIntervalSince1970;
  BOOL enabled=[p[@"Enabled"] boolValue] && [p[@"ExpiresAt"] doubleValue]>now &&
               ![[NSFileManager defaultManager] fileExistsAtPath:kKill];
  NSMutableString *text=[NSMutableString stringWithFormat:
    @"GATE1_ENABLED=%@\nTTL_REMAINING=%.0fs\n\n",enabled?@"YES":@"NO",
    MAX(0,[p[@"ExpiresAt"] doubleValue]-now)];
  for(NSArray *info in @[@[@"SpringBoard admission",kSB],
                         @[@"CarPlay admission",kCP],
                         @[@"System-issued scene",kScene]]) {
    NSString *s=[NSString stringWithContentsOfFile:info[1] encoding:NSUTF8StringEncoding error:nil];
    if(s.length>2800)s=[s substringFromIndex:s.length-2800];
    [text appendFormat:@"--- %@ ---\n%@\n",info[0],s?:@"(chưa có log)"];
  }
  [text appendString:@"\nKhông có log scene = chưa được xác minh.\nKhông thay Dock hệ thống."];
  self.logView.text=text;
}
@end
@interface Gate1Scene : UIResponder <UIWindowSceneDelegate>
@property(nonatomic,strong) UIWindow *window;
@end
@implementation Gate1Scene
- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session
  options:(UISceneConnectionOptions *)options {
  (void)options;
  if(![scene isKindOfClass:UIWindowScene.class])return;
  UIWindowScene *ws=(UIWindowScene *)scene;
  BOOL car=[session.role isEqualToString:kRole] && ws.screen!=UIScreen.mainScreen;
  if([session.role isEqualToString:kRole] && !car){Log(@"refused-not-external-scene");return;}
  UIWindow *window=[[UIWindow alloc] initWithWindowScene:ws];self.window=window;
  if(car){
    UIViewController *root=[UIViewController new];
    root.view.backgroundColor=[UIColor colorWithRed:0 green:0.3 blue:0.65 alpha:1];
    UILabel *label=[UILabel new];label.text=@"DUOFACE GATE 1\nNATIVE CARPLAY SCENE\nDOCK THUỘC iOS";
    label.textColor=UIColor.whiteColor;label.font=[UIFont boldSystemFontOfSize:20];
    label.numberOfLines=0;label.textAlignment=NSTextAlignmentCenter;
    label.frame=root.view.bounds;label.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [root.view addSubview:label];window.rootViewController=root;
    Log(@"GATE1_CARPLAY_SCENE_CONNECTED UIKit-issued external UIWindowScene");
  } else {
    window.rootViewController=[Gate1Status new];
    Log(@"gate1-iphone-status-open");
  }
  [window makeKeyAndVisible];
}
- (void)sceneDidDisconnect:(UIScene *)scene {
  if(scene==self.window.windowScene){
    self.window.hidden=YES;self.window=nil;
    Log(@"gate1-scene-disconnected");
  }
}
@end
@interface Gate1Delegate : UIResponder <UIApplicationDelegate> @end
@implementation Gate1Delegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
  (void)application;(void)options;Log(@"gate1-app-launched");return YES;
}
- (UISceneConfiguration *)application:(UIApplication *)application
 configurationForConnectingSceneSession:(UISceneSession *)session
 options:(UISceneConnectionOptions *)options {
  (void)application;(void)options;
  UISceneConfiguration *c=[UISceneConfiguration configurationWithName:nil sessionRole:session.role];
  if(![session.role isEqualToString:UIWindowSceneSessionRoleApplication] &&
     ![session.role isEqualToString:kRole])return c;
  c.sceneClass=UIWindowScene.class;c.delegateClass=Gate1Scene.class;
  return c;
}
@end
int main(int argc,char **argv) {
  @autoreleasepool {
    return UIApplicationMain(argc,argv,nil,NSStringFromClass(Gate1Delegate.class));
  }
}
