// Standalone, no vendor runtime, no fake CarPlay windows; all scenes are UIKit-issued.
#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>
#import <fcntl.h>
#import <unistd.h>
static NSString *const kRole=@"UIWindowSceneSessionRoleCarPlay";
static NSString *const kPrefs=@"/var/mobile/Library/Preferences/com.duoface.gate1smoke.plist";
static NSString *const kKill=@"/var/mobile/Library/Preferences/.duoface-gate1smoke-disable";
static NSString *const kOldPrefs=@"/var/mobile/Library/Preferences/com.duoface.firstparty-admission.plist";
static NSString *const kOldKill=@"/var/mobile/Library/Preferences/.duoface-firstparty-admission-disable";
static NSString *const kPauseMarker=@"/var/mobile/Library/Preferences/.duoface-gate1smoke-paused-old";
static NSString *const kSB=@"/var/mobile/Library/Logs/DuoFaceGate1SpringBoard.log";
static NSString *const kCP=@"/var/mobile/Library/Logs/DuoFaceGate1CarPlay.log";
static NSString *const kDiagRequest=@"/var/mobile/Library/Preferences/com.duoface.gate1smoke.diag-request.plist";
static NSString *const kDiagCar=@"/var/mobile/Library/Preferences/com.duoface.gate1smoke.diag-carplay.plist";
static NSString *const kDiagSB=@"/var/mobile/Library/Preferences/com.duoface.gate1smoke.diag-springboard.plist";
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
static BOOL OldGateActive(void) {
  NSDictionary *old=[NSDictionary dictionaryWithContentsOfFile:kOldPrefs];
  return [old[@"Enabled"] boolValue] && [old[@"RiskAcknowledged"] boolValue] &&
    [old[@"HostBundleID"] isEqualToString:@"com.duoface.native.scenehost"] &&
    ![NSFileManager.defaultManager fileExistsAtPath:kOldKill];
}
static void NotifyOldGate(void) {
  CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
    CFSTR("com.duoface.firstparty-admission.refresh"),NULL,NULL,YES);
}
static BOOL RestoreLegacyGate(void) {
  NSFileManager *fm=NSFileManager.defaultManager;
  if(![fm fileExistsAtPath:kPauseMarker])return YES;
  if(![fm fileExistsAtPath:kKill])return NO;
  NSError *error=nil;
  if([fm fileExistsAtPath:kOldKill] && ![fm removeItemAtPath:kOldKill error:&error]){
    Log(@"old-gate-restore-failed: kill file cannot be removed");return NO;
  }
  [fm removeItemAtPath:kPauseMarker error:nil];
  NotifyOldGate();
  Log(@"old-gate-restored-by-gate1");
  return YES;
}
static NSString *Disable(void) {
  NSFileManager *fm=NSFileManager.defaultManager;
  if(![fm createFileAtPath:kKill contents:[NSData data] attributes:nil])
    return @"cannot-write-gate1-kill-file";
  [@{@"Enabled":@NO,@"RiskAcknowledged":@NO,
      @"HostBundleID":@"com.duoface.gate1smoke"} writeToFile:kPrefs atomically:YES];
  Signal();
  if(!RestoreLegacyGate())return @"old-gate-restoration-failed";
  Log(@"test-disabled kill-switch-active");
  return nil;
}
static NSString *Enable(BOOL allowPauseOld) {
  NSFileManager *fm=NSFileManager.defaultManager;
  BOOL oldActive=OldGateActive();
  if(oldActive && !allowPauseOld)return @"old-gate-active-needs-confirmation";
  BOOL paused=NO;
  if(oldActive){
    // Exclusivity by explicit consent; do not modify legacy prefs or binaries.
    if(![fm createFileAtPath:kPauseMarker contents:[NSData data] attributes:nil])
      return @"cannot-create-legacy-pause-marker";
    if(![fm createFileAtPath:kOldKill contents:[NSData data] attributes:nil]){
      [fm removeItemAtPath:kPauseMarker error:nil];
      return @"cannot-pause-legacy-gate";
    }
    paused=YES;
    NotifyOldGate();
    Log(@"legacy-gate-paused-by-user");
  }
  NSDictionary *prefs=@{@"Enabled":@YES,@"RiskAcknowledged":@YES,
      @"HostBundleID":@"com.duoface.gate1smoke"};
  if(![prefs writeToFile:kPrefs atomically:YES]){
    [fm createFileAtPath:kKill contents:[NSData data] attributes:nil];
    if(paused)RestoreLegacyGate();
    return @"cannot-write-gate1-preferences";
  }
  NSDictionary *readback=[NSDictionary dictionaryWithContentsOfFile:kPrefs];
  if(![readback[@"Enabled"] boolValue] ||
     ![readback[@"HostBundleID"] isEqualToString:@"com.duoface.gate1smoke"]){
    [fm createFileAtPath:kKill contents:[NSData data] attributes:nil];
    if(paused)RestoreLegacyGate();
    return @"gate1-preferences-readback-failed";
  }
  NSError *error=nil;
  if([fm fileExistsAtPath:kKill] && ![fm removeItemAtPath:kKill error:&error]){
    [fm createFileAtPath:kKill contents:[NSData data] attributes:nil];
    if(paused)RestoreLegacyGate();
    return @"cannot-remove-gate1-kill-file";
  }
  Signal();
  Log(@"gate1-enabled-user-controlled-no-timeout");
  return nil;
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
  UIButton *on=[self button:@"BẬT thử nghiệm CarPlay" action:@selector(askEnable)];
  UIButton *off=[self button:@"TẮT NGAY / KHÓA AN TOÀN" action:@selector(stopTest)];
  UIButton *refresh=[self button:@"ĐỌC TRẠNG THÁI" action:@selector(readStatus)];
  UIButton *probe=[self button:@"KIỂM TRA ĐĂNG KÝ" action:@selector(runProbe)];
  UITextView *log=[UITextView new];log.editable=NO;log.backgroundColor=UIColor.blackColor;
  log.textColor=UIColor.greenColor;log.font=[UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
  self.logView=log;
  UIStackView *stack=[[UIStackView alloc] initWithArrangedSubviews:@[intro,on,off,probe,refresh,log]];
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
    [probe.heightAnchor constraintEqualToConstant:50],
    [log.heightAnchor constraintGreaterThanOrEqualToConstant:230],
    [stack.widthAnchor constraintEqualToAnchor:self.view.widthAnchor constant:-32]
  ]];
  [self readStatus];
}
- (void)viewDidAppear:(BOOL)animated {[super viewDidAppear:animated];[self readStatus];}
- (void)showResult:(NSString *)reason {
  if(reason.length){
    Log([NSString stringWithFormat:@"enable-refused-reason=%@",reason]);
    UIAlertController *alert=[UIAlertController alertControllerWithTitle:@"Gate 1 không bật được"
       message:reason preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Đóng" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
  }
  [self readStatus];
}
- (void)askEnable {
  BOOL oldActive=OldGateActive();
  NSString *message=oldActive?
    @"Gate DuoFace QA cũ đang hoạt động. Bạn đồng ý TẠM KHÓA gate cũ khi bật Gate 1? Không xóa hay thay đổi gói cũ; Gate 1 sẽ khôi phục khi TẮT/gỡ cài đặt. Chỉ thử khi xe đỗ.":
    @"Thử biểu tượng và scene CarPlay. Bật đến khi bạn nhấn TẮT hoặc gỡ gói; không còn giới hạn 10 phút. Có nguy cơ safe mode, cần cách khôi phục jailbreak.";
  UIAlertController *alert=[UIAlertController alertControllerWithTitle:@"DuoFace Gate 1"
    message:message preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"HỦY" style:UIAlertActionStyleCancel handler:nil]];
  [alert addAction:[UIAlertAction actionWithTitle:oldActive?@"Tạm khóa gate cũ và BẬT":@"BẬT thử nghiệm"
    style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){
      (void)action;[self showResult:Enable(oldActive)];
  }]];
  [self presentViewController:alert animated:YES completion:nil];
}
- (void)stopTest {
  NSString *reason=Disable();
  if(reason)Log([NSString stringWithFormat:@"disable-error=%@",reason]);
  [self readStatus];
}
- (void)runProbe {
  NSDictionary *cfg=[NSDictionary dictionaryWithContentsOfFile:kPrefs];
  if(![cfg[@"Enabled"] boolValue]||
     [[NSFileManager defaultManager] fileExistsAtPath:kKill]){
    Log(@"diag-not-started: gate-disabled");[self readStatus];return;
  }
  NSString *nonce=NSUUID.UUID.UUIDString;
  NSDictionary *request=@{@"Enabled":@YES,@"AuditOnly":@YES,
      @"RequestID":nonce,@"RequestedAt":@(NSDate.date.timeIntervalSince1970),
      @"HostBundleID":@"com.duoface.gate1smoke"};
  if(![request writeToFile:kDiagRequest atomically:YES]){
    Log(@"diag-request-write-failed");return;
  }
  CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
      CFSTR("com.duoface.gate1smoke.diag-run"),NULL,NULL,YES);
  [self readStatus];
  // The two processes answer asynchronously. Display actual matching-nonce
  // results without requiring the user to press Refresh again.
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^{[self readStatus];});
}
- (void)readStatus {
  NSDictionary *p=[NSDictionary dictionaryWithContentsOfFile:kPrefs];
  NSFileManager *fm=NSFileManager.defaultManager;
  BOOL enabled=[p[@"Enabled"] boolValue] && ![fm fileExistsAtPath:kKill];
  NSMutableString *text=[NSMutableString stringWithFormat:
    @"GATE1_ENABLED=%@\nGATE1_MODE=MANUAL_NO_TIMEOUT\nOLD_GATE_ACTIVE=%@\nOLD_GATE_PAUSED_BY_GATE1=%@\n\n",
    enabled?@"YES":@"NO",OldGateActive()?@"YES":@"NO",
    [fm fileExistsAtPath:kPauseMarker]?@"YES":@"NO"];
  for(NSArray *info in @[@[@"SpringBoard admission",kSB],
                         @[@"CarPlay admission",kCP],
                         @[@"System-issued scene",kScene]]) {
    NSString *s=[NSString stringWithContentsOfFile:info[1] encoding:NSUTF8StringEncoding error:nil];
    if(s.length>2800)s=[s substringFromIndex:s.length-2800];
    [text appendFormat:@"--- %@ ---\n%@\n",info[0],s?:@"(chưa có log)"];
  }
  NSDictionary *rq=[NSDictionary dictionaryWithContentsOfFile:kDiagRequest];
  NSString *nonce=rq[@"RequestID"];
  [text appendString:@"\n--- KẾT QUẢ ĐĂNG KÝ (CHỈ ĐỌC) ---\n"];
  for(NSArray *item in @[@[@"SpringBoard",kDiagSB],@[@"CarPlay",kDiagCar]]){
    NSDictionary *report=[NSDictionary dictionaryWithContentsOfFile:item[1]];
    BOOL fresh=nonce.length>0&&[report[@"RequestID"] isEqualToString:nonce];
    [text appendFormat:@"%@: %@\n",item[0],fresh?@"ĐÃ TRẢ LỜI":@"CHƯA TRẢ LỜI"];
    if(fresh){
      for(NSString *k in @[@"HookReady",@"LSOwn",@"Roster",@"LSABI3",
       @"CachedBoolABI",@"DashBoardLoaded",@"DBControllerLoaded",
       @"DBSharedABI",@"DBLookupABI",@"InclusionABI",@"IconLayout"]){
        if(report[k])[text appendFormat:@"  %@=%@\n",k,report[k]];
      }
    }
  }
  [text appendString:@"\nKhông trả lời = không có bằng chứng. Roster không phải icon thật.\nKhông thay Dock hệ thống."];
  self.logView.text=text;
  if(nonce.length>0) {
    [self.logView scrollRangeToVisible:NSMakeRange(text.length,0)];
  }
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
