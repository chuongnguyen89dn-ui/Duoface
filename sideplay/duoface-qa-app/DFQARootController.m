// DuoFace independent QA: an actual iPhone app and a SINGLE test dashboard.
// Do not claim the physical CarPlay Dock is working from plist/ACK alone.
// Enables only explicit QA preferences. The separate admission module may hook SpringBoard after consent; no respring.
#import <UIKit/UIKit.h>
#import <math.h>
#import <CoreFoundation/CoreFoundation.h>

static NSString *const DFBase=@"/var/mobile/Library/Preferences/com.duoface.mytweak.v1bc.plist";
static NSString *const DFBridge=@"/var/mobile/Library/Preferences/com.duoface.mytweak.carplay-bridge.plist";
static NSString *const DFSource=@"/var/mobile/Library/Preferences/com.duoface.mytweak.cp-surface.plist";
static NSString *const DFAck=@"/var/mobile/Library/Preferences/com.duoface.mytweak.cp-receiver-ack.plist";
static NSString *const DFNativeLog=@"/var/mobile/Library/Logs/DuoFaceNativeBridgeQA.log";
static NSString *const DFSceneProbeLog=@"/var/mobile/Library/Logs/DuoFaceNativeSceneJoin.log";
static NSString *const DFMapsOwnerLog=@"/var/mobile/Library/Logs/DuoFaceCarPlayOwnerSnapshot.log";
static NSString *const DFSceneProbeRecord=@"/var/mobile/Library/Preferences/com.duoface.native-scene-owner.v1.plist";
static NSString *const DFSBRequest=@"/var/mobile/Library/Preferences/com.duoface.sb-admission-probe.request.plist";
static NSString *const DFSBStatus=@"/var/mobile/Library/Preferences/com.duoface.sb-admission-probe.status.plist";
static NSString *const DFAdmissionConfig=@"/var/mobile/Library/Preferences/com.duoface.firstparty-admission.plist";
static NSString *const DFAdmissionKill=@"/var/mobile/Library/Preferences/.duoface-firstparty-admission-disable";
static NSString *const DFAdmissionLog=@"/var/mobile/Library/Logs/DuoFaceFirstPartyAdmission.log";
static NSString *const DFTraceRequest=@"/var/mobile/Library/Preferences/com.duoface.admission-trace.request.plist";
static NSString *const DFTraceLog=@"/var/mobile/Library/Logs/DuoFaceAdmissionTrace.log";
static NSString *const DFTraceStatus=@"/var/mobile/Library/Preferences/com.duoface.admission-trace.status.plist";
static CFStringRef const DFTraceSignal=CFSTR("com.duoface.admission-trace.preflight");
static NSString *const DFTraceDisable=@"/var/mobile/Library/Preferences/.duoface-admission-trace-disable";
static CFStringRef const DFAdmissionSignal=CFSTR("com.duoface.firstparty-admission.refresh");
static NSString *const DFRosterRequest=@"/var/mobile/Library/Preferences/com.duoface.firstparty-roster.request.plist";
static CFStringRef const DFRosterSignal=CFSTR("com.duoface.firstparty-admission.roster-readonly");
static NSString *const DFSBLog=@"/var/mobile/Library/Logs/DuoFaceSBAdmissionProbe.log";
static NSString *const DFRosterSBLog=@"/var/mobile/Library/Logs/DuoFaceFirstPartySpringBoard.log";

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
@property(nonatomic,strong) UILabel *sbAdmissionLabel;
@property(nonatomic,strong) UILabel *firstPartyLabel;
@property(nonatomic,strong) UILabel *traceReadinessLabel;
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
    [self.stack addArrangedSubview:[self label:@"Đăng ký Dashboard — SpringBoard (chỉ đọc)"
                                      font:[UIFont boldSystemFontOfSize:17]]];
    self.sbAdmissionLabel=[self label:@"Chưa chạy phép kiểm tra SpringBoard."
                                 font:[UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular]];
    [self.stack addArrangedSubview:self.sbAdmissionLabel];
    [self.stack addArrangedSubview:[self button:@"Kiểm tra API SpringBoard một lần"
                      selector:@selector(runSBAdmissionProbe:) danger:NO]];
    UILabel *sbHint=[self label:@"Mặc định TẮT. Chỉ đọc chữ ký API iOS 16, không sửa quyền và không tự khởi động lại SpringBoard."
                              font:[UIFont systemFontOfSize:12]];
    sbHint.textColor=UIColor.secondaryLabelColor;
    [self.stack addArrangedSubview:sbHint];
    [self.stack addArrangedSubview:[self label:@"Thử đăng ký DuoFace — CarPlay" font:[UIFont boldSystemFontOfSize:17]]];
    self.firstPartyLabel=[self label:@"TẮT — chưa thử." font:[UIFont systemFontOfSize:12]];
    [self.stack addArrangedSubview:self.firstPartyLabel];
    [self.stack addArrangedSubview:[self button:@"Bật thử đăng ký (xác nhận)"
                  selector:@selector(enableFirstParty:) danger:NO]];
    [self.stack addArrangedSubview:[self button:@"Tắt đăng ký ngay"
                  selector:@selector(disableFirstParty:) danger:YES]];
    [self.stack addArrangedSubview:[self button:@"Kiểm tra Native Host trong CarPlay (chỉ đọc)"
                  selector:@selector(runRosterProbe:) danger:NO]];
    [self.stack addArrangedSubview:[self button:@"Một lần đo tổng hợp (không đổi quyền)"
                  selector:@selector(startAdmissionTrace:) danger:NO]];
    [self.stack addArrangedSubview:[self button:@"Dừng phép đo tổng hợp"
                  selector:@selector(stopAdmissionTrace:) danger:YES]];
    self.traceReadinessLabel=[self label:@"Chưa chạy chẩn đoán. Không thể coi đã nạp module." font:[UIFont systemFontOfSize:12]];
    [self.stack addArrangedSubview:self.traceReadinessLabel];
    [self.stack addArrangedSubview:[self label:@"Thử khi xe đang đỗ. Bản admission mới có hook giới hạn bundle DuoFace trong cả SpringBoard và CarPlay (có rủi ro). Nút Tắt ngăn hook trả quyền mới. Chưa xác nhận biểu tượng xe." font:[UIFont systemFontOfSize:12]]];
    self.logSource=[[UISegmentedControl alloc] initWithItems:@[@"QA6", @"Native", @"SB", @"Admission"]];
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
    [self.stack addArrangedSubview:[self button:@"Chia sẻ snapshot CarPlay Maps (JSONL)"
                      selector:@selector(shareMapsOwnerLog:) danger:NO]];
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
- (void)runSBAdmissionProbe:(id)sender {
    (void)sender;
    UIAlertController *a=[UIAlertController alertControllerWithTitle:@"Kiểm tra API SpringBoard?"
      message:@"Chỉ đọc chữ ký hàm một lần trên iOS 16. Không hook, không sửa quyền ứng dụng, không khởi động lại SpringBoard. Nếu module chưa được nạp, app sẽ báo chưa có kết quả."
      preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"Hủy" style:UIAlertActionStyleCancel
                                           handler:^(UIAlertAction *x){(void)x;}]];
    [a addAction:[UIAlertAction actionWithTitle:@"Kiểm tra" style:UIAlertActionStyleDefault
                                           handler:^(UIAlertAction *x){
        (void)x;
        NSString *uuid=NSUUID.UUID.UUIDString;
        NSDictionary *request=@{@"Enabled":@YES, @"RequestID":uuid,
                      @"RequestAt":@(NSDate.date.timeIntervalSince1970),@"Version":@1};
        if(![request writeToFile:DFSBRequest atomically:YES]){
           [self alert:@"Không gửi được" message:@"Chưa ghi được yêu cầu kiểm tra. Không cần mở Filza."];
           return;
        }
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
             CFSTR("com.duoface.nativejoin.sborder.probe"),NULL,NULL,YES);
        [self refresh];
    }]];
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
- (BOOL)writeFirstParty:(BOOL)enabled {
    NSMutableDictionary *d=[DFPrefs(DFAdmissionConfig) mutableCopy];
    d[@"Enabled"]=@(enabled);
    d[@"HostBundleID"]=@"com.duoface.native.scenehost";
    d[@"RiskAcknowledged"]=@(enabled);
    BOOL ok=[d writeToFile:DFAdmissionConfig atomically:YES];
    return ok && DFFlag(DFAdmissionConfig,@"Enabled")==enabled;
}
- (void)disableFirstParty:(id)sender {
    BOOL a=[self writeFirstParty:NO];
    BOOL b=[[NSFileManager defaultManager] createFileAtPath:DFAdmissionKill
                contents:[@"off" dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    if(a&&b) CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
         DFAdmissionSignal,NULL,NULL,YES);
    if(!(a&&b)) [self alert:@"Tắt chưa xác nhận" message:@"Không xác nhận được khóa an toàn. Đừng thử thêm."];
    [self refresh];
}
- (void)enableFirstParty:(id)sender {
    UIAlertController *a=[UIAlertController alertControllerWithTitle:@"Thử đường đăng ký DuoFace?"
      message:@"CẢNH BÁO: module đăng ký có hook SpringBoard VÀ CarPlay, có nguy cơ khiến SpringBoard lỗi/safe mode. Chỉ thử khi xe đang đỗ, có cách khôi phục jailbreak. Không tự respring. Nút Tắt tạo kill switch ngăn câu trả lời hook mới."
      preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"Hủy" style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:@"Tôi đồng ý" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        if(![self writeFirstParty:YES]) {
            [self alert:@"Không bật" message:@"Không ghi được cấu hình."];[self refresh];return;
        }
        NSError *error=nil;
        [[NSFileManager defaultManager] removeItemAtPath:DFAdmissionKill error:&error];
        if([[NSFileManager defaultManager] fileExistsAtPath:DFAdmissionKill]){
            (void)[self writeFirstParty:NO];
            [self alert:@"Không bật" message:@"Chưa tháo được khóa an toàn."];
        } else {
            CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                DFAdmissionSignal,NULL,NULL,YES);
            [self alert:@"Đã gửi tín hiệu thử" message:@"Đã lưu cấu hình và gửi tín hiệu trực tiếp đến tiến trình CarPlay đang chạy. Xem tab Admission để xác nhận module phản hồi; không tự khởi động lại SpringBoard. Nếu module chưa nạp, vẫn chưa có phản hồi."];
        }
        [self refresh];
    }]];
    [self presentViewController:a animated:YES completion:nil];
}
- (void)stopAdmissionTrace:(id)sender {
    (void)sender;
    NSMutableDictionary *req=[DFPrefs(DFTraceRequest) mutableCopy];
    req[@"Enabled"]=@NO;
    BOOL written=[req writeToFile:DFTraceRequest atomically:YES];
    BOOL killed=[[NSFileManager defaultManager] createFileAtPath:DFTraceDisable
         contents:[@"disabled" dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    // Do not leave the matching SpringBoard one-shot request armed after Stop.
    NSMutableDictionary *sb=[DFPrefs(DFSBRequest) mutableCopy];
    BOOL sbStopped=YES;
    if([sb[@"Kind"] isEqualToString:@"consolidated-target"]) {
        sb[@"Enabled"]=@NO;
        sbStopped=[sb writeToFile:DFSBRequest atomically:YES];
    }
    if(!(written&&killed&&sbStopped))[self alert:@"Dừng chưa hoàn tất"
                  message:@"Chưa xác minh được cả hai yêu cầu đã dừng. Không tiếp tục thử."];
    [self refresh];
}
- (void)startAdmissionTrace:(id)sender {
    (void)sender;
    if(!DFFlag(DFAdmissionConfig,@"Enabled") ||
       !DFFlag(DFAdmissionConfig,@"RiskAcknowledged") ||
       [[NSFileManager defaultManager] fileExistsAtPath:DFAdmissionKill]) {
       [self alert:@"Chưa đủ điều kiện" message:@"Chỉ dùng với thử nghiệm CarPlay đã bật. Không tự kích hoạt quyền hay can thiệp SpringBoard."];
       return;
    }
    UIAlertController *a=[UIAlertController alertControllerWithTitle:@"Chẩn đoán CarPlay tổng hợp?"
      message:@"Một lần, tối đa 180 giây / 16 mẫu. CarPlay tự báo đã nạp module và đúng phiên bản, rồi chỉ đọc kết quả GỐC của hai hook hiện có. KHÔNG cần nâng cấp hay khởi động lại SpringBoard. Không sửa Dock/quyền ứng dụng. Nếu CarPlay chưa nạp module sẽ báo CHƯA SẴN SÀNG, không coi đã thành công."
      preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"Hủy" style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:@"Tôi đồng ý" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        (void)action;
        NSString *rid=NSUUID.UUID.UUIDString;
        NSNumber *now=@(NSDate.date.timeIntervalSince1970);
        NSDictionary *trace=@{@"Enabled":@YES,@"AuditOnly":@YES,
           @"HostBundleID":@"com.duoface.native.scenehost",
           @"RequestID":rid,@"RequestAt":now};
        // The existing SpringBoard v0.0.1 remains untouched; no respring needed.
        BOOL traceOK=[trace writeToFile:DFTraceRequest atomically:YES];
        if(!traceOK) {
            [self alert:@"Không gửi được" message:@"Không lưu được yêu cầu CarPlay. Không thực hiện."];
            return;
        }
        NSError *e=nil;[[NSFileManager defaultManager] removeItemAtPath:DFTraceDisable error:&e];
        if([[NSFileManager defaultManager] fileExistsAtPath:DFTraceDisable]) {
            NSMutableDictionary *off=[trace mutableCopy];off[@"Enabled"]=@NO;
            (void)[off writeToFile:DFTraceRequest atomically:YES];
            [self alert:@"Chưa sẵn sàng" message:@"Không xóa được khóa an toàn. Yêu cầu không được bật."];
            return;
        }
        // The already-loaded CarPlay process answers with a versioned ACK.
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
            DFTraceSignal,NULL,NULL,YES);
        [self alert:@"Đã gửi một yêu cầu"
          message:@"Xem trạng thái phiên bản/ACK CarPlay ngay bên dưới. Nếu không nhận ACK mới phiên bản 5 thì module chưa nạp: KHÔNG tiếp tục thử, không respring. Log chỉ ghi tối đa 16 mẫu, không đổi quyền trong khi đo."];
        self.logSource.selectedSegmentIndex=3;
        [self refresh];
    }]];
    [self presentViewController:a animated:YES completion:nil];
}
- (void)runRosterProbe:(id)sender {
    (void)sender;
    if(!DFFlag(DFAdmissionConfig,@"Enabled") ||
       !DFFlag(DFAdmissionConfig,@"RiskAcknowledged") ||
       [[NSFileManager defaultManager] fileExistsAtPath:DFAdmissionKill]){
        [self alert:@"Chưa bật thử đăng ký" message:@"Tính năng chỉ đọc dùng cùng sự đồng ý hiện tại. Không bật cầu nối cũ."];
        return;
    }
    UIAlertController *a=[UIAlertController alertControllerWithTitle:@"Kiểm tra Native Host một lần?"
        message:@"Đọc thông tin duy nhất ứng dụng DuoFace Native Host trong tiến trình CarPlay. Không sửa quyền, danh sách ứng dụng, Dock hoặc SpringBoard."
        preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"Hủy" style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:@"Kiểm tra" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        (void)action;
        NSDictionary *request=@{@"Enabled":@YES,@"HostBundleID":@"com.duoface.native.scenehost",
           @"RequestID":NSUUID.UUID.UUIDString,@"RequestAt":@(NSDate.date.timeIntervalSince1970)};
        if(![request writeToFile:DFRosterRequest atomically:YES]){
            [self alert:@"Không gửi được" message:@"Không ghi được yêu cầu chỉ đọc."];return;
        }
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
            DFRosterSignal,NULL,NULL,YES);
        self.logSource.selectedSegmentIndex=3;
        [self refresh];
    }]];
    [self presentViewController:a animated:YES completion:nil];
}
- (void)refresh {
    NSDictionary *traceReq=DFPrefs(DFTraceRequest);
    NSDictionary *traceAck=DFPrefs(DFTraceStatus);
    NSString *rid=[traceReq[@"RequestID"] isKindOfClass:NSString.class]?traceReq[@"RequestID"]:nil;
    NSTimeInterval age=[NSDate.date timeIntervalSince1970]-[traceAck[@"Timestamp"] doubleValue];
    BOOL sameTrace=rid.length>0 && [rid isEqualToString:traceAck[@"RequestID"]];
    BOOL readyAck=sameTrace && age>=0 && age<180 &&
       [traceAck[@"Version"] integerValue]==5 &&
       [traceAck[@"Process"] isEqualToString:@"CarPlay"];
    BOOL hookReady=readyAck && [traceAck[@"HooksReady"] boolValue];
    self.traceReadinessLabel.text=!rid.length?@"Chưa yêu cầu kiểm tra module.":
       !readyAck?@"CHƯA SẴN SÀNG: không có ACK mới từ CarPlay v5; dừng và chia sẻ log, không respring.":
       hookReady?[NSString stringWithFormat:@"CarPlay v5 ĐÃ NẠP, hook đã sẵn sàng; pid=%@. Chưa phải đã đăng ký Dashboard.",traceAck[@"PID"]]:
       @"CarPlay v5 đã phản hồi nhưng hook chưa sẵn sàng; KHÔNG coi kiểm thử thành công.";
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
    NSDictionary *req=DFPrefs(DFSBRequest);
    NSDictionary *status=DFPrefs(DFSBStatus);
    NSString *requestID=[req[@"RequestID"] isKindOfClass:NSString.class]?req[@"RequestID"]:nil;
    BOOL same=requestID.length>0 && [requestID isEqual:status[@"RequestID"]];
    NSTimeInterval seconds=NSDate.date.timeIntervalSince1970-[req[@"RequestAt"] doubleValue];
    BOOL recent=isfinite(seconds) && seconds>=0 && seconds<300;
    if(same && recent && [status[@"State"] isKindOfClass:NSString.class]) {
        self.sbAdmissionLabel.text=[NSString stringWithFormat:@"Kết quả: %@\n%@",
             status[@"State"],status[@"Summary"]?:@""];
    } else if(requestID.length>0 && recent) {
        self.sbAdmissionLabel.text=@"Đã gửi yêu cầu; chưa nhận kết quả. Nếu SpringBoard chưa nạp module, phép kiểm tra sẽ không tự chạy.";
    } else {
        self.sbAdmissionLabel.text=@"Chưa có yêu cầu kiểm tra SpringBoard mới.";
    }
    BOOL enabled=DFFlag(DFAdmissionConfig,@"Enabled") &&
        DFFlag(DFAdmissionConfig,@"RiskAcknowledged") &&
        [DFPrefs(DFAdmissionConfig)[@"HostBundleID"] isEqual:@"com.duoface.native.scenehost"] &&
        ![[NSFileManager defaultManager] fileExistsAtPath:DFAdmissionKill];
    self.firstPartyLabel.text=enabled?@"ĐÃ CHO PHÉP THỬ — chưa xác nhận CarPlay nhận app.":@"TẮT — mặc định an toàn.";
    if(!self.logView.isFirstResponder) {
        NSString *path=self.logSource.selectedSegmentIndex==3?DFAdmissionLog:
              (self.logSource.selectedSegmentIndex==2?DFSBLog:
              (self.logSource.selectedSegmentIndex==1?DFSceneProbeLog:DFNativeLog));
        self.logView.text=self.logSource.selectedSegmentIndex==2?
           [NSString stringWithFormat:@"--- SpringBoard first-party roster ---\n%@\n\n--- Earlier readonly ABI probe ---\n%@",
              DFLastLines(DFRosterSBLog,65),DFLastLines(DFSBLog,35)]:
           self.logSource.selectedSegmentIndex==3?
           [NSString stringWithFormat:@"--- Live original getter trace ---\n%@\n\n--- Earlier admission log ---\n%@",
              DFLastLines(DFTraceLog,35),DFLastLines(DFAdmissionLog,30)]:DFLastLines(path,65);
    }
}
// Share the exact bounded JSONL file instead of truncating it to display lines.
// This preserves both the native Maps and DuoFace split timeline without Filza.
- (void)shareMapsOwnerLog:(id)sender {
    NSFileManager *fm=NSFileManager.defaultManager;
    NSDictionary *attrs=[fm attributesOfItemAtPath:DFMapsOwnerLog error:nil];
    unsigned long long size=[attrs[NSFileSize] unsignedLongLongValue];
    if(![attrs[NSFileType] isEqual:NSFileTypeRegular] || size==0 || size>5*1024*1024) {
        [self alert:@"Chưa có snapshot Native Maps"
              message:@"Kết nối CarPlay, mở Maps dẫn đường 35 giây rồi mở DuoFace split 35 giây. Log chưa có hoặc vượt giới hạn; không tự bật/tắt Maps."];
        return;
    }
    NSString *name=[NSString stringWithFormat:@"DuoFaceCarPlayOwnerSnapshot-%@.jsonl",NSUUID.UUID.UUIDString];
    NSString *tmp=[NSTemporaryDirectory() stringByAppendingPathComponent:name];
    NSError *error=nil;
    if(![fm copyItemAtPath:DFMapsOwnerLog toPath:tmp error:&error]){
        [self alert:@"Không thể chia sẻ snapshot"
              message:error.localizedDescription?:@"Không có quyền đọc log CarPlay."];
        return;
    }
    UIActivityViewController *v=[[UIActivityViewController alloc]
      initWithActivityItems:@[[NSURL fileURLWithPath:tmp]]
      applicationActivities:nil];
    v.popoverPresentationController.sourceView=(UIView *)sender;
    [self presentViewController:v animated:YES completion:nil];
}
- (void)shareLog:(id)sender {
    NSString *s=[NSString stringWithFormat:
       @"DuoFace QA report\n%@\n%@\n%@\n%@\n\n--- FirstParty CarPlay Admission ---\n%@\n\n--- SpringBoard Admission ABI ---\n%@\n\n--- Native Scene ---\n%@\n\n--- QA6 ---\n%@\n",
       self.infoLabel.text?:@"",self.nativeSceneLabel.text?:@"",
       self.sbAdmissionLabel.text?:@"",
       [NSString stringWithFormat:@"%@\n%@",self.firstPartyLabel.text?:@"",self.traceReadinessLabel.text?:@""],
       [NSString stringWithFormat:@"--- Original getter trace ---\n%@\n--- Existing admission ---\n%@",
         DFLastLines(DFTraceLog,80),DFLastLines(DFAdmissionLog,80)],
       [NSString stringWithFormat:@"--- SpringBoard first-party roster ---\n%@\n--- Older ABI probe ---\n%@",
         DFLastLines(DFRosterSBLog,120),DFLastLines(DFSBLog,120)],
       DFLastLines(DFSceneProbeLog,120),DFLastLines(DFNativeLog,100)];
    UIActivityViewController *v=[[UIActivityViewController alloc] initWithActivityItems:@[s]
       applicationActivities:nil];
    v.popoverPresentationController.sourceView=(UIView *)sender;
    [self presentViewController:v animated:YES completion:nil];
}
@end
