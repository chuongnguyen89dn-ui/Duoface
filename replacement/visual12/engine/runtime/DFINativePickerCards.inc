// Independently authored CarPlay app-card picker, modeled on the original
// CBMultitaskingOverlayView.setupAppPickerCardsInCardW:cardH:contentY: contract.
// Does not load the original binary, UI classes or license/watchdog.
#pragma once

@interface DFINativePickerCardsController : UIViewController <UIScrollViewDelegate>
@property(nonatomic,copy) NSArray<NSDictionary *> *rows;
@property(nonatomic,copy) void (^pick)(NSDictionary *);
@property(nonatomic,copy) void (^touch)(void);
@property(nonatomic,copy) void (^act)(NSDictionary *);
@property(nonatomic,strong,readonly) UIScrollView *scrollView;
@end

@implementation DFINativePickerCardsController {
    UIScrollView *_scrollView;
    UIPageControl *_pageControl;
    NSMutableArray<UIView *> *_ownedCards;
    CGFloat _lastCardWidth;
    CGFloat _lastCardHeight;
    NSInteger _lastGridCols;
    NSInteger _lastGridRows;
    BOOL _lastHiddenLabels;
    NSUInteger _lastCardCount;
    BOOL _lastRecent;
}
- (UIScrollView *)scrollView {return _scrollView;}
- (void)setRows:(NSArray<NSDictionary *> *)rows {
    _rows=[rows copy]?:@[];
    _lastCardWidth=-1;
    if(self.isViewLoaded)[self layoutNativeCards];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor=UIColor.clearColor;
    _scrollView=[UIScrollView new];
    _scrollView.backgroundColor=UIColor.clearColor;
    _scrollView.showsVerticalScrollIndicator=YES;
    _scrollView.alwaysBounceVertical=NO;
    _scrollView.delegate=self;
    _scrollView.accessibilityIdentifier=@"duoface.native.picker.app-cards";
    [self.view addSubview:_scrollView];
    _pageControl=[UIPageControl new];
    _pageControl.backgroundColor=UIColor.clearColor;
    _pageControl.accessibilityIdentifier=@"duoface.native.picker.pages";
    _pageControl.hidesForSinglePage=YES;
    _pageControl.pageIndicatorTintColor=[UIColor.whiteColor colorWithAlphaComponent:.28];
    _pageControl.currentPageIndicatorTintColor=UIColor.whiteColor;
    [_pageControl addTarget:self action:@selector(pageControlChanged:)
           forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_pageControl];
    _ownedCards=[NSMutableArray array];
    _lastCardWidth=-1;_lastCardHeight=-1;
}
- (NSInteger)nativeGridCols {
    // ARM64 original104 CBMultitaskingOverlayView clamps gridCols to [4..6],
    // otherwise uses 4. Values are owned by DuoFace prefs, not vendor settings.
    NSInteger value=[DFIPref(@"gridCols") integerValue];
    return value>=4 && value<=6?value:4;
}
- (NSInteger)nativeGridRows {
    // Original104 accepts 2 or 3 grid rows and defaults to 2.
    NSInteger value=[DFIPref(@"gridRows") integerValue];
    return value==2 || value==3?value:2;
}
- (BOOL)nativeHideIconLabels {return [DFIPref(@"hideIconLabels") boolValue];}
- (BOOL)isRecentCategory {
    for(NSDictionary *candidate in self.rows)
        if([candidate[@"type"] isEqual:@"recent"])return YES;
    return NO;
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat width=CGRectGetWidth(self.view.bounds),height=CGRectGetHeight(self.view.bounds);
    BOOL recent=[self isRecentCategory];
    NSInteger cols=[self nativeGridCols],rows=[self nativeGridRows];
    BOOL hide=[self nativeHideIconLabels];
    CGFloat pageHeight=recent?0:MIN(24.0,MAX(16.0,height*.12));
    _scrollView.frame=CGRectMake(0,0,width,MAX(0,height-pageHeight));
    _pageControl.frame=CGRectMake(0,MAX(0,height-pageHeight),width,pageHeight);
    _pageControl.hidden=recent;
    if(fabs(_lastCardWidth-width)>.5 || fabs(_lastCardHeight-height)>.5 ||
       _lastCardCount!=self.rows.count || recent!=_lastRecent ||
       _lastGridCols!=cols || _lastGridRows!=rows || _lastHiddenLabels!=hide) {
        [self layoutNativeCards];
    }
}
- (void)pageControlChanged:(UIPageControl *)control {
    CGFloat width=CGRectGetWidth(_scrollView.bounds);
    if(width>0)[_scrollView setContentOffset:CGPointMake(control.currentPage*width,0)
                                  animated:YES];
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if(scrollView!=_scrollView || _pageControl.hidden)return;
    CGFloat width=CGRectGetWidth(scrollView.bounds);
    if(width>0)_pageControl.currentPage=MIN(_pageControl.numberOfPages-1,
               MAX(0,(NSInteger)lround(scrollView.contentOffset.x/width)));
}
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self scrollViewDidEndDecelerating:scrollView];
}
- (UIImage *)iconForIdentifier:(NSString *)identifier {
    UIImage *icon=nil;
    if([identifier isKindOfClass:NSString.class] && identifier.length &&
       ![identifier isEqualToString:@"*"]) {
        SEL selector=NSSelectorFromString(@"_applicationIconImageForBundleIdentifier:format:scale:");
        if([UIImage respondsToSelector:selector]){
            @try {
                icon=((UIImage *(*)(id,SEL,id,NSInteger,CGFloat))objc_msgSend)(
                    UIImage.class,selector,identifier,0,UIScreen.mainScreen.scale);
            } @catch(NSException *exception) {
                DFILog([NSString stringWithFormat:@"native picker icon %@ %@",identifier,exception.reason]);
            }
        }
    }
    return icon?:[UIImage systemImageNamed:@"square.grid.2x2"];
}
- (void)pickerCardTapped:(UIControl *)sender {
    NSInteger index=sender.tag;
    if(index<0 || index>=self.rows.count)return;
    if(self.touch)self.touch();
    if(self.pick)self.pick(self.rows[index]);
}
- (void)recentActionTapped:(UIButton *)sender {
    NSInteger index=sender.tag;
    if(index<0 || index>=self.rows.count)return;
    if(self.touch)self.touch();
    if(self.act)self.act(self.rows[index]);
}
- (void)layoutNativeCards {
    if(!self.isViewLoaded || !_scrollView)return;
    for(UIView *card in _ownedCards)[card removeFromSuperview];
    [_ownedCards removeAllObjects];
    CGFloat width=CGRectGetWidth(self.view.bounds);
    CGFloat height=CGRectGetHeight(self.view.bounds);
    if(width<1 || height<1)return;
    BOOL recent=[self isRecentCategory];
    NSInteger cols=[self nativeGridCols],rows=[self nativeGridRows];
    BOOL hiddenLabels=[self nativeHideIconLabels];
    _lastCardWidth=width;_lastCardHeight=height;_lastCardCount=self.rows.count;
    _lastRecent=recent;_lastGridCols=cols;_lastGridRows=rows;
    _lastHiddenLabels=hiddenLabels;

    // The original1.0.4 setupAppPickerCardsInCardW:cardH:contentY:
    // uses CBOverlayScrollView with horizontal paging, UIPageControl,
    // gridCols, gridRows, hideIconLabels. Our equivalent stays source-owned.
    const CGFloat gap=8.0;
    CGFloat scrollHeight=CGRectGetHeight(_scrollView.bounds);
    NSInteger count=(NSInteger)self.rows.count;
    NSInteger perPage=MAX(1,cols*rows);
    NSInteger pageCount=recent?1:MAX(1,(count+perPage-1)/perPage);
    _scrollView.pagingEnabled=!recent;
    _scrollView.alwaysBounceHorizontal=!recent && pageCount>1;
    _scrollView.alwaysBounceVertical=recent;
    _scrollView.showsHorizontalScrollIndicator=NO;
    _scrollView.showsVerticalScrollIndicator=recent;
    _pageControl.numberOfPages=recent?0:pageCount;
    _pageControl.currentPage=0;
    _pageControl.hidden=recent || pageCount<2;
    _scrollView.contentOffset=CGPointZero;

    CGFloat recentWidth=MAX(80.0,width-gap*2);
    CGFloat recentHeight=52.0;
    CGFloat cardWidth=MAX(18.0,floor((width-(cols+1)*gap)/cols));
    CGFloat cardHeight=MAX(30.0,floor((scrollHeight-(rows+1)*gap)/rows));
    CGFloat contentBottom=gap;
    for(NSInteger index=0;index<count;index++) {
        NSDictionary *item=self.rows[(NSUInteger)index];
        NSInteger page=recent?0:index/perPage;
        NSInteger within=recent?index:index%perPage;
        NSInteger column=recent?0:within%cols;
        NSInteger row=recent?index:within/cols;
        CGFloat x=recent?gap:page*width+gap+column*(cardWidth+gap);
        CGFloat y=gap+row*((recent?recentHeight:cardHeight)+gap);
        CGFloat cw=recent?recentWidth:cardWidth,ch=recent?recentHeight:cardHeight;
        UIControl *card=[[UIControl alloc]initWithFrame:CGRectMake(x,y,cw,ch)];
        card.tag=index;
        card.backgroundColor=[UIColor.whiteColor colorWithAlphaComponent:.075];
        card.layer.cornerRadius=10.0;
        card.layer.borderWidth=.5;
        card.layer.borderColor=[UIColor.whiteColor colorWithAlphaComponent:.16].CGColor;
        card.accessibilityIdentifier=[NSString stringWithFormat:
             @"duoface.native.picker.card.%ld",(long)index];
        [card addTarget:self action:@selector(pickerCardTapped:)
                forControlEvents:UIControlEventTouchUpInside];

        CGFloat iconSize=recent?36.0:MIN(44.0,MAX(22.0,cw-12.0));
        UIImageView *iconView=[UIImageView new];
        iconView.contentMode=UIViewContentModeScaleAspectFit;
        iconView.clipsToBounds=YES;
        iconView.layer.cornerRadius=recent?7.0:9.0;
        iconView.image=[self iconForIdentifier:item[@"id"]];
        iconView.tintColor=UIColor.whiteColor;
        iconView.userInteractionEnabled=NO;
        iconView.frame=recent?CGRectMake(10,8,iconSize,iconSize):
            CGRectMake((cw-iconSize)/2,hiddenLabels?(ch-iconSize)/2:MAX(4,(ch-iconSize-26)/2),
                       iconSize,iconSize);
        [card addSubview:iconView];

        if(!hiddenLabels || recent) {
            UILabel *label=[UILabel new];
            label.text=item[@"title"]?:item[@"id"]?:@"";
            label.font=[UIFont systemFontOfSize:recent?13.0:11.0
                                         weight:UIFontWeightMedium];
            label.textColor=UIColor.whiteColor;
            label.adjustsFontSizeToFitWidth=YES;
            label.minimumScaleFactor=.8;
            label.textAlignment=recent?NSTextAlignmentLeft:NSTextAlignmentCenter;
            label.numberOfLines=recent?1:2;
            label.userInteractionEnabled=NO;
            label.frame=recent?CGRectMake(54,4,MAX(16,cw-112),43):
                CGRectMake(4,CGRectGetMaxY(iconView.frame)+1,
                           MAX(16,cw-8),MAX(13,ch-CGRectGetMaxY(iconView.frame)-3));
            [card addSubview:label];
        }
        if(recent && ![item[@"id"] isEqual:@"*"]) {
            BOOL live=[item[@"live"] boolValue];
            UIButton *action=[UIButton buttonWithType:UIButtonTypeSystem];
            action.tag=index;
            action.tintColor=live?DFIApprovedLiveGreen():DFIApprovedRed();
            action.frame=CGRectMake(cw-48,4,44,44);
            [action setImage:[UIImage systemImageNamed:live?@"arrow.clockwise":@"xmark.circle"]
                    forState:UIControlStateNormal];
            action.accessibilityLabel=live?@"Khởi động lại ứng dụng":@"Đóng ứng dụng";
            [action addTarget:self action:@selector(recentActionTapped:)
                    forControlEvents:UIControlEventTouchUpInside];
            [card addSubview:action];
        }
        [_scrollView addSubview:card];
        [_ownedCards addObject:card];
        contentBottom=MAX(contentBottom,CGRectGetMaxY(card.frame)+gap);
    }
    _scrollView.contentSize=recent?CGSizeMake(width,MAX(contentBottom,scrollHeight+1)):
                           CGSizeMake(pageCount*width,scrollHeight);
    DFILog([NSString stringWithFormat:
        @"Native picker cards category=%@ count=%ld grid=%ldx%ld pages=%ld labelsHidden=%d frame=%@",
        recent?@"recent":@"apps",(long)count,(long)cols,(long)rows,
        (long)pageCount,(int)hiddenLabels,NSStringFromCGRect(self.view.bounds)]);
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if(self.touch)self.touch();
}
@end
