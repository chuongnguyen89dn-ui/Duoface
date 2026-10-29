// First-party DuoFace startup. Show genuine device/session data only.
// Do not draw sample split panes, fake app scenes or inert settings controls.
#import <UIKit/UIKit.h>
#import "DFAppEligibility.h"
#import "DFAppCatalogPolicy.h"
#import "DFEnabledAppsPolicy.h"
#import "DFAppHabits.h"
#import "DFNativeDiagnostics.h"
#import "DFLayoutEngine.h"
#import <objc/message.h>
#import <math.h>
#import <notify.h>
@interface DFNativeHostSurfaceView : UIView
- (void)start;
- (void)stop;
@end

@interface DFAppHabitsController : UITableViewController
@property(nonatomic,copy) NSArray<NSDictionary *> *inventory;
- (instancetype)initWithInventory:(NSArray<NSDictionary *> *)inventory;
@end
@implementation DFAppHabitsController
- (instancetype)initWithInventory:(NSArray<NSDictionary *> *)inventory {
 if((self=[super initWithStyle:UITableViewStyleInsetGrouped]))
    _inventory=[inventory copy];
 return self;
}
- (void)viewDidLoad {
 [super viewDidLoad];
 self.title=@"Mặc định & Ưa dùng";
 self.tableView.backgroundColor=UIColor.systemBackgroundColor;
 self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc]
     initWithBarButtonSystemItem:UIBarButtonSystemItemDone
     target:self action:@selector(closeHabitSettings)];
}
- (void)closeHabitSettings {[self dismissViewControllerAnimated:YES completion:nil];}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
 (void)tableView;(void)section;return (NSInteger)self.inventory.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView
       cellForRowAtIndexPath:(NSIndexPath *)indexPath {
 UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:@"habit"];
 if(!cell)cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"habit"];
 NSDictionary *app=self.inventory[(NSUInteger)indexPath.row];
 NSString *bid=app[@"bundle"];
 NSDictionary *choices=DFCurrentAppChoices();
 NSDictionary *counts=DFReadAppHabitCountsAtPath(DFAppHabitCountsPath);
 BOOL isDefault=[choices[@"DefaultBundleID"] isEqualToString:bid];
 BOOL pinned=[choices[@"PinnedBundleIDs"] containsObject:bid];
 cell.textLabel.text=app[@"name"];
 cell.detailTextLabel.text=[NSString stringWithFormat:@"%@%@ · Đã chọn %ld lần",
     isDefault?@"Mặc định · ":@"",pinned?@"Ưa dùng":@"Ứng dụng khác",
     (long)[counts[bid] integerValue]];
 cell.accessoryType=isDefault?UITableViewCellAccessoryCheckmark:
    (pinned?UITableViewCellAccessoryDetailDisclosureButton:UITableViewCellAccessoryDisclosureIndicator);
 return cell;
}
- (void)saveDefault:(NSString *)preferred pinned:(NSArray<NSString *> *)pinned {
 if(DFSaveAppChoices(preferred,pinned)){
     [self.tableView reloadData];return;
 }
 UIAlertController *error=[UIAlertController alertControllerWithTitle:@"Không lưu được"
      message:@"Không xác minh được dữ liệu mặc định/ưa dùng." preferredStyle:UIAlertControllerStyleAlert];
 [error addAction:[UIAlertAction actionWithTitle:@"Đóng" style:UIAlertActionStyleDefault handler:nil]];
 [self presentViewController:error animated:YES completion:nil];
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
 [tableView deselectRowAtIndexPath:indexPath animated:YES];
 if((NSUInteger)indexPath.row>=self.inventory.count)return;
 NSDictionary *app=self.inventory[(NSUInteger)indexPath.row];
 NSString *bid=app[@"bundle"];
 if(!DFIsEligibleAppID(bid))return;
 NSDictionary *choice=DFCurrentAppChoices();
 NSString *preferred=choice[@"DefaultBundleID"];
 NSArray *pinned=choice[@"PinnedBundleIDs"];
 BOOL isDefault=[preferred isEqualToString:bid];
 BOOL alreadyPinned=[pinned containsObject:bid];
 UIAlertController *menu=[UIAlertController alertControllerWithTitle:app[@"name"]
   message:@"Mặc định chỉ được ưu tiên hiển thị trong bảng chọn CarPlay. Không tự chạy hay gán vào cột/ô."
   preferredStyle:UIAlertControllerStyleActionSheet];
 __weak typeof(self) weakSelf=self;
 if(!isDefault){
   [menu addAction:[UIAlertAction actionWithTitle:@"Đặt làm ứng dụng mặc định"
      style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action){
        [weakSelf saveDefault:bid pinned:pinned];
   }]];
 }else{
   [menu addAction:[UIAlertAction actionWithTitle:@"Bỏ mặc định"
      style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action){
        [weakSelf saveDefault:@"" pinned:pinned];
   }]];
 }
 [menu addAction:[UIAlertAction actionWithTitle:
   alreadyPinned?@"Bỏ khỏi Ưa dùng":@"Thêm vào Ưa dùng"
   style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
    NSMutableArray *updated=[pinned mutableCopy];
    if(alreadyPinned)[updated removeObject:bid];else [updated addObject:bid];
    [weakSelf saveDefault:preferred pinned:updated];
 }]];
 [menu addAction:[UIAlertAction actionWithTitle:@"Hủy" style:UIAlertActionStyleCancel handler:nil]];
 UIPopoverPresentationController *popover=menu.popoverPresentationController;
 if(popover){
    UITableViewCell *cell=[tableView cellForRowAtIndexPath:indexPath];
    popover.sourceView=cell;
    popover.sourceRect=cell.bounds;
 }
 [self presentViewController:menu animated:YES completion:nil];
}
@end

