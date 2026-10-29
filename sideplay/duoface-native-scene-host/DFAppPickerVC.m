// First-party DuoFace app selection — independently implemented from the
// Native12 CBMultitaskingOverlayView CARD/RECENT behavior contract.
// Real installed bundles from DFAppLibrary; no private vendor runtime.
#import "DFAppPickerVC.h"
#import "DFNative12CardHeaderGeometry.h"
#import "DFNative12MenuHeader.h"
#import "DFAppLibrary.h"
#import "DFEnabledAppsPolicy.h"
#import "DFAppHabits.h"
#import "DFAppPickerDisplayPolicy.h"
#import "DFExtendedSettingsPolicy.h"
#import <notify.h>
#import <objc/message.h>
#import <math.h>


// Add More is explicitly a SECONDARY management view, never the primary App grid.
// Tapping an eligible disabled installed app first persists permission to the
// SAME preferences used by the iPhone; it does NOT start a remote scene.
@interface DFAddMoreAppsController : UITableViewController
- (instancetype)initWithDisabledApps:(NSArray<DFAppInfo *> *)apps;
@property(nonatomic,copy) NSArray<DFAppInfo *> *candidates;
@property(nonatomic,copy) void (^didEnable)(void);
@end
@implementation DFAddMoreAppsController
- (instancetype)initWithDisabledApps:(NSArray<DFAppInfo *> *)apps {
 if((self=[super initWithStyle:UITableViewStylePlain]))_candidates=[apps copy];
 return self;
}
- (void)viewDidLoad {
 [super viewDidLoad];
 self.title=DFLocalize(@"Thêm App",@"Add More");
 self.tableView.backgroundColor=UIColor.blackColor;
 self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc]
     initWithBarButtonSystemItem:UIBarButtonSystemItemDone
     target:self action:@selector(closeAddMore)];
 UILabel *explanation=[UILabel new];
 explanation.text=@"Chạm để cho phép ứng dụng. Thay đổi cũng xuất hiện trong cài đặt iPhone. Không tự mở ứng dụng.";
 explanation.numberOfLines=0;
 explanation.textAlignment=NSTextAlignmentCenter;
 explanation.font=[UIFont systemFontOfSize:12];
 explanation.textColor=UIColor.whiteColor;
 explanation.frame=CGRectMake(0,0,240,62);
 self.tableView.tableHeaderView=explanation;
 if(!self.candidates.count){
   UILabel *empty=[UILabel new];
   empty.text=@"Không còn ứng dụng hợp lệ chưa được bật. Có thể quản lý danh sách trong DuoFace trên iPhone.";
   empty.numberOfLines=0;
   empty.textAlignment=NSTextAlignmentCenter;
   empty.textColor=UIColor.whiteColor;
   self.tableView.backgroundView=empty;
 }
}
- (void)closeAddMore {[self dismissViewControllerAnimated:YES completion:nil];}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
 (void)tableView;(void)section;return (NSInteger)self.candidates.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView
       cellForRowAtIndexPath:(NSIndexPath *)indexPath {
 UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:@"DFAddMoreRow"];
 if(!cell)cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle
                      reuseIdentifier:@"DFAddMoreRow"];
 DFAppInfo *app=self.candidates[(NSUInteger)indexPath.row];
 cell.textLabel.text=app.displayName;
 cell.detailTextLabel.text=@"Cho phép xuất hiện trong DuoFace";
 cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
 cell.backgroundColor=UIColor.blackColor;
 cell.textLabel.textColor=UIColor.whiteColor;
 cell.detailTextLabel.textColor=[UIColor colorWithWhite:.7 alpha:1];
 return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
 [tableView deselectRowAtIndexPath:indexPath animated:YES];
 if((NSUInteger)indexPath.row>=self.candidates.count)return;
 NSString *bid=self.candidates[(NSUInteger)indexPath.row].bundleID;
 if(!DFIsEligibleAppID(bid))return;
 NSArray<NSString *> *allowed=DFConfiguredEnabledAppIDs()?:@[];
 NSMutableOrderedSet<NSString *> *updated=[NSMutableOrderedSet orderedSetWithArray:allowed];
 [updated addObject:bid];
 if(!DFWriteEnabledAppIDs(updated.array)){
   UIAlertController *error=[UIAlertController alertControllerWithTitle:@"Không thể thêm App"
      message:@"Cấu hình iPhone chưa xác nhận lưu thành công; ứng dụng vẫn bị ẩn."
      preferredStyle:UIAlertControllerStyleAlert];
   [error addAction:[UIAlertAction actionWithTitle:@"Đóng"
         style:UIAlertActionStyleCancel handler:nil]];
   [self presentViewController:error animated:YES completion:nil];
   return;
 }
 if(self.didEnable)self.didEnable();
 [self dismissViewControllerAnimated:YES completion:nil];
}
@end

