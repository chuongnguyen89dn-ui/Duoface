// First-party DuoFace startup. Show genuine device/session data only.
// Do not draw sample split panes, fake app scenes or inert settings controls.
#import <UIKit/UIKit.h>
#import "DFAppEligibility.h"
#import "DFNativeDiagnostics.h"
#import "DFLayoutEngine.h"
#import <objc/message.h>
#import <math.h>
#import <notify.h>
@interface DFNativeHostSurfaceView : UIView
- (void)start;
- (void)stop;
@end
@interface DFNativeHostRootController : UIViewController <UITableViewDataSource,UITableViewDelegate>
@property(nonatomic,assign) BOOL carPlay;
@property(nonatomic,strong) DFNativeHostSurfaceView *nativeSurface;
@property(nonatomic,strong) UIImageView *mainLogo;
@property(nonatomic,strong) UILabel *stateLabel;
@property(nonatomic,strong) UIButton *diagnosticsButton;
@property(nonatomic,strong) UISegmentedControl *tabs;
@property(nonatomic,strong) UITableView *appsTable;
@property(nonatomic,strong) NSArray<NSDictionary *> *installedApps;
@property(nonatomic,assign) NSInteger currentPreset;
- (instancetype)initWithCarPlay:(BOOL)carPlay;
@end
@implementation DFNativeHostRootController
- (instancetype)initWithCarPlay:(BOOL)carPlay {
 if((self=[super initWithNibName:nil bundle:nil]))_carPlay=carPlay;
 return self;
}
- (UIImage *)art:(NSString *)name {
 return [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]
               pathForResource:name ofType:@"png" inDirectory:@"VisualAssets"]];
}
- (UILabel *)makeText:(CGFloat)size {
 UILabel *label=[UILabel new];label.translatesAutoresizingMaskIntoConstraints=NO;
 label.numberOfLines=0;label.textAlignment=NSTextAlignmentCenter;
 label.textColor=UIColor.whiteColor;
 label.font=[UIFont systemFontOfSize:size weight:UIFontWeightMedium];
 return label;
}
- (void)loadView {
 UIView *root=[UIView new];root.backgroundColor=UIColor.blackColor;self.view=root;
}
- (NSArray<NSDictionary *> *)queryInstalledApps {
 Class workspaceClass=NSClassFromString(@"LSApplicationWorkspace");
 SEL defaultWorkspace=NSSelectorFromString(@"defaultWorkspace");
 SEL allApps=NSSelectorFromString(@"allInstalledApplications");
 if(!workspaceClass || ![workspaceClass respondsToSelector:defaultWorkspace])return @[];
 @try {
   id workspace=((id(*)(id,SEL))objc_msgSend)(workspaceClass,defaultWorkspace);
   if(![workspace respondsToSelector:allApps])return @[];
   id result=((id(*)(id,SEL))objc_msgSend)(workspace,allApps);
   if(![result isKindOfClass:NSArray.class])return @[];
   NSMutableArray<NSDictionary *> *items=[NSMutableArray new];
   for(id proxy in (NSArray *)result){
      id bundle=nil,name=nil;
      @try {bundle=[proxy valueForKey:@"applicationIdentifier"];
            name=[proxy valueForKey:@"localizedName"];}
      @catch(NSException *e){(void)e;continue;}
      if(!DFIsEligibleAppID(bundle))continue;
      if(![name isKindOfClass:NSString.class] || ![(NSString *)name length])name=bundle;
      [items addObject:@{@"name":name,@"bundle":bundle}];
   }
   [items sortUsingComparator:^NSComparisonResult(NSDictionary *a,NSDictionary *b){
      return [a[@"name"] localizedCaseInsensitiveCompare:b[@"name"]];
   }];
   return items;
 }@catch(NSException *e) {NSLog(@"[DuoFacePhone] installed-app-list error=%@",e.name);return @[];}
}
- (void)viewDidLoad {
 [super viewDidLoad];
 if(self.carPlay){
    // CarPlay's UIKit role is only the verified owner of a real remote surface.
    // Never paint fictitious app content in this system-owned window.
    self.nativeSurface=[DFNativeHostSurfaceView new];
    self.nativeSurface.translatesAutoresizingMaskIntoConstraints=NO;
    [self.view addSubview:self.nativeSurface];
    [NSLayoutConstraint activateConstraints:@[
      [self.nativeSurface.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor],
      [self.nativeSurface.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor],
      [self.nativeSurface.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
      [self.nativeSurface.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor]
    ]];return;
 }
 UIImageView *logo=[[UIImageView alloc]initWithImage:[self art:@"duoface-logo"]];
 logo.translatesAutoresizingMaskIntoConstraints=NO;logo.contentMode=UIViewContentModeScaleAspectFit;
 [self.view addSubview:logo];self.mainLogo=logo;
 UISegmentedControl *tabs=[[UISegmentedControl alloc]initWithItems:@[@"Trạng thái",@"Ứng dụng",@"Bố cục"]];
 tabs.translatesAutoresizingMaskIntoConstraints=NO;tabs.selectedSegmentIndex=0;
 tabs.selectedSegmentTintColor=[UIColor colorWithRed:.82 green:.02 blue:.08 alpha:1];
 [tabs addTarget:self action:@selector(tabChanged:) forControlEvents:UIControlEventValueChanged];
 [self.view addSubview:tabs];self.tabs=tabs;
 UILabel *state=[self makeText:15];
 [self.view addSubview:state];self.stateLabel=state;
 UIButton *diagnostics=[UIButton buttonWithType:UIButtonTypeSystem];
 diagnostics.translatesAutoresizingMaskIntoConstraints=NO;
 [diagnostics setTitle:@"Xuất log / lỗi CarPlay" forState:UIControlStateNormal];
 diagnostics.titleLabel.font=[UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
 [diagnostics setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
 diagnostics.backgroundColor=[UIColor colorWithRed:.56 green:.08 blue:.12 alpha:1];
 diagnostics.layer.cornerRadius=10;
 [diagnostics addTarget:self action:@selector(shareCarPlayDiagnostics:)
           forControlEvents:UIControlEventTouchUpInside];
 [self.view addSubview:diagnostics];self.diagnosticsButton=diagnostics;
 UITableView *list=[[UITableView alloc]initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
 list.translatesAutoresizingMaskIntoConstraints=NO;list.backgroundColor=UIColor.blackColor;
 list.dataSource=self;list.delegate=self;list.hidden=YES;list.allowsSelection=YES;
 [self.view addSubview:list];self.appsTable=list;
 [NSLayoutConstraint activateConstraints:@[
   [logo.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:28],
   [logo.centerXAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.centerXAnchor],
   [logo.widthAnchor constraintLessThanOrEqualToAnchor:self.view.safeAreaLayoutGuide.widthAnchor multiplier:.82],
   [logo.widthAnchor constraintEqualToConstant:MIN(320,UIScreen.mainScreen.bounds.size.width*.78)],
   [logo.heightAnchor constraintEqualToConstant:82],
   [tabs.topAnchor constraintEqualToAnchor:logo.bottomAnchor constant:26],
   [tabs.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:22],
   [tabs.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-22],
   [tabs.heightAnchor constraintEqualToConstant:38],
   [state.topAnchor constraintEqualToAnchor:tabs.bottomAnchor constant:32],
   [state.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:22],
   [state.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-22],
   [diagnostics.topAnchor constraintEqualToAnchor:state.bottomAnchor constant:20],
   [diagnostics.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:32],
   [diagnostics.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-32],
   [diagnostics.heightAnchor constraintEqualToConstant:46],
   [list.topAnchor constraintEqualToAnchor:tabs.bottomAnchor constant:12],
   [list.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:14],
   [list.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-14],
   [list.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-6]
 ]];
 self.installedApps=[self queryInstalledApps];
 [self readSavedPreset];
 [list reloadData];
 [self reloadLiveStatus];
}
- (void)reloadLiveStatus {
 if(self.carPlay)return;
 NSDictionary *session=[NSDictionary dictionaryWithContentsOfFile:
   @"/var/mobile/Library/Preferences/com.duoface.nativehost.touchowner.session.plist"];
 NSNumber *stamp=session[@"Timestamp"];
 NSTimeInterval age=[stamp isKindOfClass:NSNumber.class]?
      NSDate.date.timeIntervalSince1970-stamp.doubleValue:INFINITY;
 BOOL active=[session[@"Active"] boolValue] && isfinite(age) && age>=0 && age<=2.5;
 self.stateLabel.text=active?
      @"CarPlay: phiên điều khiển đang hoạt động\nMở App trên màn hình xe để chọn ứng dụng":
      @"CarPlay: không có phiên điều khiển đang hoạt động\nKết nối CarPlay và mở DuoFace trên màn hình xe";
}
- (void)readSavedPreset {
 NSDictionary *record=[NSDictionary dictionaryWithContentsOfFile:
       @"/var/mobile/Library/Preferences/com.duoface.nativehost.layout.v1.plist"];
 NSInteger n=[record[@"Preset"] isKindOfClass:NSNumber.class]?
       [record[@"Preset"] integerValue]:
       (record?([record[@"Vertical"] boolValue]?0:1):0);
 if([record[@"Version"] isEqual:@1]){
    const NSInteger legacy[9]={1,2,4,5,6,7,8,3,0};
    n=(n>=0 && n<=8)?legacy[n]:1;
 }
 self.currentPreset=MAX(0,MIN(8,n));
}
- (BOOL)writeNativeLayoutPreset:(NSInteger)preset {
 if(preset<0||preset>8)return NO;
 NSString *path=@"/var/mobile/Library/Preferences/com.duoface.nativehost.layout.v1.plist";
 NSDictionary *old=[NSDictionary dictionaryWithContentsOfFile:path]?:@{};
 NSNumber *ratio=@(DFNative12DefaultPrimaryRatio(preset));
 NSNumber *logo=[old[@"LogoFraction"] isKindOfClass:NSNumber.class]?old[@"LogoFraction"]:@.5;
 double r=ratio.doubleValue,l=logo.doubleValue;
 if(!isfinite(r)||r<1.0/3.0||r>2.0/3.0)ratio=@.5;
 if(!isfinite(l)||l<.1||l>.9)logo=@.5;
 NSNumber *swapped=[old[@"Swapped"] isKindOfClass:NSNumber.class]?old[@"Swapped"]:@NO;
 BOOL vertical=(preset!=2&&preset!=6&&preset!=7);
 // Original Native12 presetSelected: @0xaa4f0 commits selected tag to
 // BOTH splitPreset and splitMode before notifying active Dashboard.
 // Only recreate this observable state update in independent DuoFace.
 NSDictionary *state=@{@"Version":@2,@"Preset":@(preset),
                       @"splitPreset":@(preset),@"splitMode":@(preset),
                       @"Ratio":ratio,@"Secondary":@(DFNative12DefaultSecondaryRatio(preset)),@"LogoFraction":logo,
                       @"Vertical":@(vertical),@"Swapped":swapped};
 if(![state writeToFile:path atomically:YES])return NO;
 self.currentPreset=preset;
 // A real SpringBoard owner consumes this; do not render duplicate app panes.
 notify_post("com.duoface.nativehost.layout.changed.v1");
 return YES;
}
- (void)shareCarPlayDiagnostics:(UIButton *)sender {
    if(self.carPlay)return;
    UIAlertController *confirm=[UIAlertController alertControllerWithTitle:@"Xuất chẩn đoán DuoFace"
       message:@"Chỉ lấy log DuoFace và tối đa 3 báo cáo lỗi SpringBoard/CarPlay gần đây. Báo cáo có thể chứa tên ứng dụng và thông tin kỹ thuật. Không tự gửi lên mạng; bạn quyết định nơi chia sẻ."
       preferredStyle:UIAlertControllerStyleAlert];
    [confirm addAction:[UIAlertAction actionWithTitle:@"Hủy"
         style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf=self;
    [confirm addAction:[UIAlertAction actionWithTitle:@"Tạo báo cáo"
         style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        (void)action;
        typeof(self) strongSelf=weakSelf;
        if(!strongSelf)return;
        NSArray<NSURL *> *items=[DFNativeDiagnostics prepareShareFiles];
        if(!items.count){
            UIAlertController *error=[UIAlertController alertControllerWithTitle:@"Không tạo được báo cáo"
               message:@"Không ghi được file chẩn đoán vào thư mục tạm."
               preferredStyle:UIAlertControllerStyleAlert];
            [error addAction:[UIAlertAction actionWithTitle:@"Đóng" style:UIAlertActionStyleDefault handler:nil]];
            [strongSelf presentViewController:error animated:YES completion:nil];
            return;
        }
        UIActivityViewController *activity=[[UIActivityViewController alloc]
                  initWithActivityItems:items applicationActivities:nil];
        UIPopoverPresentationController *popover=activity.popoverPresentationController;
        if(popover){
            popover.sourceView=sender;
            popover.sourceRect=sender.bounds;
        }
        [strongSelf presentViewController:activity animated:YES completion:nil];
    }]];
    [self presentViewController:confirm animated:YES completion:nil];
}
- (void)tabChanged:(UISegmentedControl *)control {
 BOOL showingList=(control.selectedSegmentIndex!=0);
 self.stateLabel.hidden=showingList;self.diagnosticsButton.hidden=showingList;
 self.appsTable.hidden=!showingList;
 if(showingList){
   if(control.selectedSegmentIndex==1)self.installedApps=[self queryInstalledApps];
   else [self readSavedPreset];
   [self.appsTable reloadData];
 }
 else [self reloadLiveStatus];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
 (void)tableView;(void)section;
 return self.tabs.selectedSegmentIndex==2?10:(NSInteger)self.installedApps.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
 UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:@"DuoFaceInstalled"];
 if(!cell)cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle
                                     reuseIdentifier:@"DuoFaceInstalled"];
 if(self.tabs.selectedSegmentIndex==2 && indexPath.row==9){
    cell.textLabel.text=@"Thử nghiệm bản đồ CarPlay native";
    cell.detailTextLabel.text=@"Gắn / khôi phục Maps trên CarPlay, chỉ khi xe đang đỗ";
    cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
 } else if(self.tabs.selectedSegmentIndex==2){
    NSArray *titles=@[@"Một khung",@"Trái / phải",@"Trên / dưới",
        @"Ba cột",@"Một trái, hai phải",@"Hai trái, một phải",
        @"Một trên, hai dưới",@"Hai trên, một dưới",@"Bốn ô"];
    NSInteger preset=indexPath.row;
    cell.textLabel.text=titles[(NSUInteger)preset];
    cell.detailTextLabel.text=@"Bố cục scene thật trên CarPlay";
    cell.accessoryType=preset==self.currentPreset?
       UITableViewCellAccessoryCheckmark:UITableViewCellAccessoryNone;
 } else {
    NSDictionary *item=self.installedApps[(NSUInteger)indexPath.row];
    cell.textLabel.text=item[@"name"];cell.detailTextLabel.text=item[@"bundle"];
    cell.accessoryType=UITableViewCellAccessoryNone;
 }
 cell.backgroundColor=[UIColor colorWithWhite:.10 alpha:1];
 cell.textLabel.textColor=UIColor.whiteColor;
 cell.detailTextLabel.textColor=[UIColor colorWithWhite:.7 alpha:1];
 return cell;
}
- (void)nativeMapPaneCommand:(NSString *)operation slot:(NSInteger)slot {
    // An actual opt-in action from the iPhone app, never an automatic hook
    // on Maps navigation. CarPlay-only coordinator verifies one genuine
    // DBApplicationSceneViewController, real system Dock and same UIWindow.
    NSString *request=NSUUID.UUID.UUIDString;
    NSString *commandPath=@"/var/mobile/Library/Preferences/com.duoface.nativehost.map-pane.command.v1.plist";
    NSDictionary *record=@{@"Version":@1,@"Operation":operation,
        @"MapSlot":@(slot),@"RequestID":request,
        @"Timestamp":@(NSDate.date.timeIntervalSince1970)};
    if(![record writeToFile:commandPath atomically:YES]){
        [self nativeMapPaneAlert:@"Không gửi được lệnh" detail:@"Không thể ghi yêu cầu vào iPhone. Bản đồ trên xe không bị thay đổi."];
        return;
    }
    notify_post("com.duoface.nativehost.map-pane.command.v1");
    __weak typeof(self) weakSelf=self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(1.5*NSEC_PER_SEC)),
                   dispatch_get_main_queue(),^{
        typeof(self) strongSelf=weakSelf;
        if(!strongSelf || !strongSelf.isViewLoaded || !strongSelf.view.window)return;
        NSDictionary *ack=[NSDictionary dictionaryWithContentsOfFile:
          @"/var/mobile/Library/Preferences/com.duoface.nativehost.map-pane.ack.v1.plist"];
        if(![ack[@"RequestID"] isEqualToString:request]){
            [strongSelf nativeMapPaneAlert:@"Chưa có phản hồi CarPlay"
                detail:@"Chưa nhận được ACK. Có thể chưa có CarPlay hoặc bộ thử nghiệm chưa được cài. Không coi là bản đồ đã ghép thành công."];
            return;
        }
        BOOL applied=[ack[@"Applied"] isEqual:@YES];
        NSString *detail=[NSString stringWithFormat:
            @"%@: %@. ACK chỉ xác nhận thao tác controller, KHÔNG xác nhận Maps vẽ đúng hoặc dẫn đường liên tục.",
            ack[@"OwnerProcess"]?:@"CarPlay",ack[@"Reason"]?:@"unknown"];
        [strongSelf nativeMapPaneAlert:applied?@"Đã nhận thao tác":@"CarPlay từ chối ghép" detail:detail];
    });
}
- (void)nativeMapPaneAlert:(NSString *)title detail:(NSString *)detail {
    if(self.presentedViewController)return;
    UIAlertController *alert=[UIAlertController alertControllerWithTitle:title message:detail
       preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Đóng" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}
- (void)showNativeMapPaneChoices {
    UIAlertController *menu=[UIAlertController alertControllerWithTitle:@"Maps native — thử nghiệm"
        message:@"Chỉ dùng khi xe đang đỗ. Mở Google Maps trực tiếp trên CarPlay và giữ bản đồ hiện trên xe. DuoFace thử chuyển controller native sang một ô, có thể bị hệ thống từ chối. Không đổi giấy phép/CarPlay Customize, không phóng to Maps iPhone."
        preferredStyle:UIAlertControllerStyleAlert];
    __weak typeof(self) weakSelf=self;
    [menu addAction:[UIAlertAction actionWithTitle:@"Bản đồ bên trái"
        style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *a){
            [weakSelf nativeMapPaneCommand:@"Attach" slot:0];
        }]];
    [menu addAction:[UIAlertAction actionWithTitle:@"Bản đồ bên phải"
        style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *a){
            [weakSelf nativeMapPaneCommand:@"Attach" slot:1];
        }]];
    [menu addAction:[UIAlertAction actionWithTitle:@"Khôi phục giao diện Maps"
        style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *a){
            [weakSelf nativeMapPaneCommand:@"Restore" slot:0];
        }]];
    [menu addAction:[UIAlertAction actionWithTitle:@"Hủy" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:menu animated:YES completion:nil];
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
 [tableView deselectRowAtIndexPath:indexPath animated:YES];
 if(self.tabs.selectedSegmentIndex!=2)return;
 if(indexPath.row==9) {
    [self showNativeMapPaneChoices];
    return;
 }
 BOOL success=[self writeNativeLayoutPreset:indexPath.row];
 if(success){[self.appsTable reloadData];return;}
 UIAlertController *alert=[UIAlertController alertControllerWithTitle:@"Không lưu được bố cục"
   message:@"Không ghi được cấu hình DuoFace. Bố cục CarPlay hiện tại không bị thay đổi."
   preferredStyle:UIAlertControllerStyleAlert];
 [alert addAction:[UIAlertAction actionWithTitle:@"Đóng" style:UIAlertActionStyleDefault handler:nil]];
 [self presentViewController:alert animated:YES completion:nil];
}
- (void)viewDidAppear:(BOOL)animated {
 [super viewDidAppear:animated];
 if(self.carPlay)[self.nativeSurface start];
 else [self reloadLiveStatus];
}
- (void)viewWillDisappear:(BOOL)animated {
 [self.nativeSurface stop];[super viewWillDisappear:animated];
}
@end
