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
    NSMutableArray<UIView *> *_ownedCards;
    CGFloat _lastCardWidth;
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
    _scrollView.alwaysBounceVertical=YES;
    _scrollView.delegate=self;
    _scrollView.accessibilityIdentifier=@"duoface.native.picker.app-cards";
    [self.view addSubview:_scrollView];
    _ownedCards=[NSMutableArray array];
    _lastCardWidth=-1;
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    _scrollView.frame=self.view.bounds;
    BOOL recent=[self.rows.firstObject[@"type"] isEqual:@"recent"];
    if(fabs(_lastCardWidth-CGRectGetWidth(self.view.bounds))>.5 ||
       _lastCardCount!=self.rows.count || recent!=_lastRecent) {
        [self layoutNativeCards];
    }
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
    if(width<1)return;
    BOOL recent=[self.rows.firstObject[@"type"] isEqual:@"recent"];
    _lastCardWidth=width;
    _lastCardCount=self.rows.count;
    _lastRecent=recent;

    // The original overlay uses icon cards for app selection, rather than
    // QA's full-width UITableView rows. Native12 exact spacing/scale still
    // requires actual CarPlay screenshot comparison.
    const CGFloat gap=9.0;
    NSInteger columns=recent?1:MAX(1,MIN(4,(NSInteger)floor((width-gap)/88.0)));
    CGFloat cardWidth=recent?MAX(80,width-gap*2):
                      floor((width-(columns+1)*gap)/columns);
    CGFloat height=recent?52.0:84.0;
    CGFloat y=gap;
    for(NSUInteger i=0;i<self.rows.count;i++) {
        NSDictionary *item=self.rows[i];
        NSInteger column=(NSInteger)i%columns;
        NSInteger row=(NSInteger)i/columns;
        CGFloat x=gap+column*(cardWidth+gap);
        CGFloat top=gap+row*(height+gap);
        UIControl *card=[[UIControl alloc]initWithFrame:CGRectMake(x,top,cardWidth,height)];
        card.tag=i;
        card.backgroundColor=[UIColor.whiteColor colorWithAlphaComponent:.075];
        card.layer.cornerRadius=10.0;
        card.layer.borderWidth=.5;
        card.layer.borderColor=[UIColor.whiteColor colorWithAlphaComponent:.16].CGColor;
        card.accessibilityIdentifier=[NSString stringWithFormat:@"duoface.native.picker.card.%lu",(unsigned long)i];
        [card addTarget:self action:@selector(pickerCardTapped:) forControlEvents:UIControlEventTouchUpInside];

        UIImageView *iconView=[UIImageView new];
        iconView.contentMode=UIViewContentModeScaleAspectFit;
        iconView.clipsToBounds=YES;
        iconView.layer.cornerRadius=recent?7.0:9.0;
        iconView.image=[self iconForIdentifier:item[@"id"]];
        iconView.tintColor=UIColor.whiteColor;
        iconView.userInteractionEnabled=NO;
        iconView.frame=recent?CGRectMake(10,8,36,36):
                               CGRectMake((cardWidth-44)/2,6,44,44);
        [card addSubview:iconView];

        UILabel *label=[UILabel new];
        label.text=item[@"title"]?:item[@"id"]?:@"";
        label.font=[UIFont systemFontOfSize:recent?13.0:11.0 weight:UIFontWeightMedium];
        label.textColor=UIColor.whiteColor;
        label.adjustsFontSizeToFitWidth=YES;
        label.minimumScaleFactor=.8;
        label.textAlignment=recent?NSTextAlignmentLeft:NSTextAlignmentCenter;
        label.numberOfLines=recent?1:2;
        label.userInteractionEnabled=NO;
        label.frame=recent?CGRectMake(54,4,MAX(16,cardWidth-112),43):
                               CGRectMake(5,53,MAX(16,cardWidth-10),27);
        [card addSubview:label];
        if(recent && ![item[@"id"] isEqual:@"*"]) {
            BOOL live=[item[@"live"] boolValue];
            UIButton *action=[UIButton buttonWithType:UIButtonTypeSystem];
            action.tag=i;
            action.tintColor=live?DFIApprovedLiveGreen():DFIApprovedRed();
            action.frame=CGRectMake(cardWidth-48,4,44,44);
            [action setImage:[UIImage systemImageNamed:live?@"arrow.clockwise":@"xmark.circle"]
                    forState:UIControlStateNormal];
            action.accessibilityLabel=live?@"Khởi động lại ứng dụng":@"Đóng ứng dụng";
            [action addTarget:self action:@selector(recentActionTapped:)
                       forControlEvents:UIControlEventTouchUpInside];
            [card addSubview:action];
        }
        [_scrollView addSubview:card];
        [_ownedCards addObject:card];
        y=MAX(y,CGRectGetMaxY(card.frame)+gap);
    }
    _scrollView.contentSize=CGSizeMake(width,MAX(y,CGRectGetHeight(self.view.bounds)+1));
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if(self.touch)self.touch();
}
@end