@interface DFNativeAppCard : UICollectionViewCell
@property(nonatomic,strong) UIImageView *icon;
@property(nonatomic,strong) UILabel *title;
@property(nonatomic,strong) UILabel *runningDetail;
@property(nonatomic,strong) UIButton *closeRunning;
@property(nonatomic,strong) UIButton *restartRunning;
@property(nonatomic,assign) BOOL runningControls;
// 0: not hosted, 1: verified current slot, 2: verified other slot.
@property(nonatomic,assign) NSInteger appBadgeKind;
@property(nonatomic,assign) NSInteger appGridColumns;
@property(nonatomic,assign) BOOL showsAppName;
@property(nonatomic,strong) UIImageView *appStateBadge;
@end
@implementation DFNativeAppCard
- (instancetype)initWithFrame:(CGRect)frame {
    if((self=[super initWithFrame:frame])){
        self.contentView.backgroundColor=[UIColor colorWithWhite:.19 alpha:.96];
        self.contentView.layer.cornerRadius=14; // Native12 original running-card radius @0xa6b30
        self.contentView.layer.masksToBounds=YES;
        self.icon=[UIImageView new];
        self.icon.contentMode=UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:self.icon];
        self.title=[UILabel new];
        self.title.textColor=UIColor.whiteColor;
        self.title.font=[UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
        self.title.textAlignment=NSTextAlignmentCenter;
        self.title.lineBreakMode=NSLineBreakByTruncatingTail;
        [self.contentView addSubview:self.title];
        self.runningDetail=[UILabel new];
        self.runningDetail.textColor=[UIColor colorWithWhite:.78 alpha:1];
        self.runningDetail.font=[UIFont systemFontOfSize:8 weight:UIFontWeightRegular];
        self.runningDetail.textAlignment=NSTextAlignmentCenter;
        self.runningDetail.adjustsFontSizeToFitWidth=YES;
        self.runningDetail.minimumScaleFactor=.8;
        [self.contentView addSubview:self.runningDetail];
        // Original @a522c/@a5374 uses real badge UIImageViews, not color fills.
        self.appStateBadge=[UIImageView new];
        self.appStateBadge.contentMode=UIViewContentModeScaleAspectFit;
        self.appStateBadge.userInteractionEnabled=NO;
        self.appStateBadge.layer.shadowColor=UIColor.blackColor.CGColor;
        self.appStateBadge.layer.shadowOpacity=.5;
        self.appStateBadge.layer.shadowRadius=2.5;
        self.appStateBadge.layer.shadowOffset=CGSizeMake(0,1);
        [self.contentView addSubview:self.appStateBadge];
        // Native12 setupRecentAppsCards @0xa678c creates independent
        // OVERLAY_RESTART_SINGLE and OVERLAY_CLOSE_SINGLE controls.
        self.closeRunning=[UIButton buttonWithType:UIButtonTypeCustom];
        [self.closeRunning setTitle:DFLocalize(@"Đóng",@"Close") forState:UIControlStateNormal];
        self.closeRunning.titleLabel.font=[UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
        self.closeRunning.tintColor=UIColor.whiteColor;
        // Match the proven original CLOSE ALL red instead of a guessed shade.
        self.closeRunning.backgroundColor=
            [UIColor colorWithRed:.88 green:.18 blue:.22 alpha:.95];
        self.closeRunning.layer.cornerRadius=6;
        [self.contentView addSubview:self.closeRunning];
        self.restartRunning=[UIButton buttonWithType:UIButtonTypeCustom];
        [self.restartRunning setTitle:DFLocalize(@"Khởi động lại",@"Restart") forState:UIControlStateNormal];
        self.restartRunning.titleLabel.font=[UIFont systemFontOfSize:9 weight:UIFontWeightMedium];
        self.restartRunning.tintColor=UIColor.whiteColor;
        self.restartRunning.backgroundColor=[UIColor colorWithWhite:.28 alpha:.96];
        self.restartRunning.layer.cornerRadius=6;
        [self.contentView addSubview:self.restartRunning];
        self.accessibilityTraits=UIAccessibilityTraitButton;
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w=self.bounds.size.width,h=self.bounds.size.height;
    CGFloat iconSide=MIN(43,MAX(16,h-(self.runningControls?68:(self.showsAppName?26:10))));
    self.icon.frame=CGRectMake((w-iconSide)/2,5,iconSide,iconSide);
    // Original Native12 App icon only: corner multiplier at 0xa493c-0xa4940.
    // Preserve running-card styling; its icon treatment is a separate surface.
    self.icon.layer.cornerRadius=self.runningControls?0:(.225*iconSide);
    self.icon.layer.masksToBounds=!self.runningControls;
    // Original ARM64 @a4c24-a4c48, VM coefficients -.65, -.20,
    // a523c/a538c badge CGRect from icon bounds. This badge overlaps
    // icon's upper-right, and never replaces the icon or the App cell.
    CGFloat badgeSide=iconSide<40?14:(self.appGridColumns==6?16:18);
    self.appStateBadge.frame=CGRectMake(CGRectGetMaxX(self.icon.frame)-.65*badgeSide,
                       CGRectGetMinY(self.icon.frame)-.20*badgeSide,badgeSide,badgeSide);
    self.appStateBadge.hidden=self.runningControls || self.appBadgeKind==0;
    if(!self.appStateBadge.hidden)[self.contentView bringSubviewToFront:self.appStateBadge];
    self.title.frame=CGRectMake(2,CGRectGetMaxY(self.icon.frame)+1,w-4,MIN(16,MAX(10,h- CGRectGetMaxY(self.icon.frame)-2)));
    self.title.hidden=!self.runningControls && !self.showsAppName;
    self.runningDetail.hidden=!self.runningControls;
    self.runningDetail.frame=CGRectMake(2,CGRectGetMaxY(self.title.frame)+1,w-4,14);
    self.closeRunning.hidden=!self.runningControls;
    self.restartRunning.hidden=!self.runningControls;
    if(self.runningControls){
        CGFloat bh=MIN(21,MAX(18,h*.23));
        self.closeRunning.frame=CGRectMake(3,h-bh-3,(w-9)/2,bh);
        self.restartRunning.frame=CGRectMake((w-9)/2+6,h-bh-3,(w-9)/2,bh);
    }
}
@end

@interface DFAppPickerVC () <UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>
@property(nonatomic,strong) UIView *sheet;
@property(nonatomic,strong) UIVisualEffectView *sheetMaterial;
@property(nonatomic,strong) UIView *modes;
@property(nonatomic,strong) NSArray<UIButton *> *modeButtons;
@property(nonatomic,strong) UIButton *zoomButton;
@property(nonatomic,assign) NSInteger currentMode;
@property(nonatomic,strong) UIImageView *headerIcon;
@property(nonatomic,strong) UIView *headerSeparator;
@property(nonatomic,strong) UIImageView *emptyImage;
@property(nonatomic,strong) UILabel *emptyTitle;
@property(nonatomic,strong) UICollectionView *cards;
@property(nonatomic,strong) UIPageControl *pageControl;
@property(nonatomic,strong) UIButton *categoryButton;
@property(nonatomic,assign) NSInteger categoryMode;
@property(nonatomic,assign) NSInteger cardsPerPage;
@property(nonatomic,assign) NSInteger gridColumns;
@property(nonatomic,assign) NSInteger gridRows;
@property(nonatomic,assign) BOOL showAppNames;
@property(nonatomic,assign) int displayNotifyToken;
@property(nonatomic,assign) BOOL displayObserverActive;
@property(nonatomic,strong) UILabel *titleLabel;
@property(nonatomic,strong) UIButton *closeButton;
@property(nonatomic,strong) UIButton *closeAllRunningButton;
@property(nonatomic,strong) UILabel *runningCountLabel;
@property(nonatomic,strong) UIButton *rotateForwardButton;
@property(nonatomic,strong) UIButton *rotateBackwardButton;
@property(nonatomic,strong) NSArray<NSString *> *runningBundleIDs;
@property(nonatomic,assign) BOOL runningMode;
@property(nonatomic,strong) NSArray<DFAppInfo *> *apps;
@property(nonatomic,readonly) NSArray<DFAppInfo *> *visibleApps;
@property(nonatomic,assign) NSUInteger inventoryGeneration;
@property(nonatomic,assign) int appSettingsNotifyToken;
@property(nonatomic,assign) BOOL appSettingsObserverActive;
@property(nonatomic,assign) int habitNotifyToken;
@property(nonatomic,assign) BOOL habitObserverActive;
@end
@implementation DFAppPickerVC
- (void)dealloc {
 if(self.appSettingsObserverActive)notify_cancel(self.appSettingsNotifyToken);
 if(self.habitObserverActive)notify_cancel(self.habitNotifyToken);
 if(self.displayObserverActive)notify_cancel(self.displayNotifyToken);
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Original real two-DEB proof @a05e4/a0764/a0834/a089c/a0934:
    // black underlay alpha .65, system material dark (UIBlurEffectStyle 18),
    // 20pt continuous rounded sheet, 1pt white/.18 border, shadow .65/r26/y10.
    self.view.backgroundColor=[UIColor colorWithWhite:0 alpha:.65];
    self.sheet=[UIView new];
    self.sheet.backgroundColor=UIColor.clearColor;
    self.sheet.layer.cornerRadius=20;
    self.sheet.layer.cornerCurve=kCACornerCurveContinuous;
    self.sheet.layer.borderWidth=1;
    self.sheet.layer.borderColor=[UIColor colorWithWhite:1 alpha:.18].CGColor;
    self.sheet.layer.shadowColor=UIColor.blackColor.CGColor;
    self.sheet.layer.shadowOpacity=.65;
    self.sheet.layer.shadowRadius=26;
    self.sheet.layer.shadowOffset=CGSizeMake(0,10);
    [self.view addSubview:self.sheet];
    self.sheetMaterial=[[UIVisualEffectView alloc] initWithEffect:
        [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialDark]];
    self.sheetMaterial.layer.cornerRadius=20;
    self.sheetMaterial.layer.cornerCurve=kCACornerCurveContinuous;
    self.sheetMaterial.clipsToBounds=YES;
    self.sheetMaterial.userInteractionEnabled=NO;
    [self.sheet addSubview:self.sheetMaterial];
    // Original setupCardContent @0xa2a58 uses a mode-specific 18pt SF symbol.
    // Outer four actions retain their separate approved DuoFace PNG assets.
    self.headerIcon=[UIImageView new];
    self.headerIcon.contentMode=UIViewContentModeScaleAspectFit;
    self.headerIcon.tintColor=[UIColor colorWithRed:.08 green:.52 blue:1 alpha:1];
    [self.sheet addSubview:self.headerIcon];
    self.titleLabel=[UILabel new];
    self.titleLabel.text=@"ỨNG DỤNG";
    self.titleLabel.textColor=UIColor.whiteColor;
    self.titleLabel.font=[UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    [self.sheet addSubview:self.titleLabel];
    // Original inner overlay: THREE real modes (Apps, Layout, Recent),
    // not stored launch-history masquerading as currently running apps.
    self.modes=[UIView new];
    self.modes.layer.cornerRadius=8;
    self.modes.layer.cornerCurve=kCACornerCurveContinuous;
    self.modes.clipsToBounds=YES;
    [self.sheet addSubview:self.modes];
    NSArray<NSString *> *names=@[DFLocalize(@"Ứng dụng",@"Apps"),DFLocalize(@"Bố cục",@"Layouts"),DFLocalize(@"Đang mở",@"Running")];
    NSMutableArray<UIButton *> *actions=[NSMutableArray new];
    for(NSInteger i=0;i<3;i++){
        UIButton *tab=[UIButton buttonWithType:UIButtonTypeCustom];
        tab.tag=i;
        [tab setTitle:names[(NSUInteger)i] forState:UIControlStateNormal];
        tab.titleLabel.font=[UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
        tab.titleLabel.adjustsFontSizeToFitWidth=YES;
        tab.titleLabel.minimumScaleFactor=.7;
        tab.layer.cornerRadius=6;
        [tab addTarget:self action:@selector(nativeModePressed:)
                forControlEvents:UIControlEventTouchUpInside];
        [self.modes addSubview:tab];
        [actions addObject:tab];
    }
    self.modeButtons=actions;
    self.zoomButton=[UIButton buttonWithType:UIButtonTypeCustom];
    self.zoomButton.titleLabel.font=[UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
    [self.zoomButton addTarget:self action:@selector(zoomTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.modes addSubview:self.zoomButton];
    self.currentMode=0;
    self.headerSeparator=[UIView new];
    self.headerSeparator.backgroundColor=[UIColor colorWithWhite:1 alpha:.12];
    [self.sheet addSubview:self.headerSeparator];
    // The original RECENT mode is a list of REAL running apps and provides
    // a separate CLOSE ALL button (original @0xa6c74 / @0xa6d70).
    self.closeAllRunningButton=[UIButton buttonWithType:UIButtonTypeCustom];
    [self.closeAllRunningButton setTitle:DFLocalize(@"Đóng tất cả",@"Close all") forState:UIControlStateNormal];
    self.closeAllRunningButton.titleLabel.font=[UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    self.closeAllRunningButton.tintColor=UIColor.whiteColor;
    // Original Native12 @0xa6ab4..0xa6ad8 exact verified literals:
    // red 0x30fab8=.88, green 0x30fac0=.18,
    // blue 0x311730=.22, alpha 0x30faf8=.95.
    self.closeAllRunningButton.backgroundColor=
        [UIColor colorWithRed:.88 green:.18 blue:.22 alpha:.95];
    self.closeAllRunningButton.layer.cornerRadius=14;
    self.closeAllRunningButton.hidden=YES;
    [self.closeAllRunningButton addTarget:self action:@selector(closeAllRunningTapped:)
             forControlEvents:UIControlEventTouchUpInside];
    [self.sheet addSubview:self.closeAllRunningButton];
    self.runningCountLabel=[UILabel new];
    self.runningCountLabel.font=[UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    self.runningCountLabel.textColor=[UIColor colorWithWhite:.75 alpha:1];
    self.runningCountLabel.hidden=YES;
    [self.sheet addSubview:self.runningCountLabel];
    self.rotateForwardButton=[UIButton buttonWithType:UIButtonTypeSystem];
    [self.rotateForwardButton setTitle:DFLocalize(@"Xoay →",@"Rotate →") forState:UIControlStateNormal];
    [self.rotateForwardButton addTarget:self action:@selector(rotateForwardTapped)
                         forControlEvents:UIControlEventTouchUpInside];
    [self.sheet addSubview:self.rotateForwardButton];
    self.rotateBackwardButton=[UIButton buttonWithType:UIButtonTypeSystem];
    [self.rotateBackwardButton setTitle:DFLocalize(@"← Xoay",@"← Rotate") forState:UIControlStateNormal];
    [self.rotateBackwardButton addTarget:self action:@selector(rotateBackwardTapped)
                          forControlEvents:UIControlEventTouchUpInside];
    [self.sheet addSubview:self.rotateBackwardButton];
    UICollectionViewFlowLayout *layout=[UICollectionViewFlowLayout new];
    // Native12 CBMultitaskingOverlayView has distinct pageControlChanged:
    // and card-page setup methods. Use a horizontal page, not a long vertical
    // scrolling inventory which can trap the CarPlay touchscreen.
    layout.scrollDirection=UICollectionViewScrollDirectionHorizontal;
    layout.minimumInteritemSpacing=0;
    layout.minimumLineSpacing=0;
    self.cards=[[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:layout];
    self.cards.backgroundColor=UIColor.clearColor;
    self.cards.dataSource=self;self.cards.delegate=self;
    self.cards.pagingEnabled=YES;
    self.cards.alwaysBounceHorizontal=YES;
    self.cards.showsHorizontalScrollIndicator=NO;
    self.cards.showsVerticalScrollIndicator=NO;
    // Original a40c0-a40ec accepts gridCols 4/5/6 and gridRows 2/3;
    // first-party picker still defaults 4x2, custom sizing remains pending.
    self.gridColumns=4;self.gridRows=2;self.showAppNames=YES;
    [self updatePickerDisplayConfiguration];
    self.cardsPerPage=DFPickerCapacity(self.gridColumns,self.gridRows);
    [self.cards registerClass:DFNativeAppCard.class forCellWithReuseIdentifier:@"DFNativeCard"];
    [self.sheet addSubview:self.cards];
    self.pageControl=[UIPageControl new];
    self.pageControl.pageIndicatorTintColor=[UIColor colorWithWhite:1 alpha:.25]; // original @a42fc
    self.pageControl.currentPageIndicatorTintColor=UIColor.whiteColor; // original @a4338
    [self.pageControl addTarget:self action:@selector(pageControlChanged:)
                forControlEvents:UIControlEventValueChanged];
    self.pageControl.accessibilityLabel=@"Trang ứng dụng DuoFace";
    [self.sheet addSubview:self.pageControl];
    self.categoryButton=[UIButton buttonWithType:UIButtonTypeSystem];
    self.categoryButton.titleLabel.font=[UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
    self.categoryButton.accessibilityLabel=@"Lọc nhóm ứng dụng DuoFace";
    [self.categoryButton addTarget:self action:@selector(showCategoryMenu)
           forControlEvents:UIControlEventTouchUpInside];
    [self.sheet addSubview:self.categoryButton];
    self.categoryMode=0;
    self.closeButton=[UIButton buttonWithType:UIButtonTypeCustom];
    [self.closeButton setImage:[UIImage systemImageNamed:@"xmark"]
                   forState:UIControlStateNormal];
    self.closeButton.tintColor=UIColor.whiteColor;
    self.closeButton.backgroundColor=[UIColor colorWithRed:.18 green:.18 blue:.22 alpha:.9];
    self.closeButton.accessibilityLabel=@"Đóng bảng chọn ứng dụng";
    [self.closeButton addTarget:self action:@selector(closeTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.sheet addSubview:self.closeButton];
    // Byte-verified original zero-result artwork:
    // Apps @a45ac, genuine running @a7b64. No fake app cards.
    self.emptyImage=[UIImageView new];
    self.emptyImage.contentMode=UIViewContentModeScaleAspectFit;
    [self.sheet addSubview:self.emptyImage];
    self.emptyTitle=[UILabel new];
    self.emptyTitle.textColor=UIColor.whiteColor;
    self.emptyTitle.font=[UIFont systemFontOfSize:13.5 weight:UIFontWeightSemibold];
    self.emptyTitle.textAlignment=NSTextAlignmentCenter;
    [self.sheet addSubview:self.emptyTitle];
    self.apps=@[];
    self.runningBundleIDs=@[];
    [self refreshInstalledApps];
    __weak typeof(self) weakSelf=self;
    int token=-1;
    uint32_t status=notify_register_dispatch(DFEnabledAppsChangedNotification,
      &token,dispatch_get_main_queue(),^(int ignored){
        (void)ignored;
        DFAppPickerVC *owner=weakSelf;
        if(owner && owner.isViewLoaded)[owner refreshInstalledApps];
      });
    if(status==NOTIFY_STATUS_OK){
      self.appSettingsNotifyToken=token;
      self.appSettingsObserverActive=YES;
    }
    int habitToken=-1;
    uint32_t habitStatus=notify_register_dispatch(DFAppChoicesChangedNotification,
      &habitToken,dispatch_get_main_queue(),^(int ignored){
        (void)ignored;
        DFAppPickerVC *owner=weakSelf;
        if(owner && owner.isViewLoaded)[owner refreshInstalledApps];
      });
    if(habitStatus==NOTIFY_STATUS_OK){
      self.habitNotifyToken=habitToken;
      self.habitObserverActive=YES;
    }
    int displayToken=-1;
    uint32_t displayStatus=notify_register_dispatch(DFPickerDisplayChanged,
      &displayToken,dispatch_get_main_queue(),^(int ignored){
        (void)ignored;
        DFAppPickerVC *owner=weakSelf;
        if(!owner || !owner.isViewLoaded)return;
        [owner updatePickerDisplayConfiguration];
        [owner reloadCards];
        [owner.view setNeedsLayout];
      });
    if(displayStatus==NOTIFY_STATUS_OK){
      self.displayNotifyToken=displayToken;
      self.displayObserverActive=YES;
    }
}
- (void)updatePickerDisplayConfiguration {
 NSDictionary *config=DFCurrentPickerDisplay();
 self.gridColumns=[config[@"GridColumns"] integerValue];
 self.gridRows=[config[@"GridRows"] integerValue];
 self.showAppNames=[config[@"ShowAppNames"] boolValue];
}
- (void)updateNativeModeButtons {
    for(UIButton *tab in self.modeButtons){
        BOOL selected=(tab.tag==self.currentMode);
        tab.backgroundColor=selected?
             [UIColor colorWithRed:.08 green:.52 blue:1 alpha:1]:UIColor.clearColor;
        // Original inactive inner mode is white=.68; active stays white.
        [tab setTitleColor:selected?UIColor.whiteColor:
            [UIColor colorWithWhite:.68 alpha:1] forState:UIControlStateNormal];
    }
    NSString *name=self.currentMode==0?@"square.grid.2x2.fill":
                   self.currentMode==1?@"rectangle.split.2x1.fill":@"app.badge.fill";
    self.headerIcon.image=[UIImage systemImageNamed:name];
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // Host window now uses Native12's original outer sheet geometry.
    self.sheet.frame=self.view.bounds;
    self.sheetMaterial.frame=self.sheet.bounds;
    CGFloat w=CGRectGetWidth(self.sheet.bounds),h=CGRectGetHeight(self.sheet.bounds);
    DFNative12CardHeader header=DFOriginalCardHeader(w,h);
    self.headerIcon.frame=CGRectMake(header.icon.x,header.icon.y,
                                      header.icon.width,header.icon.height);
    self.titleLabel.frame=CGRectMake(header.title.x,header.title.y,
                                      header.title.width,header.title.height);
    self.titleLabel.font=[UIFont systemFontOfSize:w<440?11.5:13 weight:UIFontWeightBold];
    self.modes.frame=CGRectMake(header.tabs.x,header.tabs.y,
                                 header.tabs.width,header.tabs.height);
    for(NSInteger i=0;i<3;i++){
        DFNative12CardRect f=header.tabButtons[i];
        self.modeButtons[(NSUInteger)i].frame=CGRectMake(f.x,f.y,f.width,f.height);
        self.modeButtons[(NSUInteger)i].titleLabel.font=
            [UIFont systemFontOfSize:w<440?10:11 weight:UIFontWeightMedium];
    }
    self.closeButton.frame=CGRectMake(header.dismiss.x,header.dismiss.y,
                                       header.dismiss.width,header.dismiss.height);
    self.closeButton.layer.cornerRadius=header.dismiss.width/2;
    self.headerSeparator.frame=CGRectMake(0,header.headerHeight,w,.5);
    [self updateNativeModeButtons];
    // Keep running count/Close All in CONTENT, never over the three tabs.
    CGFloat top=header.contentY;
    self.titleLabel.hidden=NO;
    CGRect nativeFrame=CGRectMake(header.tabs.x,header.tabs.y,header.tabs.width,header.tabs.height);
    CGFloat bodyTop=DFLayoutNative12MenuHeader(self.sheet,self.modes,self.headerIcon,
        self.titleLabel,@[self.modeButtons[0],self.zoomButton,self.modeButtons[1],self.modeButtons[2]],
        nativeFrame,self.currentMode==0?0:self.currentMode==1?2:3,self.hostExpanded);
    self.zoomButton.hidden=(bodyTop==0);
    self.headerSeparator.hidden=(bodyTop>0);
    if(bodyTop>0)top=MAX(top,bodyTop);
    self.closeAllRunningButton.hidden=!self.runningMode||!self.runningBundleIDs.count;
    self.closeAllRunningButton.frame=CGRectMake(MAX(116,w-134),top+5,
                                                  MAX(65,MIN(120,w*.28)),28);
    self.runningCountLabel.hidden=!self.runningMode;
    BOOL canRotate=self.runningMode && self.runningRotateCapacity>=3 &&
         self.runningRotateCapacity<=4 &&
         (NSInteger)self.runningBundleIDs.count==self.runningRotateCapacity;
    self.rotateForwardButton.hidden=!canRotate;
    self.rotateBackwardButton.hidden=!canRotate;
    self.rotateBackwardButton.frame=CGRectMake(8,top+27,65,26);
    self.rotateForwardButton.frame=CGRectMake(76,top+27,65,26);
    self.runningCountLabel.frame=CGRectMake(10,top+2,MAX(80,w-153),22);
    CGFloat gridTop=top+(self.runningMode?(canRotate?58:39):4);
    CGFloat available=MAX(30,h-gridTop-34);
    self.cards.frame=CGRectMake(9,gridTop,MAX(100,w-18),available);
    self.pageControl.frame=CGRectMake(106,MAX(gridTop,h-32),MAX(60,w-116),26);
    self.categoryButton.frame=CGRectMake(9,MAX(gridTop,h-32),94,25);
    self.categoryButton.hidden=self.runningMode;
    NSArray<NSString *> *categoryLabels=@[DFLocalize(@"Tất cả",@"All"),DFLocalize(@"Ưa dùng",@"Favorites"),DFLocalize(@"Người dùng",@"User"),DFLocalize(@"Hệ thống",@"System")];
    [self.categoryButton setTitle:categoryLabels[(NSUInteger)MAX(0,MIN(3,self.categoryMode))]
                       forState:UIControlStateNormal];
    // The app picker includes one Add More tile; running mode has NONE.
    // The actual App cards still represent ONLY installed, explicitly eligible IDs.
    BOOL empty=self.runningMode && self.visibleApps.count==0;
    self.cards.hidden=empty;
    self.emptyImage.hidden=!empty;
    self.emptyTitle.hidden=!empty;
    if(empty){
        self.emptyImage.image=[UIImage systemImageNamed:self.runningMode?
             @"checkmark.shield.fill":@"square.stack.3d.up.slash"];
        self.emptyImage.tintColor=self.runningMode?
             [UIColor colorWithRed:.08 green:.52 blue:1 alpha:1]:
             [UIColor colorWithWhite:1 alpha:.65];
        CGFloat iconTop=gridTop+MAX(1,(available-80)/2);
        self.emptyImage.frame=CGRectMake((w-28)/2,iconTop,28,28);
        self.emptyTitle.frame=CGRectMake(10,iconTop+34,w-20,25);
        self.emptyTitle.text=self.runningMode?
             @"Không có ứng dụng đang chạy":@"Không có ứng dụng";
    }
    NSInteger capacity=self.runningMode?4:DFPickerCapacity(self.gridColumns,self.gridRows);
    BOOL geometryChanged=self.cardsPerPage!=capacity;
    self.cardsPerPage=capacity;
    [self.cards.collectionViewLayout invalidateLayout];
    if(geometryChanged)[self reloadCards];
}
- (NSArray<DFAppInfo *> *)visibleApps {
    if(self.runningMode) {
        // These identifiers are exclusively supplied from verified LIVE
        // DFSceneHost owned views; never populate from "Recent" defaults.
        NSMutableArray<DFAppInfo *> *active=[NSMutableArray new];
        for(NSString *bid in self.runningBundleIDs){
            if(![bid isKindOfClass:NSString.class] || !bid.length)continue;
            DFAppInfo *match=nil;
            for(DFAppInfo *app in self.apps)
                if([app.bundleID isEqualToString:bid]){match=app;break;}
            if(!match){match=[DFAppInfo new];match.bundleID=bid;match.displayName=bid;}
            [active addObject:match];
        }
        return active;
    }
    if(self.categoryMode==0)return self.apps;
    NSDictionary *choices=DFCurrentAppChoices();
    NSMutableArray<DFAppInfo *> *filtered=[NSMutableArray new];
    for(DFAppInfo *app in self.apps) {
      BOOL pinned=[choices[@"PinnedBundleIDs"] containsObject:app.bundleID] ||
           [choices[@"DefaultBundleID"] isEqualToString:app.bundleID];
      BOOL system=[app.bundleID hasPrefix:@"com.apple."];
      if((self.categoryMode==1 && pinned) ||
         (self.categoryMode==2 && !system) ||
         (self.categoryMode==3 && system))
          [filtered addObject:app];
    }
    return filtered;
}
- (void)showCategoryMenu {
 if(self.runningMode || self.presentedViewController)return;
 UIAlertController *menu=[UIAlertController alertControllerWithTitle:@"Phân loại ứng dụng"
     message:@"Chỉ lọc trong những ứng dụng đã bật trên iPhone."
     preferredStyle:UIAlertControllerStyleActionSheet];
 NSArray<NSString *> *labels=@[DFLocalize(@"Tất cả",@"All"),DFLocalize(@"Ưa dùng",@"Favorites"),DFLocalize(@"Người dùng",@"User"),DFLocalize(@"Hệ thống",@"System")];
 __weak typeof(self) weakSelf=self;
 for(NSInteger i=0;i<(NSInteger)labels.count;i++) {
    NSInteger category=i;
    [menu addAction:[UIAlertAction actionWithTitle:labels[(NSUInteger)i]
          style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *a) {
             DFAppPickerVC *owner=weakSelf;
             if(!owner)return;
             owner.categoryMode=category;
             [owner reloadCards];
             [owner.view setNeedsLayout];
    }]];
 }
 [menu addAction:[UIAlertAction actionWithTitle:@"Hủy" style:UIAlertActionStyleCancel handler:nil]];
 UIPopoverPresentationController *popover=menu.popoverPresentationController;
 if(popover){popover.sourceView=self.categoryButton;popover.sourceRect=self.categoryButton.bounds;}
 [self presentViewController:menu animated:YES completion:nil];
}
- (NSInteger)pageCount {
    NSInteger count=(NSInteger)self.visibleApps.count+(self.runningMode?0:1);
    NSInteger capacity=MAX(1,self.cardsPerPage);
    return MAX(1,(count+capacity-1)/capacity);
}
- (void)reloadCards {
    // Inventory/host state changes must also refresh original zero-result
    // artwork; collection reload alone doesn't invoke viewDidLayoutSubviews.
    [self.view setNeedsLayout];
    // Keep the delegate wired to the REAL DFAppInfo bundle, not a display
    // placeholder; visual slots past the last bundle are blank padding.
    self.pageControl.numberOfPages=[self pageCount];
    self.pageControl.currentPage=0;
    self.pageControl.hidden=(self.pageControl.numberOfPages<=1);
    [self.cards reloadData];
    [self.cards setContentOffset:CGPointZero animated:NO];
}
- (void)nativeModePressed:(UIButton *)sender {
    switch(sender.tag){
        case 0:[self presentInstalledApps];break;
        case 1:[self.delegate appPickerDidRequestLayout:self];break;
        case 2:[self.delegate appPickerDidRequestRunningApps:self];break;
        default:break;
    }
}
- (void)zoomTapped {[self.delegate appPickerDidRequestZoom:self];}
- (void)presentInstalledApps {
    self.runningMode=NO;
    self.runningBundleIDs=@[];
    self.titleLabel.text=@"ỨNG DỤNG";
    self.currentMode=0;
    [self.view setNeedsLayout];
    [self reloadCards];
}
- (void)presentRunningApps:(NSArray<NSString *> *)verifiedBundleIDs {
    self.runningMode=YES;
    self.currentMode=2;
    // No synthetic entries, no duplicates: only IDs actually observed in
    // the independent scene host by the menu owner.
    NSMutableOrderedSet<NSString *> *unique=[NSMutableOrderedSet new];
    for(id bid in verifiedBundleIDs)
        if([bid isKindOfClass:NSString.class] && [bid length])
            [unique addObject:bid];
    self.runningBundleIDs=unique.array;
    self.titleLabel.text=@"ĐANG MỞ";
    self.runningCountLabel.text=self.runningBundleIDs.count?
        [NSString stringWithFormat:@"%lu ứng dụng đang chạy",(unsigned long)self.runningBundleIDs.count]:
        @"Không có ứng dụng đang chạy";
    [self.view setNeedsLayout];
    [self reloadCards];
}
- (void)pageControlChanged:(UIPageControl *)sender {
    CGFloat width=self.cards.bounds.size.width;
    if(width<=0)return;
    NSInteger page=MAX(0,MIN(sender.currentPage,[self pageCount]-1));
    [self.cards setContentOffset:CGPointMake(page*width,0) animated:YES];
}
- (void)updateCurrentPage {
    CGFloat width=self.cards.bounds.size.width;
    if(width<=0)return;
    NSInteger page=(NSInteger)lround(self.cards.contentOffset.x/width);
    self.pageControl.currentPage=MAX(0,MIN(page,[self pageCount]-1));
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if(scrollView==self.cards)[self updateCurrentPage];
}
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if(scrollView==self.cards)[self updateCurrentPage];
}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                 willDecelerate:(BOOL)decelerate {
    if(scrollView==self.cards && !decelerate)[self updateCurrentPage];
}
- (void)refreshInstalledApps {
    if(![NSThread isMainThread]){
        dispatch_async(dispatch_get_main_queue(), ^{[self refreshInstalledApps];});
        return;
    }
    if(!self.isViewLoaded)return;
    NSUInteger generation=++self.inventoryGeneration;
    __weak typeof(self) weakSelf=self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0), ^{
        NSArray<DFAppInfo *> *results=[DFAppLibrary installedUserApps];
        dispatch_async(dispatch_get_main_queue(), ^{
            DFAppPickerVC *owner=weakSelf;
            if(!owner || owner.inventoryGeneration!=generation)return;
            // Re-read config only when an actual user opens/refreshed picker.
            // No background process restarts, no scene unload on toggles.
            NSArray<NSString *> *enabled=DFConfiguredEnabledAppIDs();
            NSMutableArray<DFAppInfo *> *visible=[NSMutableArray new];
            for(DFAppInfo *app in results)
                if(DFPickerAllowsApp(app.bundleID,enabled))[visible addObject:app];
            // Default, pinned and successful prior selections ONLY affect
            // card ordering. Never assign an app to any pane or auto-start.
            NSArray<NSString *> *orderedIDs=DFRankAppIDsByHabits(
                [visible valueForKey:@"bundleID"],DFCurrentAppChoices(),
                DFReadAppHabitCountsAtPath(DFAppHabitCountsPath));
            NSMutableArray<DFAppInfo *> *ranked=[NSMutableArray new];
            for(NSString *bid in orderedIDs)
              for(DFAppInfo *candidate in visible)
                if([candidate.bundleID isEqualToString:bid]){
                  [ranked addObject:candidate];break;
                }
            owner.apps=ranked;
            [owner reloadCards];
            NSLog(@"[DuoFace] native-card-picker real-installed-apps=%lu",
                  (unsigned long)owner.apps.count);
        });
    });
}
- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    (void)collectionView;(void)section;
    return [self pageCount]*MAX(1,self.cardsPerPage);
}
- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)layout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    (void)layout;(void)indexPath;
    CGFloat width=collectionView.bounds.size.width;
    // 4/5/6 columns x 2/3 rows, configurable only for installed App mode.
    // Running-app actions retain 4 columns and one row.
    NSInteger columns=self.runningMode?4:self.gridColumns;
    NSInteger rows=self.runningMode?1:self.gridRows;
    CGFloat w=width/(CGFloat)MAX(1,columns);
    CGFloat h=collectionView.bounds.size.height/(CGFloat)MAX(1,rows);
    return CGSizeMake(w,h);
}
- (UIImage *)installedIconForBundle:(NSString *)bundleID {
    // Private iOS launcher imagery is optional; never invent another app icon.
    SEL get=NSSelectorFromString(@"_applicationIconImageForBundleIdentifier:format:scale:");
    if([UIImage respondsToSelector:get]){
        @try {
            id art=((id(*)(id,SEL,id,NSInteger,CGFloat))objc_msgSend)(
                UIImage.class,get,bundleID,2,UIScreen.mainScreen.scale);
            if([art isKindOfClass:UIImage.class])return art;
        }@catch(NSException *e){(void)e;}
    }
    return [UIImage systemImageNamed:@"app"];
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                 cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    DFNativeAppCard *card=(DFNativeAppCard *)[collectionView
                              dequeueReusableCellWithReuseIdentifier:@"DFNativeCard"
                                                      forIndexPath:indexPath];
    NSArray<DFAppInfo *> *display=[self visibleApps];
    BOOL isAddMore=!self.runningMode && (NSUInteger)indexPath.item==display.count;
    if(isAddMore){
        card.hidden=NO;
        card.runningControls=NO;
        card.showsAppName=self.showAppNames;
        card.title.text=DFLocalize(@"Thêm App",@"Add More");
        card.runningDetail.text=nil;
        card.title.textColor=UIColor.whiteColor;
        card.icon.image=[UIImage systemImageNamed:@"plus.circle.fill"];
        card.icon.tintColor=[UIColor colorWithRed:.08 green:.52 blue:1 alpha:1];
        card.icon.layer.borderWidth=0;
        card.appBadgeKind=0;
        card.appStateBadge.image=nil;
        card.closeRunning.hidden=YES;
        card.restartRunning.hidden=YES;
        card.accessibilityLabel=DFLocalize(@"Thêm ứng dụng được phép",@"Allow more apps");
        [card setNeedsLayout];
        return card;
    }
    if((NSUInteger)indexPath.item>=display.count){
        card.runningControls=NO;
        card.hidden=YES;
        card.title.text=nil;
        card.runningDetail.text=nil;
        card.icon.image=nil;
        card.appBadgeKind=0;
        card.appStateBadge.image=nil;
        card.accessibilityLabel=nil;
        return card;
    }
    card.hidden=NO;
    card.runningControls=self.runningMode;
    card.showsAppName=self.showAppNames;
    // APP tiles are clear; RUNNING tiles retain their distinct gray cards.
    card.contentView.backgroundColor=self.runningMode?
        [UIColor colorWithWhite:.19 alpha:.96]:UIColor.clearColor;
    card.closeRunning.tag=indexPath.item;
    card.restartRunning.tag=indexPath.item;
    [card.closeRunning removeTarget:self action:@selector(closeRunningTapped:)
                   forControlEvents:UIControlEventTouchUpInside];
    [card.restartRunning removeTarget:self action:@selector(restartRunningTapped:)
                   forControlEvents:UIControlEventTouchUpInside];
    [card.closeRunning addTarget:self action:@selector(closeRunningTapped:)
                 forControlEvents:UIControlEventTouchUpInside];
    [card.restartRunning addTarget:self action:@selector(restartRunningTapped:)
                 forControlEvents:UIControlEventTouchUpInside];
    [card setNeedsLayout];
    DFAppInfo *app=display[indexPath.item];
    card.title.text=app.displayName;
    NSDictionary *details=self.runningAppDetails[app.bundleID];
    NSString *status=[details[@"State"] isKindOfClass:NSString.class]?
                         details[@"State"]:@"Scene đã xác nhận";
    NSNumber *pid=[details[@"PID"] isKindOfClass:NSNumber.class]?details[@"PID"]:nil;
    card.runningDetail.text=self.runningMode?
         [NSString stringWithFormat:@"%@ · %@",status,
                 pid? [NSString stringWithFormat:@"PID %@",pid]:DFLocalize(@"PID chưa xác minh",@"PID unavailable")] : nil;
    BOOL selectedApp=!self.runningMode && self.currentSlotBundleID.length &&
        [self.currentSlotBundleID isEqualToString:app.bundleID];
    // Original per-App border/text state, independent of the badge palette.
    card.title.textColor=self.runningMode?UIColor.whiteColor:(selectedApp?
        [UIColor colorWithRed:.55 green:.80 blue:1 alpha:1]:
        [UIColor colorWithWhite:.95 alpha:1]);
    card.icon.layer.borderWidth=selectedApp?2:0;
    card.icon.layer.borderColor=[UIColor colorWithRed:.15 green:.62 blue:1 alpha:1].CGColor;
    BOOL otherSlotApp=!self.runningMode && !selectedApp &&
        [self.otherSlotBundleIDs containsObject:app.bundleID];
    card.appBadgeKind=selectedApp?1:(otherSlotApp?2:0);
    card.appGridColumns=self.runningMode?4:self.gridColumns;
    NSString *badgeSymbol=selectedApp?@"checkmark.circle.fill":
                          (otherSlotApp?@"arrow.left.arrow.right.circle.fill":nil);
    UIColor *badgeAccent=selectedApp?
        [UIColor colorWithRed:.08 green:.52 blue:1 alpha:1]:
        [UIColor colorWithRed:1 green:.62 blue:.04 alpha:1];
    UIImageSymbolConfiguration *palette=[UIImageSymbolConfiguration
        configurationWithPaletteColors:@[UIColor.whiteColor,badgeAccent]];
    UIImage *badgeImage=badgeSymbol?[UIImage systemImageNamed:badgeSymbol]:nil;
    card.appStateBadge.image=badgeImage?[badgeImage imageWithConfiguration:palette]:nil;
    card.icon.image=[self installedIconForBundle:app.bundleID];
    card.icon.tintColor=UIColor.whiteColor;
    card.accessibilityLabel=app.displayName;
    return card;
}
- (void)collectionView:(UICollectionView *)collectionView
 didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    (void)collectionView;
    if(self.runningMode)return; // Explicit Close/Restart, not accidental launch.
    NSArray<DFAppInfo *> *display=[self visibleApps];
    if(!self.runningMode && (NSUInteger)indexPath.item==display.count){
        [self presentAddMore];
        return;
    }
    if((NSUInteger)indexPath.item>=display.count)return;
    DFAppInfo *app=display[indexPath.item];
    if(!DFPickerAllowsApp(app.bundleID,DFConfiguredEnabledAppIDs())){
        [self refreshInstalledApps];
        return;
    }
    if(app.bundleID.length){
        [self.delegate appPicker:self didSelectBundleID:app.bundleID displayName:app.displayName];
    }
}
- (NSString *)verifiedRunningIDForIndex:(NSInteger)index {
    if(!self.runningMode || index<0 ||
       (NSUInteger)index>=self.runningBundleIDs.count)return nil;
    return self.runningBundleIDs[(NSUInteger)index];
}
- (void)closeRunningTapped:(UIButton *)sender {
    NSString *bid=[self verifiedRunningIDForIndex:sender.tag];
    if(!bid)return;
    [self.delegate appPicker:self closeRunningBundleID:bid];
}
- (void)restartRunningTapped:(UIButton *)sender {
    NSString *bid=[self verifiedRunningIDForIndex:sender.tag];
    if(!bid)return;
    [self.delegate appPicker:self restartRunningBundleID:bid];
}
- (void)rotateForwardTapped {
 if(!self.runningMode || self.runningRotateCapacity<3)return;
 [self.delegate appPicker:self rotateRunningClockwise:YES];
}
- (void)rotateBackwardTapped {
 if(!self.runningMode || self.runningRotateCapacity<3)return;
 [self.delegate appPicker:self rotateRunningClockwise:NO];
}
- (void)closeAllRunningTapped:(UIButton *)sender {
    (void)sender;
    if(!self.runningMode || !self.runningBundleIDs.count)return;
    [self.delegate appPickerCloseAllRunning:self];
}
- (void)presentAddMore {
 if(self.runningMode || self.presentedViewController)return;
 __weak typeof(self) weakSelf=self;
 dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0), ^{
   NSArray<NSString *> *enabled=DFConfiguredEnabledAppIDs()?:@[];
   NSMutableArray<DFAppInfo *> *disabled=[NSMutableArray new];
   for(DFAppInfo *app in [DFAppLibrary installedUserApps]){
     if(DFIsEligibleAppID(app.bundleID) && ![enabled containsObject:app.bundleID])
       [disabled addObject:app];
   }
   dispatch_async(dispatch_get_main_queue(), ^{
     DFAppPickerVC *owner=weakSelf;
     if(!owner || !owner.isViewLoaded || !owner.view.window ||
        owner.runningMode || owner.presentedViewController)return;
     DFAddMoreAppsController *manager=[[DFAddMoreAppsController alloc]
                                       initWithDisabledApps:disabled];
     manager.didEnable=^{[weakSelf refreshInstalledApps];};
     UINavigationController *navigation=[[UINavigationController alloc]
                                         initWithRootViewController:manager];
     navigation.modalPresentationStyle=UIModalPresentationFullScreen;
     [owner presentViewController:navigation animated:YES completion:nil];
   });
 });
}
- (void)closeTapped {[self.delegate appPickerDidCancel:self];}
@end

