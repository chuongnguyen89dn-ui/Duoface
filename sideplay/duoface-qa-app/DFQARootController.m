// DuoFace independent QA: an actual iPhone app and a SINGLE test dashboard.
// Do not claim the physical CarPlay Dock is working from plist/ACK alone.
// Writes only two known pref dictionaries; no SpringBoard LS hooks, no respring.
#import <UIKit/UIKit.h>
#import <math.h>

static NSString *const DFBase=@"/var/mobile/Library/Preferences/com.duoface.mytweak.v1bc.plist";
static NSString *const DFBridge=@"/var/mobile/Library/Preferences/com.duoface.mytweak.carplay-bridge.plist";
static NSString *const DFSource=@"/var/mobile/Library/Preferences/com.duoface.mytweak.cp-surface.plist";
static NSString *const DFAck=@"/var/mobile/Library/Preferences/com.duoface.mytweak.cp-receiver-ack.plist";
static NSString *const DFNativeLog=@"/var/mobile/Library/Logs/DuoFaceNativeBridgeQA.log";
static NSString *const DFSceneProbeLog=@"/var/mobile/Library/Logs/DuoFaceNativeSceneJoin.log";
static NSString *const DFSceneProbeRecord=@"/var/mobile/Library/Preferences/com.duoface.native-scene-owner.v1.plist";