@interface DFNativeHostRootController : UIViewController <UITableViewDataSource,UITableViewDelegate,UISearchBarDelegate>
@property(nonatomic,assign) BOOL carPlay;
@property(nonatomic,strong) DFNativeHostSurfaceView *nativeSurface;
@property(nonatomic,strong) UIImageView *mainLogo;
@property(nonatomic,strong) UILabel *stateLabel;
@property(nonatomic,strong) UIButton *diagnosticsButton;
@property(nonatomic,strong) UISegmentedControl *tabs;
@property(nonatomic,strong) UITableView *appsTable;
@property(nonatomic,strong) NSArray<NSDictionary *> *installedApps;
@property(nonatomic,copy) NSString *appSearch;
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
   return DFCatalogRecordsFromProxies((NSArray *)result);
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
 UISearchBar *appSearchBar=[UISearchBar new];
 appSearchBar.placeholder=@"Tìm ứng dụng đã cài";
 appSearchBar.searchBarStyle=UISearchBarStyleMinimal;
 appSearchBar.delegate=self;
 list.tableHeaderView=appSearchBar;
 self.appSearch=@"";

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
- (void)searchBar:(UISearchBar *)bar textDidChange:(NSString *)text {
 (void)bar;self.appSearch=text?:@"";[self.appsTable reloadData];
}
- (NSArray<NSDictionary *> *)appsInGroup:(NSInteger)section {
 if(section<1||section>3)return @[];
 NSArray<NSString *> *enabled=DFConfiguredEnabledAppIDs();
 NSMutableArray *items=[NSMutableArray new];
 for(NSDictionary *app in self.installedApps){
  NSString *bid=app[@"bundle"],*name=app[@"name"];
  BOOL selected=!enabled||[enabled containsObject:bid];
  BOOL system=[app[@"kind"] isEqual:@"system"];
  BOOL matches=!self.appSearch.length||
    [name localizedCaseInsensitiveContainsString:self.appSearch]||
    [bid localizedCaseInsensitiveContainsString:self.appSearch];
  if(!matches)continue;
  if((section==1&&selected)||(section==2&&!selected&&!system)||
     (section==3&&!selected&&system))[items addObject:app];
 }
 return items;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
 (void)tableView;return self.tabs.selectedSegmentIndex==1?4:1;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
 (void)tableView;
 if(self.tabs.selectedSegmentIndex!=1)return nil;
 return @[@"Quản lý",@"My Apps — Đã chọn",@"Ứng dụng khác",@"Ứng dụng hệ thống"][(NSUInteger)section];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
 (void)tableView;
 if(self.tabs.selectedSegmentIndex==2)return 10;
 if(self.tabs.selectedSegmentIndex!=1)return 0;
 return section==0?3:(NSInteger)[self appsInGroup:section].count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
 UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:@"DuoFaceInstalled"];
 if(!cell)cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle
                                     reuseIdentifier:@"DuoFaceInstalled"];
 cell.accessoryView=nil;
 if(self.tabs.selectedSegmentIndex==1 && indexPath.section==0){
    NSArray *titles=@[@"⋯ Tùy chọn ứng dụng",@"Bản đồ CarPlay native",@"Mặc định & Ưa dùng"];
    NSArray *descriptions=@[@"Bật đề xuất / Bật tất cả / Tắt tất cả",
       @"Maps native: ghép/khôi phục, chỉ khi xe đang đỗ",
       @"Chọn ứng dụng ưu tiên cho bảng chọn CarPlay, không gán ô"];
    cell.textLabel.text=titles[(NSUInteger)indexPath.row];
    cell.detailTextLabel.text=descriptions[(NSUInteger)indexPath.row];
    cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
 } else if(self.tabs.selectedSegmentIndex==2 && indexPath.row==9){
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
    NSDictionary *item=[self appsInGroup:indexPath.section][(NSUInteger)indexPath.row];
    cell.textLabel.text=item[@"name"];cell.detailTextLabel.text=item[@"bundle"];
    UISwitch *toggle=[UISwitch new];
    toggle.tag=[self.installedApps indexOfObjectIdenticalTo:item];
     toggle.accessibilityLabel=[NSString stringWithFormat:@"Cho phép %@",item[@"name"]];
    NSArray *enabled=DFConfiguredEnabledAppIDs();
    [toggle setOn:(!enabled || [enabled containsObject:item[@"bundle"]]) animated:NO];
    [toggle addTarget:self action:@selector(appSwitchToggled:)
         forControlEvents:UIControlEventValueChanged];
    cell.accessoryView=toggle;
    cell.accessoryType=UITableViewCellAccessoryNone;
 }
 cell.backgroundColor=[UIColor colorWithWhite:.10 alpha:1];
 cell.textLabel.textColor=UIColor.whiteColor;
 cell.detailTextLabel.textColor=[UIColor colorWithWhite:.7 alpha:1];
 return cell;
}
- (void)showHabitSettings {
 NSArray *enabled=DFConfiguredEnabledAppIDs();
 NSMutableArray<NSDictionary *> *candidates=[NSMutableArray new];
 for(NSDictionary *app in self.installedApps) {
    if(DFPickerAllowsApp(app[@"bundle"],enabled))[candidates addObject:app];
 }
 DFAppHabitsController *manager=[[DFAppHabitsController alloc]initWithInventory:candidates];
 UINavigationController *navigation=[[UINavigationController alloc]initWithRootViewController:manager];
 [self presentViewController:navigation animated:YES completion:nil];
}
- (void)appSettingsSaveFailed {
 UIAlertController *alert=[UIAlertController alertControllerWithTitle:@"Không lưu được ứng dụng"
   message:@"Không xác nhận được dữ liệu đã lưu. Kiểm tra quyền ghi và thử lại."
   preferredStyle:UIAlertControllerStyleAlert];
 [alert addAction:[UIAlertAction actionWithTitle:@"Đóng" style:UIAlertActionStyleDefault handler:nil]];
 [self presentViewController:alert animated:YES completion:nil];
}
- (NSArray<NSString *> *)allEligibleBundleIDs {
 NSMutableArray<NSString *> *items=[NSMutableArray new];
 for(NSDictionary *record in self.installedApps){
   NSString *bid=record[@"bundle"];
   if(DFIsEligibleAppID(bid))[items addObject:bid];
 }
 return items;
}
- (void)appSwitchToggled:(UISwitch *)sender {
 NSInteger index=sender.tag;
 if(index<0 || (NSUInteger)index>=self.installedApps.count)return;
 NSString *bid=self.installedApps[(NSUInteger)index][@"bundle"];
 if(!DFIsEligibleAppID(bid))return;
 NSArray *existing=DFConfiguredEnabledAppIDs();
 NSMutableOrderedSet<NSString *> *updated=[NSMutableOrderedSet orderedSetWithArray:
     existing?:[self allEligibleBundleIDs]];
 if(sender.on)[updated addObject:bid];else [updated removeObject:bid];
 if(!DFWriteEnabledAppIDs(updated.array)){[sender setOn:!sender.on animated:YES];[self appSettingsSaveFailed];return;}
 [self.appsTable reloadData];
}
- (void)showAppSettingsActions {
 UIAlertController *sheet=[UIAlertController alertControllerWithTitle:@"Quản lý ứng dụng DuoFace"
   message:@"Bật đề xuất = các app người dùng đã cài (không gồm app Apple). Bật tất cả = mọi app hợp lệ. Không đóng app đang chạy."
   preferredStyle:UIAlertControllerStyleActionSheet];
 __weak typeof(self) weakSelf=self;
 [sheet addAction:[UIAlertAction actionWithTitle:@"Bật tất cả"
   style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *a){
   typeof(self) owner=weakSelf;if(!owner)return;
   if(!DFWriteEnabledAppIDs([owner allEligibleBundleIDs]))[owner appSettingsSaveFailed];
   [owner.appsTable reloadData];
 }]];
 [sheet addAction:[UIAlertAction actionWithTitle:@"Bật đề xuất"
   style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *a){
   typeof(self) owner=weakSelf;if(!owner)return;
   NSMutableArray<NSString *> *recommended=[NSMutableArray new];
   for(NSString *bid in [owner allEligibleBundleIDs])
      if(DFIsRecommendedAppID(bid))[recommended addObject:bid];
   // Replace previous enabled set, never union with default all-eligible.
   if(!DFWriteEnabledAppIDs(recommended))[owner appSettingsSaveFailed];
   [owner.appsTable reloadData];
 }]];
 [sheet addAction:[UIAlertAction actionWithTitle:@"Tắt tất cả"
   style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *a){
   typeof(self) owner=weakSelf;if(!owner)return;
   if(!DFWriteEnabledAppIDs(@[]))[owner appSettingsSaveFailed];
   [owner.appsTable reloadData];
 }]];
 [sheet addAction:[UIAlertAction actionWithTitle:@"Hủy" style:UIAlertActionStyleCancel handler:nil]];
 UIPopoverPresentationController *popover=sheet.popoverPresentationController;
 if(popover){popover.sourceView=self.appsTable;popover.sourceRect=CGRectMake(
        self.appsTable.bounds.size.width-44,24,36,36);}
 [self presentViewController:sheet animated:YES completion:nil];
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
 if(self.tabs.selectedSegmentIndex==1){
  if(indexPath.section==0){
    if(indexPath.row==0)[self showAppSettingsActions];
    else if(indexPath.row==1)[self showNativeMapPaneChoices];
    else [self showHabitSettings];
  } else {
    UITableViewCell *cell=[tableView cellForRowAtIndexPath:indexPath];
    UISwitch *toggle=[cell.accessoryView isKindOfClass:UISwitch.class]?
      (UISwitch *)cell.accessoryView:nil;
    if(toggle){[toggle setOn:!toggle.on animated:YES];[self appSwitchToggled:toggle];}
  }
  return;
 }
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
