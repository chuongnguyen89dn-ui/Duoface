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
@end
@implementation DFNativeAppCard
- (instancetype)initWithFrame:(CGRect)frame {
    if((self=[super initWithFrame:frame])){
        self.contentView.backgroundColor=[UIColor colorWithWhite:.19 alpha:.96];
        self.contentView.layer.cornerRadius=13;
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
        self.accessibilityTraits=UIAccessibilityTraitButton;
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w=self.bounds.size.width,h=self.bounds.size.height;
    CGFloat iconSide=MIN(43,MAX(24,h-29));
    self.icon.frame=CGRectMake((w-iconSide)/2,5,iconSide,iconSide);
    self.title.frame=CGRectMake(3,CGRectGetMaxY(self.icon.frame)+3,w-6,17);
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
    self.cardsPerPage=4;
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
    // One page has a single row of genuine installed-app cards. Each page
    // fills the full viewport, including the padded final row.
    self.cards.frame=CGRectMake(9,74,MAX(100,w-18),MAX(30,h-115));
    self.pageControl.frame=CGRectMake(10,MAX(82,h-38),w-20,27);
    NSInteger columns=MAX(2,MIN(5,(NSInteger)floor(self.cards.bounds.size.width/86.)));
    BOOL geometryChanged=(self.cardsPerPage!=columns);
    self.cardsPerPage=columns;
    [self.cards.collectionViewLayout invalidateLayout];
    if(geometryChanged)[self reloadCards];
}
- (NSArray<DFAppInfo *> *)visibleApps {
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
    // Make each N-card page exactly viewport-wide. A single row avoids
    // layout wrapping and preserves true UIPageControl indices.
    NSInteger columns=MAX(1,self.cardsPerPage);
    CGFloat w=width/columns;
    return CGSizeMake(w,MIN(77,collectionView.bounds.size.height-1));
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
        card.hidden=YES;
        card.title.text=nil;
        card.icon.image=nil;
        card.accessibilityLabel=nil;
        return card;
    }
    card.hidden=NO;
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
- (void)closeTapped {[self.delegate appPickerDidCancel:self];}
@end