static NSDictionary *DFPrefs(NSString *path) {
    NSDictionary *d=[NSDictionary dictionaryWithContentsOfFile:path];
    return [d isKindOfClass:NSDictionary.class]?d:@{};
}
static BOOL DFFlag(NSString *path,NSString *key) {
    id n=DFPrefs(path)[key];
    return [n isKindOfClass:NSNumber.class] && [n boolValue];
}
// Preserve all unrelated user settings. Fail instead of claiming success.
static BOOL DFWriteFlag(NSString *path,NSString *key,BOOL value,NSString **error) {
    if([[NSFileManager defaultManager] fileExistsAtPath:path] &&
       ![[NSFileManager defaultManager] isWritableFileAtPath:path]) {
        if(error)*error=@"Không có quyền sửa tệp Preferences. App chưa thay đổi gì.";
        return NO;
    }
    NSMutableDictionary *d=[DFPrefs(path) mutableCopy];
    d[key]=@(value);
    BOOL ok=[d writeToFile:path atomically:YES];
    if(!ok && error)*error=[NSString stringWithFormat:
      @"Không ghi được %@. Kiểm tra quyền app jailbreak; không cần mở Filza.",path.lastPathComponent];
    return ok && DFFlag(path,key)==value;
}
static BOOL DFFresh(NSDictionary *d) {
    id ts=d[@"Timestamp"];
    if(![ts isKindOfClass:NSNumber.class])return NO;
    NSTimeInterval delta=NSDate.date.timeIntervalSince1970-[ts doubleValue];
    return isfinite(delta) && delta>=0 && delta<=3.5;
}
static NSString *DFLastLines(NSString *path, NSUInteger limit) {
    NSError *err=nil;
    NSString *s=[NSString stringWithContentsOfFile:path
          encoding:NSUTF8StringEncoding error:&err];
    if(!s)return [NSString stringWithFormat:@"Không đọc được %@\n%@",path.lastPathComponent,
                                  err.localizedDescription?:@"Chưa có log."];
    NSArray<NSString *> *lines=[s componentsSeparatedByString:@"\n"];
    if(lines.count>limit)lines=[lines subarrayWithRange:NSMakeRange(lines.count-limit,limit)];
    return [lines componentsJoinedByString:@"\n"];
}
@interface DFQARootController : UIViewController
@property(nonatomic,strong) UIScrollView *scroll;
@property(nonatomic,strong) UIStackView *stack;
@property(nonatomic,strong) UISwitch *baseSwitch;
@property(nonatomic,strong) UISwitch *bridgeSwitch;
@property(nonatomic,strong) UISwitch *trialSwitch;
@property(nonatomic,strong) UISegmentedControl *geometry;
@property(nonatomic,strong) UILabel *infoLabel;
@property(nonatomic,strong) UILabel *detailLabel;
@property(nonatomic,strong) UILabel *nativeSceneLabel;
@property(nonatomic,strong) UISegmentedControl *logSource;
@property(nonatomic,strong) UITextView *logView;
@property(nonatomic,strong) NSTimer *refreshTimer;
@end
@implementation DFQARootController
- (UIColor *)accent { return [UIColor colorWithRed:0.14 green:0.48 blue:0.86 alpha:1]; }
- (UILabel *)label:(NSString *)s font:(UIFont *)font {
    UILabel *x=[UILabel new];x.text=s;x.font=font;
    x.textColor=UIColor.labelColor;
    x.numberOfLines=0;
    return x;
}
- (UIButton *)button:(NSString *)name selector:(SEL)sel danger:(BOOL)danger {
    UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];
    [b setTitle:name forState:UIControlStateNormal];
    b.titleLabel.font=[UIFont boldSystemFontOfSize:16];
    b.backgroundColor=danger?[UIColor colorWithRed:0.93 green:0.29 blue:0.27 alpha:0.14]:
                             [self.accent colorWithAlphaComponent:0.12];
    [b setTitleColor:danger?UIColor.systemRedColor:self.accent forState:UIControlStateNormal];
    b.layer.cornerRadius=12;
    b.contentEdgeInsets=UIEdgeInsetsMake(14,12,14,12);
    [b addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    return b;
}
- (UIView *)row:(NSString *)title explanation:(NSString *)desc toggle:(UISwitch *)control {
    UIStackView *v=[[UIStackView alloc] init];v.axis=UILayoutConstraintAxisVertical;v.spacing=5;
    UIStackView *top=[[UIStackView alloc] init];top.axis=UILayoutConstraintAxisHorizontal;
    top.alignment=UIStackViewAlignmentCenter;top.spacing=8;
    UILabel *heading=[self label:title font:[UIFont boldSystemFontOfSize:16]];
    [top addArrangedSubview:heading];
    [top addArrangedSubview:control];
    [v addArrangedSubview:top];
    UILabel *detail=[self label:desc font:[UIFont systemFontOfSize:13]];
    detail.textColor=UIColor.secondaryLabelColor;
    [v addArrangedSubview:detail];
    return v;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title=@"DuoFace QA";
    self.view.backgroundColor=UIColor.systemGroupedBackgroundColor;
    self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc]
       initWithTitle:@"Làm mới" style:UIBarButtonItemStylePlain target:self
       action:@selector(refresh)];
    self.scroll=[UIScrollView new];
    self.scroll.alwaysBounceVertical=YES;
    [self.view addSubview:self.scroll];
    self.scroll.translatesAutoresizingMaskIntoConstraints=NO;
    [NSLayoutConstraint activateConstraints:@[
      [self.scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
      [self.scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
      [self.scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
      [self.scroll.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]]];
    self.stack=[UIStackView new];self.stack.axis=UILayoutConstraintAxisVertical;
    self.stack.spacing=18;
    self.stack.layoutMargins=UIEdgeInsetsMake(18,18,24,18);
    self.stack.layoutMarginsRelativeArrangement=YES;
    [self.scroll addSubview:self.stack];self.stack.translatesAutoresizingMaskIntoConstraints=NO;
    [NSLayoutConstraint activateConstraints:@[
      [self.stack.topAnchor constraintEqualToAnchor:self.scroll.contentLayoutGuide.topAnchor],
      [self.stack.bottomAnchor constraintEqualToAnchor:self.scroll.contentLayoutGuide.bottomAnchor],
      [self.stack.leadingAnchor constraintEqualToAnchor:self.scroll.contentLayoutGuide.leadingAnchor],
      [self.stack.trailingAnchor constraintEqualToAnchor:self.scroll.contentLayoutGuide.trailingAnchor],
      [self.stack.widthAnchor constraintEqualToAnchor:self.scroll.frameLayoutGuide.widthAnchor]]];

    UILabel *intro=[self label:@"Điều khiển và kiểm tra DuoFace trên iPhone"
                       font:[UIFont boldSystemFontOfSize:21]];
    [self.stack addArrangedSubview:intro];
    UILabel *notice=[self label:
      @"App này điều khiển tweak đang cài. Chỉ thử trên xe đang đỗ. Cầu nối thành công chưa có nghĩa Dock/Home thật đã hiện."
      font:[UIFont systemFontOfSize:13]];
    notice.textColor=UIColor.secondaryLabelColor;
    [self.stack addArrangedSubview:notice];
    self.baseSwitch=[UISwitch new];self.baseSwitch.accessibilityLabel=@"Bật engine MyTweak";
    [self.baseSwitch addTarget:self action:@selector(baseChanged:) forControlEvents:UIControlEventValueChanged];
    [self.stack addArrangedSubview:[self row:@"MyTweak – giao diện hai ứng dụng"
      explanation:@"Bật/tắt engine V1B+C. Không cần biểu tượng MyTweak riêng."
      toggle:self.baseSwitch]];
    self.bridgeSwitch=[UISwitch new];self.bridgeSwitch.accessibilityLabel=@"Bật cầu nối Dashboard";
    [self.bridgeSwitch addTarget:self action:@selector(bridgeChanged:) forControlEvents:UIControlEventValueChanged];
    [self.stack addArrangedSubview:[self row:@"Cầu nối CarPlay / Dashboard"
      explanation:@"Cho phép gửi hình sang tiến trình CarPlay. Tắt để dừng thử nghiệm."
      toggle:self.bridgeSwitch]];
    self.trialSwitch=[UISwitch new];self.trialSwitch.accessibilityLabel=@"Thử Dock thật tối đa 45 giây";
    [self.trialSwitch addTarget:self action:@selector(trialChanged:) forControlEvents:UIControlEventValueChanged];
    [self.stack addArrangedSubview:[self row:@"Thử thanh hệ thống (45 giây)"
      explanation:@"Thử nghiệm can thiệp cửa sổ thật, chưa được xác minh ổn định trên xe."
      toggle:self.trialSwitch]];

    [self.stack addArrangedSubview:[self label:@"Chế độ giao diện" font:[UIFont boldSystemFontOfSize:16]]];
    self.geometry=[[UISegmentedControl alloc] initWithItems:@[@"Normal / hiện Dock",@"Fullscreen"]];
    self.geometry.selectedSegmentIndex=0;
    [self.geometry addTarget:self action:@selector(geometryChanged:) forControlEvents:UIControlEventValueChanged];
    [self.stack addArrangedSubview:self.geometry];
    UILabel *modeNote=[self label:@"Gửi yêu cầu Normal/Fullscreen; phải kiểm tra thực tế trên CarPlay. Không thay đổi phóng to một ô chia."
                                font:[UIFont systemFontOfSize:12]];
    modeNote.textColor=UIColor.secondaryLabelColor;
    [self.stack addArrangedSubview:modeNote];
    [self.stack addArrangedSubview:[self button:@"Dừng thử nghiệm và trở về Normal"
                                     selector:@selector(stopTrial:) danger:YES]];
    [self.stack addArrangedSubview:[self label:@"Trạng thái thực tế"
                                      font:[UIFont boldSystemFontOfSize:17]]];
    self.infoLabel=[self label:@"" font:[UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightRegular]];
    [self.stack addArrangedSubview:self.infoLabel];
    self.detailLabel=[self label:@""
        font:[UIFont systemFontOfSize:12]];
    self.detailLabel.textColor=UIColor.secondaryLabelColor;
    [self.stack addArrangedSubview:self.detailLabel];
    [self.stack addArrangedSubview:[self label:@"CarPlay scene hệ thống (chỉ đọc)"
                                      font:[UIFont boldSystemFontOfSize:17]]];
    self.nativeSceneLabel=[self label:@"Chưa nhận dữ liệu native scene"
                                 font:[UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular]];
    [self.stack addArrangedSubview:self.nativeSceneLabel];
    UILabel *nativeHint=[self label:@"Không bật Dock bằng lệnh. Chỉ đọc scene và API thật; không đăng ký app hay thay đổi cửa sổ."
                                font:[UIFont systemFontOfSize:12]];
    nativeHint.textColor=UIColor.secondaryLabelColor;
    [self.stack addArrangedSubview:nativeHint];
    self.logSource=[[UISegmentedControl alloc] initWithItems:@[@"QA6", @"Native scene"]];
    self.logSource.selectedSegmentIndex=1;
    [self.logSource addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    [self.stack addArrangedSubview:self.logSource];
    [self.stack addArrangedSubview:[self label:@"Nhật ký cầu nối"
                  font:[UIFont boldSystemFontOfSize:17]]];
    self.logView=[UITextView new];
    self.logView.editable=NO;
    self.logView.scrollEnabled=YES;
    self.logView.font=[UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular];
    self.logView.backgroundColor=UIColor.secondarySystemGroupedBackgroundColor;
    self.logView.layer.cornerRadius=12;
    [self.logView.heightAnchor constraintEqualToConstant:220].active=YES;
    [self.stack addArrangedSubview:self.logView];
    [self.stack addArrangedSubview:[self button:@"Chia sẻ log"
                      selector:@selector(shareLog:) danger:NO]];
    [self refresh];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.refreshTimer=[NSTimer scheduledTimerWithTimeInterval:2.0 target:self
                       selector:@selector(refresh) userInfo:nil repeats:YES];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];[self.refreshTimer invalidate];
    self.refreshTimer=nil;
}
- (void)alert:(NSString *)title message:(NSString *)message {
    UIAlertController *a=[UIAlertController alertControllerWithTitle:title
      message:message preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"Đóng" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}
- (BOOL)set:(NSString *)path key:(NSString *)key flag:(BOOL)value {
    NSString *reason=nil;
    if(!DFWriteFlag(path,key,value,&reason)) {
        [self alert:@"Chưa thay đổi được" message:reason?:@"Không có quyền ghi."];
        [self refresh];return NO;
    }
    [self refresh];return YES;
}
- (void)baseChanged:(UISwitch *)sender {
    if(!sender.on) {
        [self stopWithoutDialog];
        [self set:DFBase key:@"Enabled" flag:NO];
        return;
    }
    UIAlertController *a=[UIAlertController alertControllerWithTitle:@"Bật MyTweak?"
      message:@"Bật engine V1B+C để nó xuất hiện khi kết nối CarPlay. Không tự khởi động lại SpringBoard."
      preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"Hủy" style:UIAlertActionStyleCancel handler:^(UIAlertAction *x){[self refresh];}]];
    [a addAction:[UIAlertAction actionWithTitle:@"Bật" style:UIAlertActionStyleDefault handler:^(UIAlertAction *x){[self set:DFBase key:@"Enabled" flag:YES];}]];
    [self presentViewController:a animated:YES completion:nil];
}
- (void)bridgeChanged:(UISwitch *)sender {
    if(sender.on && !DFFlag(DFBase,@"Enabled")) {
        [self alert:@"Chưa bật MyTweak" message:@"Bật engine trước rồi mới bật cầu nối."];
        [self refresh];return;
    }
    if(!sender.on) [self stopWithoutDialog];
    else [self set:DFBridge key:@"Enabled" flag:YES];
}
- (void)trialChanged:(UISwitch *)sender {
    if(!sender.on) {[self set:DFBridge key:@"NativeSidebarTrial" flag:NO];return;}
    if(!DFFlag(DFBase,@"Enabled") || !DFFlag(DFBridge,@"Enabled")) {
        [self alert:@"Chưa bật cầu nối" message:@"Cần bật MyTweak và Dashboard trước khi thử."];
        [self refresh];return;
    }
    UIAlertController *a=[UIAlertController alertControllerWithTitle:@"Thử Dock thật?"
       message:@"Đây là phép thử tối đa 45 giây tác động cửa sổ CarPlay. Chỉ bật khi xe đang đỗ; có thể tắt ngay bằng nút Dừng thử nghiệm."
       preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"Hủy" style:UIAlertActionStyleCancel handler:^(UIAlertAction *x){[self refresh];}]];
    [a addAction:[UIAlertAction actionWithTitle:@"Bật thử" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *x){[self set:DFBridge key:@"NativeSidebarTrial" flag:YES];}]];
    [self presentViewController:a animated:YES completion:nil];
}
- (void)geometryChanged:(UISegmentedControl *)control {
    if(!DFFlag(DFBase,@"Enabled") || !DFFlag(DFBridge,@"Enabled")) {
        [self alert:@"Cầu nối chưa hoạt động" message:@"Bật MyTweak và Dashboard trước khi đổi chế độ."];
        [self refresh];return;
    }
    BOOL full=control.selectedSegmentIndex==1;
    if([self set:DFBridge key:@"HostFullscreen" flag:full])
        [self alert:@"Đã gửi yêu cầu" message:full?
           @"Đã yêu cầu toàn màn hình. Kiểm tra trực tiếp trên CarPlay để xác nhận.":
           @"Đã yêu cầu Normal và khôi phục Dock. Kiểm tra trực tiếp trên CarPlay để xác nhận."];
}
- (void)stopWithoutDialog {
    NSString *e=nil;
    // Order matters: request Normal first, disable native trial second, then bridge.
    BOOL a=DFWriteFlag(DFBridge,@"HostFullscreen",NO,&e);
    BOOL b=DFWriteFlag(DFBridge,@"NativeSidebarTrial",NO,&e);
    BOOL c=DFWriteFlag(DFBridge,@"Enabled",NO,&e);
    if(!(a&&b&&c))[self alert:@"Tắt chưa hoàn tất" message:e?:@"Không ghi được cấu hình."];
    [self refresh];
}
- (void)stopTrial:(id)sender { [self stopWithoutDialog]; }
- (void)refresh {
    BOOL base=DFFlag(DFBase,@"Enabled");
    BOOL bridge=DFFlag(DFBridge,@"Enabled");
    BOOL trial=DFFlag(DFBridge,@"NativeSidebarTrial");
    self.baseSwitch.on=base;self.bridgeSwitch.on=bridge;self.trialSwitch.on=trial;
    self.geometry.selectedSegmentIndex=DFFlag(DFBridge,@"HostFullscreen")?1:0;
    NSDictionary *surface=DFPrefs(DFSource);
    NSDictionary *ack=DFPrefs(DFAck);
    BOOL sending=base && bridge && DFFresh(surface);
    BOOL receiving=sending && DFFresh(ack) &&
      [surface[@"Session"] isKindOfClass:NSString.class] &&
      [ack[@"Session"] isEqual:surface[@"Session"]] &&
      [ack[@"ContextID"] isEqual:surface[@"ContextID"]];
    self.infoLabel.text=[NSString stringWithFormat:
      @"MyTweak: %@\nCầu nối: %@\nThử Dock: %@\nNguồn hình: %@\nReceiver Dashboard: %@",
      base?@"BẬT":@"TẮT",bridge?@"BẬT":@"TẮT",trial?@"BẬT":@"TẮT",
      sending?@"Có phiên mới":@"Chưa có phiên mới",
      receiving?@"ACK còn hiệu lực":@"Chưa có ACK"];
    self.detailLabel.text=@"ACK không phải bằng chứng Dock/Home đã hiển thị. Quan sát trên xe và xem log khi kiểm tra.";
    NSDictionary *native=DFPrefs(DFSceneProbeRecord);
    BOOL fresh=DFFresh(native) && [native[@"Kind"] isEqual:@"native-dash-readonly"];
    BOOL chrome=fresh && [native[@"ChromeObserved"] respondsToSelector:@selector(boolValue)] &&
                [native[@"ChromeObserved"] boolValue];
    NSString *metrics=fresh?[NSString stringWithFormat:@"%.1fx%.1f | nội dung x=%.1f y=%.1f w=%.1f h=%.1f",
         [native[@"FullW"] doubleValue], [native[@"FullH"] doubleValue],
         [native[@"UsableX"] doubleValue], [native[@"UsableY"] doubleValue],
         [native[@"UsableW"] doubleValue], [native[@"UsableH"] doubleValue]]:
         @"Chưa có bản ghi từ tiến trình CarPlay";
    self.nativeSceneLabel.text=[NSString stringWithFormat:
        @"Dashboard scene: %@\nDock hệ thống được nhìn thấy: %@\n%@\n"
         @"Có Dashboard không có nghĩa DuoFace đã đăng ký thành app.",
         fresh?@"Đang có phiên":@"Chưa có phiên",
         fresh?(chrome?@"Có":@"Không xác nhận"):@"Chưa rõ",
         metrics];
    if(!self.logView.isFirstResponder) {
        NSString *path=self.logSource.selectedSegmentIndex==1?DFSceneProbeLog:DFNativeLog;
        self.logView.text=DFLastLines(path,65);
    }
}
- (void)shareLog:(id)sender {
    NSString *s=[NSString stringWithFormat:
       @"DuoFace QA report\n%@\n%@\n\n--- Native Scene ---\n%@\n\n--- QA6 ---\n%@\n",
       self.infoLabel.text?:@"",self.nativeSceneLabel.text?:@"",
       DFLastLines(DFSceneProbeLog,350),DFLastLines(DFNativeLog,200)];
    UIActivityViewController *v=[[UIActivityViewController alloc] initWithActivityItems:@[s]
       applicationActivities:nil];
    v.popoverPresentationController.sourceView=(UIView *)sender;
    [self presentViewController:v animated:YES completion:nil];
}
@end
