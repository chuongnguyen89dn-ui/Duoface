// DuoFace QA-only control app. No CarPlay entitlements or vendor frameworks.
// Real scene attach is performed only by the independently built SpringBoard tweak.
#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>
#import <notify.h>
#import <objc/message.h>

static CFStringRef const DFQADomain=CFSTR("com.duoface.visual12");
static NSString *DFQAGet(NSString *key, NSString *fallback) {
    CFPreferencesAppSynchronize(DFQADomain);
    id value=CFBridgingRelease(CFPreferencesCopyAppValue((__bridge CFStringRef)key,DFQADomain));
    return [value isKindOfClass:NSString.class] && [value length] ? value : fallback;
}
static void DFQAWrite(NSString *key,id value) {
    CFPreferencesSetAppValue((__bridge CFStringRef)key,(__bridge CFPropertyListRef)value,DFQADomain);
    CFPreferencesAppSynchronize(DFQADomain);
}
@interface DFQAControlController : UIViewController <UITextFieldDelegate>
@property(nonatomic,strong) UITextField *first;
@property(nonatomic,strong) UITextField *second;
@property(nonatomic,strong) UILabel *status;
@property(nonatomic,strong) UISwitch *enabled;
@property(nonatomic,strong) NSArray<NSDictionary *> *installedApps;
@end
@implementation DFQAControlController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor=UIColor.systemBackgroundColor;
    self.title=@"DuoFace CarPlay QA";
    UIScrollView *scroll=[UIScrollView new];scroll.translatesAutoresizingMaskIntoConstraints=NO;
    [self.view addSubview:scroll];
    [NSLayoutConstraint activateConstraints:@[
        [scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]]];
    UIStackView *stack=[UIStackView new];stack.axis=UILayoutConstraintAxisVertical;
    stack.alignment=UIStackViewAlignmentFill;stack.spacing=12;
    stack.translatesAutoresizingMaskIntoConstraints=NO;[scroll addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor constant:24],
        [stack.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor constant:-24],
        [stack.leadingAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.leadingAnchor constant:24],
        [stack.trailingAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.trailingAnchor constant:-24]]];
    UILabel *intro=[UILabel new];intro.numberOfLines=0;
    intro.text=@"Thử nghiệm G1/G2 trên xe đang dừng. Không thay Native12 + Hub8. Nếu lõi CarPlay cũ đang nạp, bản QA sẽ từ chối khởi động. Sau khi cài, mở ứng dụng này trên iPhone.";
    intro.font=[UIFont systemFontOfSize:14];[stack addArrangedSubview:intro];
    UILabel *row=[UILabel new];row.text=@"Bật chế độ QA thủ công";[stack addArrangedSubview:row];
    self.enabled=[UISwitch new];[stack addArrangedSubview:self.enabled];
    [self.enabled addTarget:self action:@selector(changeEnabled) forControlEvents:UIControlEventValueChanged];
    CFPreferencesAppSynchronize(DFQADomain);
    id flag=CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("qaEnabled"),DFQADomain));
    self.enabled.on=[flag respondsToSelector:@selector(boolValue)] && [flag boolValue];
    self.first=[self field:@"App 1: bundle ID" value:DFQAGet(@"qaFirstBundle",@"com.waze")];
    self.second=[self field:@"App 2: bundle ID" value:DFQAGet(@"qaSecondBundle",@"com.google.ios.youtube")];
    [stack addArrangedSubview:self.first];[stack addArrangedSubview:self.second];
    UIButton *chooseFirst=[UIButton buttonWithType:UIButtonTypeSystem];
    [chooseFirst setTitle:@"Chọn App 1 từ ứng dụng đã cài" forState:UIControlStateNormal];
    [chooseFirst addTarget:self action:@selector(pickFirst) forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:chooseFirst];
    UIButton *chooseSecond=[UIButton buttonWithType:UIButtonTypeSystem];
    [chooseSecond setTitle:@"Chọn App 2 từ ứng dụng đã cài" forState:UIControlStateNormal];
    [chooseSecond addTarget:self action:@selector(pickSecond) forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:chooseSecond];
    NSArray *labels=@[@"1. Khởi tạo cửa sổ QA",@"2. G1: mở một ứng dụng",@"3. G2: mở hai ứng dụng",@"Dừng QA / đóng hai scene"];
    SEL actions[]={@selector(start),@selector(g1),@selector(g2),@selector(stop)};
    for(int i=0;i<4;i++){
        UIButton *button=[UIButton buttonWithType:UIButtonTypeSystem];
        [button setTitle:labels[i] forState:UIControlStateNormal];
        button.titleLabel.numberOfLines=2;
        button.contentHorizontalAlignment=UIControlContentHorizontalAlignmentCenter;
        button.backgroundColor=UIColor.secondarySystemBackgroundColor;
        button.layer.cornerRadius=9;
        [button.heightAnchor constraintEqualToConstant:48].active=YES;
        [button addTarget:self action:actions[i] forControlEvents:UIControlEventTouchUpInside];
        [stack addArrangedSubview:button];
    }
    self.status=[UILabel new];self.status.numberOfLines=0;
    self.status.font=[UIFont systemFontOfSize:13];self.status.textColor=UIColor.secondaryLabelColor;
    self.status.text=@"Chưa chạy thử. Sau G1/G2, lấy log /var/mobile/Library/Logs/DuoFaceCarPlayQA.log";
    [stack addArrangedSubview:self.status];
}
- (NSArray<NSDictionary *> *)queryInstalledApps {
    // QA-only, runtime checked private LaunchServices API; no SpringBoard scene changes.
    Class cls=NSClassFromString(@"LSApplicationWorkspace");
    SEL shared=NSSelectorFromString(@"defaultWorkspace");
    if(!cls || ![cls respondsToSelector:shared]) return @[];
    id workspace=((id(*)(id,SEL))objc_msgSend)(cls,shared);
    SEL list=NSSelectorFromString(@"allInstalledApplications");
    if(!workspace || ![workspace respondsToSelector:list]) return @[];
    id apps=((id(*)(id,SEL))objc_msgSend)(workspace,list);
    if(![apps isKindOfClass:NSArray.class]) return @[];
    NSMutableArray *items=[NSMutableArray array];
    for(id proxy in apps) {
        SEL bundleSel=NSSelectorFromString(@"applicationIdentifier");
        SEL nameSel=NSSelectorFromString(@"localizedName");
        if(![proxy respondsToSelector:bundleSel]) continue;
        id bundle=((id(*)(id,SEL))objc_msgSend)(proxy,bundleSel);
        id name=[proxy respondsToSelector:nameSel] ? ((id(*)(id,SEL))objc_msgSend)(proxy,nameSel) : bundle;
        if(![bundle isKindOfClass:NSString.class] || ![bundle length]) continue;
        [items addObject:@{@"bundle":bundle,@"name":([name isKindOfClass:NSString.class] && [name length])?name:bundle}];
    }
    [items sortUsingComparator:^NSComparisonResult(NSDictionary *a,NSDictionary *b) {
        return [a[@"name"] localizedCaseInsensitiveCompare:b[@"name"]];
    }];
    return items;
}
- (void)pickFirst { [self presentPickerForField:self.first]; }
- (void)pickSecond { [self presentPickerForField:self.second]; }
- (void)presentPickerForField:(UITextField *)field {
    NSArray *apps=[self queryInstalledApps];
    if(!apps.count) {
        self.status.text=@"Không đọc được danh sách ứng dụng qua LaunchServices. Có thể nhập bundle ID thủ công.";
        return;
    }
    UIAlertController *alert=[UIAlertController alertControllerWithTitle:@"Chọn ứng dụng"
       message:@"Danh sách ứng dụng đã cài; chọn không đảm bảo CarPlay có thể mở."
       preferredStyle:UIAlertControllerStyleActionSheet];
    // Show a bounded set to keep the QA UI responsive; search by typing bundle ID remains available.
    NSUInteger limit=MIN(apps.count,80);
    for(NSUInteger i=0;i<limit;i++) {
        NSDictionary *app=apps[i];
        NSString *label=[NSString stringWithFormat:@"%@ (%@)",app[@"name"],app[@"bundle"]];
        [alert addAction:[UIAlertAction actionWithTitle:label style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            field.text=app[@"bundle"];
            self.status.text=[NSString stringWithFormat:@"Đã chọn %@. Nhấn Khởi tạo rồi G1/G2.",app[@"name"]];
        }]];
    }
    [alert addAction:[UIAlertAction actionWithTitle:@"Hủy" style:UIAlertActionStyleCancel handler:nil]];
    UIPopoverPresentationController *pop=alert.popoverPresentationController;
    if(pop) { pop.sourceView=field;pop.sourceRect=field.bounds; }
    [self presentViewController:alert animated:YES completion:nil];
}
- (UITextField *)field:(NSString *)placeholder value:(NSString *)value {
    UITextField *field=[UITextField new];
    field.borderStyle=UITextBorderStyleRoundedRect;field.placeholder=placeholder;
    field.text=value;field.autocorrectionType=UITextAutocorrectionTypeNo;
    field.autocapitalizationType=UITextAutocapitalizationTypeNone;
    field.returnKeyType=UIReturnKeyDone;field.delegate=self;
    [field.heightAnchor constraintEqualToConstant:44].active=YES;
    return field;
}
- (BOOL)textFieldShouldReturn:(UITextField *)field{[field resignFirstResponder];return YES;}
- (void)changeEnabled {
    DFQAWrite(@"qaEnabled",@(self.enabled.on));
    notify_post("com.duoface.visual12.preferences");
    if(!self.enabled.on) notify_post("com.duoface.carplay.qa.stop");
    self.status.text=self.enabled.on?@"QA bật; nhấn Khởi tạo. Không chạy song song CB owner cũ.":
                                   @"QA tắt; đã gửi yêu cầu dừng.";
}
- (BOOL)save {
    NSString *first=[self.first.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSString *second=[self.second.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if(!first.length || !second.length || [first isEqualToString:second]){
        self.status.text=@"Cần hai bundle ID khác nhau, đã cài trên iPhone.";
        return NO;
    }
    DFQAWrite(@"qaFirstBundle",first);DFQAWrite(@"qaSecondBundle",second);
    return YES;
}
- (void)signal:(const char *)name label:(NSString *)label{
    if(!self.enabled.on){self.status.text=@"Bật chế độ QA trước.";return;}
    if(![self save])return;
    notify_post(name);
    self.status.text=[NSString stringWithFormat:@"Đã gửi lệnh %@ (chưa chứng minh mở app). Kiểm tra log DuoFaceCarPlayQA.log / SpringBoard.",label];
}
- (void)start{[self signal:"com.duoface.carplay.qa.start" label:@"Start"];}
- (void)g1{[self signal:"com.duoface.carplay.qa.g1" label:@"G1"];}
- (void)g2{[self signal:"com.duoface.carplay.qa.g2" label:@"G2"];}
- (void)stop{notify_post("com.duoface.carplay.qa.stop");self.status.text=@"Đã gửi yêu cầu dừng QA.";}
@end
@interface DFQAAppDelegate : UIResponder<UIApplicationDelegate>
@property(nonatomic,strong) UIWindow *window;
@end
@implementation DFQAAppDelegate
- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)options {
    self.window=[[UIWindow alloc]initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController=[[UINavigationController alloc]initWithRootViewController:[DFQAControlController new]];
    [self.window makeKeyAndVisible];
    return YES;
}
@end
int main(int argc,char **argv){
    @autoreleasepool {return UIApplicationMain(argc,argv,nil,NSStringFromClass(DFQAAppDelegate.class));}
}
