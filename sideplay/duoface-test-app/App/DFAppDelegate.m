#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>

static NSString *const DFStart=@"com.duoface.testapp.cmd.start";
static NSString *const DFStop=@"com.duoface.testapp.cmd.stop";
static NSString *const DFStatus=@"com.duoface.testapp.cmd.status";
static NSString *const DFAckEnabled=@"com.duoface.testapp.ack.started";
static NSString *const DFAckStopped=@"com.duoface.testapp.ack.stopped";
static NSString *const DFAckMissing=@"com.duoface.testapp.ack.base-missing";
static NSString *const DFAckReady=@"com.duoface.testapp.ack.ready";
static NSString *const DFAckExpired=@"com.duoface.testapp.ack.expired";
static NSString *const DFError=@"com.duoface.testapp.ack.error";

static void DFPost(NSString *name) {
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
         (__bridge CFStringRef)name,NULL,NULL,YES);
}
@class DFTestViewController;
@interface DFAppDelegate : UIResponder <UIApplicationDelegate>
@property(nonatomic,strong) UIWindow *window;
@end
@interface DFTestViewController : UIViewController
@property(nonatomic,strong) UILabel *status;
@property(nonatomic,strong) UILabel *detail;
@property(nonatomic,strong) UITextView *events;
@property(nonatomic,strong) NSMutableString *timeline;
@property(nonatomic,strong) UIScrollView *scroll;
@property(nonatomic,assign) BOOL hasAck;
@end
static void DFReceive(CFNotificationCenterRef center,void *observer,CFStringRef name,
                      const void *object,CFDictionaryRef userInfo) {
    DFTestViewController *controller=(__bridge DFTestViewController *)observer;
    NSString *event=(__bridge NSString *)name;
    // Darwin callbacks need not be on the UIKit main thread.
    dispatch_async(dispatch_get_main_queue(), ^{
        [controller performSelector:@selector(didReceive:) withObject:event];
    });
}
@implementation DFTestViewController
- (UIColor *)ink {return [UIColor colorWithRed:0.90 green:0.94 blue:0.99 alpha:1];}
- (UIColor *)panel {return [UIColor colorWithRed:0.12 green:0.17 blue:0.26 alpha:1];}
- (UILabel *)label:(NSString *)string size:(CGFloat)size strong:(BOOL)strong {
    UILabel *v=[UILabel new];v.text=string;v.textColor=self.ink;
    v.font=strong?[UIFont boldSystemFontOfSize:size]:[UIFont systemFontOfSize:size];
    v.numberOfLines=0;return v;
}
- (UIButton *)button:(NSString *)title action:(SEL)action color:(UIColor *)color {
    UIButton *v=[UIButton buttonWithType:UIButtonTypeSystem];
    [v setTitle:title forState:UIControlStateNormal];[v setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    v.backgroundColor=color;v.titleLabel.font=[UIFont boldSystemFontOfSize:16];
    v.layer.cornerRadius=12;v.contentEdgeInsets=UIEdgeInsetsMake(16,12,16,12);
    [v addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    v.translatesAutoresizingMaskIntoConstraints=NO;
    [v.heightAnchor constraintGreaterThanOrEqualToConstant:54].active=YES;
    return v;
}
- (void)append:(NSString *)message {
    NSDateFormatter *f=[NSDateFormatter new];f.dateFormat=@"HH:mm:ss";
    [self.timeline appendFormat:@"[%@] %@\n",[f stringFromDate:NSDate.date],message];
    if(self.timeline.length>8000)[self.timeline deleteCharactersInRange:NSMakeRange(0,self.timeline.length-7000)];
    self.events.text=self.timeline;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor=[UIColor colorWithRed:0.06 green:0.09 blue:0.15 alpha:1];
    self.timeline=[NSMutableString string];
    UIScrollView *scroll=[UIScrollView new];scroll.translatesAutoresizingMaskIntoConstraints=NO;
    [self.view addSubview:scroll];
    [NSLayoutConstraint activateConstraints:@[
        [scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
        [scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
    ]];
    UIStackView *stack=[UIStackView new];stack.axis=UILayoutConstraintAxisVertical;
    stack.spacing=14;stack.translatesAutoresizingMaskIntoConstraints=NO;
    stack.layoutMargins=UIEdgeInsetsMake(22,18,24,18);stack.layoutMarginsRelativeArrangement=YES;
    [scroll addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor],
        [stack.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor],
        [stack.leadingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.trailingAnchor],
        [stack.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor]
    ]];
    UILabel *title=[self label:@"DuoFace Test" size:30 strong:YES];[stack addArrangedSubview:title];
    UILabel *subtitle=[self label:@"Điều khiển thử CarPlay trực tiếp trên iPhone" size:14 strong:NO];
    subtitle.textColor=[UIColor colorWithWhite:0.65 alpha:1];[stack addArrangedSubview:subtitle];
    self.status=[self label:@"Đang kiểm tra cầu nối…" size:19 strong:YES];[stack addArrangedSubview:self.status];
    self.detail=[self label:@"Chỉ thử khi xe đang đỗ. Tự dừng sau 45 giây." size:13 strong:NO];
    [stack addArrangedSubview:self.detail];
    [stack addArrangedSubview:[self button:@"Bắt đầu thử Dock · 45 giây" action:@selector(startTest)
                              color:[UIColor colorWithRed:0.14 green:0.43 blue:0.79 alpha:1]]];
    [stack addArrangedSubview:[self button:@"Dừng thử và hoàn nguyên" action:@selector(stopTest)
                              color:[UIColor colorWithRed:0.57 green:0.21 blue:0.24 alpha:1]]];
    [stack addArrangedSubview:[self button:@"Kiểm tra kết nối" action:@selector(checkStatus)
                              color:[UIColor colorWithRed:0.22 green:0.29 blue:0.40 alpha:1]]];
    UILabel *logTitle=[self label:@"Nhật ký thử nghiệm" size:19 strong:YES];
    [stack addArrangedSubview:logTitle];
    UITextView *events=[UITextView new];events.editable=NO;events.selectable=YES;
    events.scrollEnabled=YES;events.backgroundColor=self.panel;events.textColor=self.ink;
    events.font=[UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
    events.layer.cornerRadius=12;events.translatesAutoresizingMaskIntoConstraints=NO;
    [events.heightAnchor constraintEqualToConstant:170].active=YES;
    self.events=events;[stack addArrangedSubview:events];
    [stack addArrangedSubview:[self button:@"Chia sẻ nhật ký" action:@selector(shareLog)
                              color:[UIColor colorWithRed:0.22 green:0.29 blue:0.40 alpha:1]]];
    UILabel *warning=[self label:@"Bản QA đang thử nghiệm. Khi hết 45 giây, giao diện cầu nối được tắt và cấu hình MyTweak ban đầu được khôi phục. Dock/Home thật vẫn cần kiểm tra trên xe." size:12 strong:NO];
    warning.textColor=[UIColor colorWithWhite:0.63 alpha:1];[stack addArrangedSubview:warning];
    NSArray *names=@[DFAckEnabled,DFAckStopped,DFAckMissing,DFAckReady,DFAckExpired,DFError];
    for(NSString *name in names)
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
          (__bridge const void *)self,DFReceive,(__bridge CFStringRef)name,NULL,
          CFNotificationSuspensionBehaviorDeliverImmediately);
    [self append:@"DuoFace Test 0.1.0 đã mở. Chưa có phép thử nào được khởi động."];
    [self checkStatus];
}
- (void)dealloc {
    CFNotificationCenterRemoveEveryObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                            (__bridge const void *)self);
}
- (void)checkStatus {
    self.status.text=@"Đang kiểm tra SpringBoard…";
    self.detail.text=@"Nếu không có phản hồi, bộ điều khiển cần được nạp sau khi cài Sileo.";
    [self append:@"Gửi yêu cầu kiểm tra trạng thái…"];DFPost(DFStatus);
}
- (void)startTest {
    UIAlertController *c=[UIAlertController alertControllerWithTitle:@"Bắt đầu thử 45 giây?"
       message:@"Chỉ thực hiện khi xe đang đỗ. DuoFace Test sẽ bật giao diện MyTweak và phép thử Dock, sau đó tự hoàn nguyên."
       preferredStyle:UIAlertControllerStyleAlert];
    [c addAction:[UIAlertAction actionWithTitle:@"Hủy" style:UIAlertActionStyleCancel handler:nil]];
    [c addAction:[UIAlertAction actionWithTitle:@"Bắt đầu" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        self.status.text=@"Đang gửi lệnh bắt đầu…";
        [self append:@"Gửi lệnh thử nghiệm 45 giây."];DFPost(DFStart);
    }]];
    [self presentViewController:c animated:YES completion:nil];
}
- (void)stopTest {
    [self append:@"Yêu cầu dừng và khôi phục."];DFPost(DFStop);
}
- (void)didReceive:(NSString *)event {
    self.hasAck=YES;
    if([event isEqualToString:DFAckEnabled]) {
        self.status.text=@"Đã bật phép thử · 45 giây";
        self.detail.text=@"Hãy quan sát màn CarPlay. Thiết bị sẽ tự khôi phục sau 45 giây.";
        [self append:@"SpringBoard xác nhận BẬT. Chưa xác nhận Dock/Home đã hiện."];
    }else if([event isEqualToString:DFAckStopped]||[event isEqualToString:DFAckExpired]) {
        self.status.text=@"Đã tắt thử nghiệm";
        self.detail.text=@"SpringBoard đã xử lý lệnh tắt và hoàn nguyên cấu hình thử.";
        [self append:[event isEqualToString:DFAckExpired]?@"Hết hạn 45 giây, yêu cầu tự hoàn nguyên đã chạy.":@"Lệnh dừng đã được xác nhận."];
    }else if([event isEqualToString:DFAckReady]) {
        self.status.text=@"Bộ điều khiển SpringBoard đã kết nối";
        self.detail.text=@"Có thể bắt đầu một phiên thử 45 giây khi xe đang đỗ.";
        [self append:@"Nhận phản hồi bộ điều khiển đã được nạp."];
    }else if([event isEqualToString:DFAckMissing]) {
        self.status.text=@"Chưa có MyTweak Recovery";
        [self append:@"Không tìm thấy cấu hình MyTweak nền; không bắt đầu phép thử."];
    }else {
        self.status.text=@"Lỗi xử lý lệnh";
        [self append:@"SpringBoard trả về lỗi; không coi là đã bật."];
    }
}
- (void)shareLog {
    NSString *header=[NSString stringWithFormat:@"DuoFace Test v0.1.0\n%@\n",NSDate.date];
    NSString *path=@"/var/mobile/Library/Logs/DuoFaceNativeBridgeQA.log";
    NSData *data=[NSData dataWithContentsOfFile:path];
    NSString *native=(data.length>0)?[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]:nil;
    if(native.length>20000)native=[native substringFromIndex:native.length-20000];
    if(!native)native=[NSString stringWithFormat:@"Không đọc được file native (%@) trong sandbox app.\n",path];
    NSString *report=[NSString stringWithFormat:@"%@\nAPP:\n%@\nNATIVE:\n%@",header,self.timeline,native];
    UIActivityViewController *share=[[UIActivityViewController alloc]
      initWithActivityItems:@[report] applicationActivities:nil];
    if(share.popoverPresentationController)
        share.popoverPresentationController.sourceView=self.view;
    [self presentViewController:share animated:YES completion:nil];
}
@end
@implementation DFAppDelegate
- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)options {
    self.window=[[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController=[DFTestViewController new];
    [self.window makeKeyAndVisible];
    return YES;
}
@end
