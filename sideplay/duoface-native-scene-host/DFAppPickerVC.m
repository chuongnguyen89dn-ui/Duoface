// First-party DuoFace app selection — independently implemented from the
// Native12 CBMultitaskingOverlayView CARD/RECENT behavior contract.
// Real installed bundles from DFAppLibrary; no private vendor runtime.
#import "DFAppPickerVC.h"
#import "DFAppLibrary.h"
#import <objc/message.h>
#import <math.h>

static NSString *const DFRecentKey=@"com.duoface.nativehost.recentApps.v1";
@interface DFNativeAppCard : UICollectionViewCell
@property(nonatomic,strong) UIImageView *icon;
@property(nonatomic,strong) UILabel *title;
@property(nonatomic,strong) UIButton *closeRunning;
@property(nonatomic,strong) UIButton *restartRunning;
@property(nonatomic,assign) BOOL runningControls;
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
        // Native12 setupRecentAppsCards @0xa678c creates independent
        // OVERLAY_RESTART_SINGLE and OVERLAY_CLOSE_SINGLE controls.
        self.closeRunning=[UIButton buttonWithType:UIButtonTypeSystem];
        [self.closeRunning setTitle:@"Đóng" forState:UIControlStateNormal];
        self.closeRunning.titleLabel.font=[UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
        self.closeRunning.tintColor=UIColor.whiteColor;
        // Match the proven original CLOSE ALL red instead of a guessed shade.
        self.closeRunning.backgroundColor=
            [UIColor colorWithRed:.88 green:.18 blue:.22 alpha:.95];
        self.closeRunning.layer.cornerRadius=6;
        [self.contentView addSubview:self.closeRunning];
        self.restartRunning=[UIButton buttonWithType:UIButtonTypeSystem];
        [self.restartRunning setTitle:@"Khởi động lại" forState:UIControlStateNormal];
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
    CGFloat iconSide=MIN(43,MAX(24,h-(self.runningControls?68:29)));
    self.icon.frame=CGRectMake((w-iconSide)/2,5,iconSide,iconSide);
    self.title.frame=CGRectMake(3,CGRectGetMaxY(self.icon.frame)+3,w-6,17);
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
@property(nonatomic,strong) UISegmentedControl *modes;
@property(nonatomic,strong) UICollectionView *cards;
@property(nonatomic,strong) UIPageControl *pageControl;
@property(nonatomic,assign) NSInteger cardsPerPage;
@property(nonatomic,strong) UILabel *titleLabel;
@property(nonatomic,strong) UIButton *closeButton;
@property(nonatomic,strong) UIButton *closeAllRunningButton;
@property(nonatomic,strong) UILabel *runningCountLabel;
@property(nonatomic,strong) NSArray<NSString *> *runningBundleIDs;
@property(nonatomic,assign) BOOL runningMode;
@property(nonatomic,strong) NSArray<DFAppInfo *> *apps;
@property(nonatomic,readonly) NSArray<DFAppInfo *> *visibleApps;
@property(nonatomic,assign) NSUInteger inventoryGeneration;
@end
@implementation DFAppPickerVC
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor=[UIColor colorWithWhite:0 alpha:.95];
    self.sheet=[UIView new];
    self.sheet.backgroundColor=[UIColor colorWithWhite:.10 alpha:1];
    self.sheet.layer.cornerRadius=20;
    self.sheet.layer.borderWidth=.5;
    self.sheet.layer.borderColor=[UIColor colorWithWhite:1 alpha:.25].CGColor;
    [self.view addSubview:self.sheet];
    UIImage *logo=[UIImage imageWithContentsOfFile:
       @"/var/jb/Library/Application Support/DuoFaceNativeHost/VisualAssets/duoface-logo-picker-alpha-v2.png"];
    if(logo){
        UIImageView *brand=[[UIImageView alloc]initWithImage:logo];
        brand.contentMode=UIViewContentModeScaleAspectFit;
        brand.tag=927;
        [self.sheet addSubview:brand];
    }
    self.titleLabel=[UILabel new];
    self.titleLabel.text=@"ỨNG DỤNG";
    self.titleLabel.textColor=UIColor.whiteColor;
    self.titleLabel.font=[UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    [self.sheet addSubview:self.titleLabel];
    self.modes=[[UISegmentedControl alloc]initWithItems:@[@"Ứng dụng",@"Gần đây"]];
    self.modes.selectedSegmentIndex=0;
    self.modes.selectedSegmentTintColor=[UIColor colorWithRed:227./255 green:2./255 blue:15./255 alpha:1];
    [self.modes addTarget:self action:@selector(modeChanged:) forControlEvents:UIControlEventValueChanged];
    [self.sheet addSubview:self.modes];
    // The original RECENT mode is a list of REAL running apps and provides
    // a separate CLOSE ALL button (original @0xa6c74 / @0xa6d70).
    self.closeAllRunningButton=[UIButton buttonWithType:UIButtonTypeSystem];
    [self.closeAllRunningButton setTitle:@"Đóng tất cả" forState:UIControlStateNormal];
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
    // Original Native12 setupAppPickerCards @0xa40c8 caps gridCols at 4;
    // @0xa40e8 uses a 2-row default, not a single scrolling row.
    self.cardsPerPage=8;
    [self.cards registerClass:DFNativeAppCard.class forCellWithReuseIdentifier:@"DFNativeCard"];
    [self.sheet addSubview:self.cards];
    self.pageControl=[UIPageControl new];
    self.pageControl.pageIndicatorTintColor=[UIColor colorWithWhite:.5 alpha:1];
    self.pageControl.currentPageIndicatorTintColor=[UIColor colorWithRed:227./255
                                                        green:2./255 blue:15./255 alpha:1];
    [self.pageControl addTarget:self action:@selector(pageControlChanged:)
                forControlEvents:UIControlEventValueChanged];
    self.pageControl.accessibilityLabel=@"Trang ứng dụng DuoFace";
    [self.sheet addSubview:self.pageControl];
    self.closeButton=[UIButton buttonWithType:UIButtonTypeSystem];
    [self.closeButton setTitle:@"×" forState:UIControlStateNormal];
    self.closeButton.tintColor=UIColor.whiteColor;
    self.closeButton.titleLabel.font=[UIFont systemFontOfSize:27];
    self.closeButton.accessibilityLabel=@"Đóng bảng chọn ứng dụng";
    [self.closeButton addTarget:self action:@selector(closeTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.sheet addSubview:self.closeButton];
    self.apps=@[];
    self.runningBundleIDs=@[];
    [self refreshInstalledApps];
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGRect bounds=self.view.bounds;
    self.sheet.frame=CGRectInset(bounds,2,2);
    CGFloat w=CGRectGetWidth(self.sheet.bounds),h=CGRectGetHeight(self.sheet.bounds);
    UIView *logo=[self.sheet viewWithTag:927];
    logo.frame=CGRectMake(10,7,MIN(w*.28,112),27);
    self.titleLabel.frame=CGRectMake(CGRectGetMaxX(logo.frame)+5,6,
                                    MAX(70,w-CGRectGetMaxX(logo.frame)-46),27);
    self.closeButton.frame=CGRectMake(w-37,3,33,34);
    self.modes.frame=CGRectMake(9,39,w-18,30);
    self.modes.hidden=self.runningMode;
    self.closeAllRunningButton.hidden=!self.runningMode || !self.runningBundleIDs.count;
    self.closeAllRunningButton.frame=CGRectMake(MAX(116,w-134),40,MAX(65,MIN(120,w*.28)),28);
    self.runningCountLabel.hidden=!self.runningMode;
    self.runningCountLabel.frame=CGRectMake(10,39,MAX(80,w-153),30);
    // One page has a single row of genuine installed-app cards. Each page
    // fills the full viewport, including the padded final row.
    self.cards.frame=CGRectMake(9,74,MAX(100,w-18),MAX(30,h-115));
    self.pageControl.frame=CGRectMake(10,MAX(82,h-38),w-20,27);
    // App original default 4x2; running mode reuses original
    // CBMultitaskingOverlayView card/page UI with full-height action cells.
    NSInteger columns=self.runningMode?4:4*2;
    BOOL geometryChanged=(self.cardsPerPage!=columns);
    self.cardsPerPage=columns;
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
    if(self.modes.selectedSegmentIndex!=1)return self.apps;
    NSArray *recent=[[NSUserDefaults standardUserDefaults] objectForKey:DFRecentKey];
    if(![recent isKindOfClass:NSArray.class])return @[];
    NSMutableArray<DFAppInfo *> *output=[NSMutableArray new];
    for(id bundle in recent){
        if(![bundle isKindOfClass:NSString.class])continue;
        for(DFAppInfo *app in self.apps){
            if([app.bundleID isEqualToString:bundle]){[output addObject:app];break;}
        }
    }
    return output;
}
- (NSInteger)pageCount {
    NSInteger count=(NSInteger)self.visibleApps.count;
    NSInteger capacity=MAX(1,self.cardsPerPage);
    return MAX(1,(count+capacity-1)/capacity);
}
- (void)reloadCards {
    // Keep the delegate wired to the REAL DFAppInfo bundle, not a display
    // placeholder; visual slots past the last bundle are blank padding.
    self.pageControl.numberOfPages=[self pageCount];
    self.pageControl.currentPage=0;
    self.pageControl.hidden=(self.pageControl.numberOfPages<=1);
    [self.cards reloadData];
    [self.cards setContentOffset:CGPointZero animated:NO];
}
- (void)modeChanged:(UISegmentedControl *)sender {
    (void)sender;[self reloadCards];
}
- (void)presentInstalledApps {
    self.runningMode=NO;
    self.runningBundleIDs=@[];
    self.titleLabel.text=@"ỨNG DỤNG";
    self.modes.selectedSegmentIndex=0;
    [self.view setNeedsLayout];
    [self reloadCards];
}
- (void)presentRunningApps:(NSArray<NSString *> *)verifiedBundleIDs {
    self.runningMode=YES;
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
            owner.apps=results?:@[];
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
    // Native12 shows 4 columns × 2 rows; the default card grid is
    // governed by original CBDashboardSettings.gridCols/gridRows selectors.
    // Do not change user live-app hosting or per-pane SceneWindow ratios.
    CGFloat w=width/4.0;
    CGFloat h=collectionView.bounds.size.height/(self.runningMode?1.0:2.0);
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
    if((NSUInteger)indexPath.item>=display.count){
        card.runningControls=NO;
        card.hidden=YES;
        card.title.text=nil;
        card.icon.image=nil;
        card.accessibilityLabel=nil;
        return card;
    }
    card.hidden=NO;
    card.runningControls=self.runningMode;
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
    if((NSUInteger)indexPath.item>=display.count)return;
    DFAppInfo *app=display[indexPath.item];
    if(app.bundleID.length){
        NSArray *prior=[[NSUserDefaults standardUserDefaults] objectForKey:DFRecentKey];
        NSMutableArray *recent=[NSMutableArray arrayWithObject:app.bundleID];
        for(id other in [prior isKindOfClass:NSArray.class]?prior:@[]){
            if([other isKindOfClass:NSString.class] && ![other isEqual:app.bundleID]){
                [recent addObject:other];
                if(recent.count>=12)break;
            }
        }
        [[NSUserDefaults standardUserDefaults] setObject:recent forKey:DFRecentKey];
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
- (void)closeAllRunningTapped:(UIButton *)sender {
    (void)sender;
    if(!self.runningMode || !self.runningBundleIDs.count)return;
    [self.delegate appPickerCloseAllRunning:self];
}
- (void)closeTapped {[self.delegate appPickerDidCancel:self];}
@end
