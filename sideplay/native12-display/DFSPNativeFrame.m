#import "DFSPNativeFrame.h"
#import "DFSPNativeSlotPill.h"
#import <math.h>

/* Native12 HUD8 visual measurements from the established handoff:
   pill 76x22 radius 11; divider logo 28/30px; sheet blur radius 20;
   approved picker header 120x30; menu row 30; 0.30s logo hold;
   live ratio clamped to 1/3 ... 2/3, snaps at 4%. */
static CGFloat const DFSPGripSize = 30.0;
static CGFloat const DFSPSheetRadius = 20.0;
static CGFloat const DFSPMenuHeight = 30.0;
static CGFloat const DFSPMinRatio = 1.0/3.0;
static CGFloat const DFSPMaxRatio = 2.0/3.0;
static CGFloat const DFSPSnapDelta = 0.04;

static UIColor *DFSPApprovedRed(void) {
    return [UIColor colorWithRed:227.0/255.0 green:2.0/255.0
                           blue:15.0/255.0 alpha:1.0];
}
static UIImage *DFSPApprovedArtwork(NSString *name) {
    // Only load assets installed by this independent QA package.
    if (!name.length || [name containsString:@".."] ||
        [name containsString:@"/"]) return nil;
    NSString *root=@"/var/jb/Library/Application Support/DuoFaceSidePlayDisplayQA/";
    return [UIImage imageWithContentsOfFile:[root stringByAppendingString:name]];
}
static UIImage *DFSPLogo(void) {
    return DFSPApprovedArtwork(@"duoface-logo-picker-alpha-v2.png");
}
static double DFSPClampRatio(double r, BOOL snap) {
    if (!isfinite(r)) r=0.5;
    r=fmax(DFSPMinRatio,fmin(DFSPMaxRatio,r));
    if (snap) {
        for (NSNumber *stop in @[@(DFSPMinRatio),@(0.5),@(DFSPMaxRatio)]) {
            if (fabs(r-stop.doubleValue)<DFSPSnapDelta) return stop.doubleValue;
        }
    }
    return r;
}
@interface DFSPNativeFrame () <UIGestureRecognizerDelegate>
@property(nonatomic,strong) NSArray<DFSPNativeSlotPill *> *pills;
@property(nonatomic,strong) UIView *dividerTrack;
@property(nonatomic,strong) UIButton *dividerLogo;
@property(nonatomic,strong) UIView *dividerLine;
@property(nonatomic,strong) UIPanGestureRecognizer *dividerPan;
@property(nonatomic,strong) UILongPressGestureRecognizer *logoHold;
@property(nonatomic,strong) UIView *shade;
@property(nonatomic,strong) UIVisualEffectView *sheet;
@property(nonatomic,strong) UIImageView *approvedLogo;
@property(nonatomic,strong) NSArray<UIButton *> *menuButtons;
@property(nonatomic,strong) UIButton *dismissButton;
@property(nonatomic,readwrite) BOOL pickerVisible;
@property(nonatomic) CGRect firstRect;
@property(nonatomic) CGRect secondRect;
@property(nonatomic) double currentRatio;
@property(nonatomic) BOOL verticalDivider;
@property(nonatomic) CGFloat logoRelativePosition;
@property(nonatomic) NSInteger selectedSlot;
@property(nonatomic) BOOL inFullscreen;
@property(nonatomic) BOOL hasFirst;
@property(nonatomic) BOOL hasSecond;
@end
@implementation DFSPNativeFrame
- (instancetype)initWithFrame:(CGRect)frame {
    if (!(self=[super initWithFrame:frame])) return nil;
    self.backgroundColor=UIColor.clearColor;
    self.opaque=NO;
    self.clipsToBounds=NO;
    self.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.accessibilityIdentifier=@"duoface.native12.sideplay.frame";
    self.currentRatio=0.5;
    _focusedSlot=-1;
    self.logoRelativePosition=0.5;
    NSMutableArray *pills=[NSMutableArray array];
    for (NSInteger i=0;i<2;i++) {
        // TWO independent actions per slot, with verified six Native12 modes.
        DFSPNativeSlotPill *pill=[[DFSPNativeSlotPill alloc]
             initWithSlot:i target:self
             menuAction:@selector(pillTapped:)
             expandAction:@selector(expandTapped:)
             restoreAction:@selector(restoreTapped:)];
        [self addSubview:pill]; [pills addObject:pill];

    }
    self.pills=pills; // no second oversized add-app control beside native pill


    UIView *track=[UIView new];
    track.backgroundColor=UIColor.clearColor;
    track.accessibilityIdentifier=@"duoface.native.divider.track";
    [self addSubview:track];self.dividerTrack=track;
    UIView *line=[UIView new];
    line.backgroundColor=[UIColor colorWithWhite:1 alpha:0.18];
    line.userInteractionEnabled=NO;
    [track addSubview:line];self.dividerLine=line;

    UIPanGestureRecognizer *pan=[[UIPanGestureRecognizer alloc]initWithTarget:self
                                                                      action:@selector(dragDivider:)];
    pan.maximumNumberOfTouches=1;
    pan.cancelsTouchesInView=NO;
    pan.delegate=self;
    [track addGestureRecognizer:pan];self.dividerPan=pan;

    UIButton *logo=[UIButton buttonWithType:UIButtonTypeCustom];
    logo.backgroundColor=[UIColor colorWithWhite:0.17 alpha:0.96];
    logo.tintColor=UIColor.whiteColor;
    logo.layer.cornerRadius=15.0;
    logo.accessibilityIdentifier=@"duoface.native.divider.logo";
    logo.accessibilityLabel=@"Thanh chia DuoFace";
    // Match the approved Native12 divider artwork, not the temporary QA arrow.
    UIImage *swapArt=DFSPApprovedArtwork(@"duoface-swap.png");
    [logo setImage:swapArt ?: [UIImage systemImageNamed:@"arrow.left.arrow.right"]
         forState:UIControlStateNormal];
    logo.imageView.contentMode=UIViewContentModeScaleAspectFit;
    [logo addTarget:self action:@selector(swapTapped:)
       forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:logo];self.dividerLogo=logo;

    UILongPressGestureRecognizer *hold=[[UILongPressGestureRecognizer alloc]
                                        initWithTarget:self action:@selector(moveLogo:)];
    hold.minimumPressDuration=0.30;
    hold.allowableMovement=14.0;
    hold.cancelsTouchesInView=YES;
    [logo addGestureRecognizer:hold];self.logoHold=hold;
    UIPanGestureRecognizer *logoPan=[[UIPanGestureRecognizer alloc]
                                    initWithTarget:self action:@selector(dragDivider:)];
    logoPan.maximumNumberOfTouches=1;
    [logoPan requireGestureRecognizerToFail:hold];
    [logo addGestureRecognizer:logoPan];

    // Header exists only IN the approved 20pt radius app picker sheet.
    UIControl *shade=[[UIControl alloc]initWithFrame:self.bounds];
    shade.backgroundColor=[UIColor colorWithWhite:0 alpha:0.56];
    shade.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [shade addTarget:self action:@selector(dismissPicker)
    forControlEvents:UIControlEventTouchUpInside];
    shade.hidden=YES;
    [self addSubview:shade];self.shade=shade;

    UIVisualEffectView *sheet=[[UIVisualEffectView alloc]initWithEffect:
        [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialDark]];
    sheet.layer.cornerRadius=DFSPSheetRadius;
    sheet.layer.masksToBounds=YES;
    sheet.layer.borderWidth=0;
    sheet.accessibilityIdentifier=@"duoface.native.picker.card";
    [shade addSubview:sheet];self.sheet=sheet;

    UIImageView *approved=[[UIImageView alloc]initWithImage:DFSPLogo()];
    approved.contentMode=UIViewContentModeScaleAspectFit;
    approved.accessibilityIdentifier=@"duoface.native.picker.approved-logo";
    if (!approved.image) {
        UILabel *fallback=[UILabel new];
        fallback.text=@"DUOFACE";fallback.font=[UIFont boldSystemFontOfSize:18];
        fallback.textColor=DFSPApprovedRed();
        fallback.frame=CGRectMake(0,0,120,30);
        [approved addSubview:fallback];
    }
    [sheet.contentView addSubview:approved];self.approvedLogo=approved;

    NSArray *names=@[@"App",@"Zoom",@"Style",@"Close"];
    NSArray *symbols=@[@"square.grid.2x2",@"arrow.up.left.and.arrow.down.right",
                        @"rectangle.3.group",@"xmark.circle"];
    NSMutableArray<UIButton *> *menu=[NSMutableArray array];
    for(NSInteger i=0;i<4;i++) {
        UIButton *tab=[UIButton buttonWithType:UIButtonTypeCustom];
        tab.tag=i;tab.accessibilityLabel=names[i];
        tab.accessibilityIdentifier=[NSString stringWithFormat:@"duoface.native.picker.menu.%@",names[i]];
        tab.backgroundColor=UIColor.clearColor;
        [tab addTarget:self action:@selector(menuTapped:)
        forControlEvents:UIControlEventTouchUpInside];
        UIImageView *icon=[UIImageView new];
        icon.tag=8162;icon.contentMode=UIViewContentModeScaleAspectFit;
        icon.image=[[UIImage systemImageNamed:symbols[i]
                         withConfiguration:[UIImageSymbolConfiguration
                           configurationWithPointSize:16]]
                         imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        icon.tintColor=UIColor.whiteColor;
        icon.userInteractionEnabled=NO;
        [tab addSubview:icon];
        UILabel *caption=[UILabel new];
        caption.tag=8163;caption.text=names[i];
        caption.font=[UIFont systemFontOfSize:10];
        caption.textColor=UIColor.whiteColor;
        caption.textAlignment=NSTextAlignmentCenter;
        caption.userInteractionEnabled=NO;
        [tab addSubview:caption];
        [sheet.contentView addSubview:tab];[menu addObject:tab];
    }
    self.menuButtons=menu;
    UIButton *dismiss=[UIButton buttonWithType:UIButtonTypeSystem];
    [dismiss setTitle:@"×" forState:UIControlStateNormal];
    dismiss.titleLabel.font=[UIFont systemFontOfSize:24];
    dismiss.tintColor=UIColor.whiteColor;
    dismiss.accessibilityLabel=@"Đóng bảng chọn";
    [dismiss addTarget:self action:@selector(dismissPicker)
      forControlEvents:UIControlEventTouchUpInside];
    [sheet.contentView addSubview:dismiss];self.dismissButton=dismiss;
    return self;
}
- (void)updateFirst:(CGRect)first second:(CGRect)second
        hasFirstApp:(BOOL)firstApp hasSecondApp:(BOOL)secondApp
            ratio:(double)ratio fullscreen:(BOOL)fullscreen {
    self.firstRect=first;self.secondRect=second;
    self.hasFirst=firstApp;self.hasSecond=secondApp;
    self.inFullscreen=fullscreen;
    self.currentRatio=DFSPClampRatio(ratio,NO);
    // Detect Native12 divider axis from real SidePlay panes, not preset labels.
    if (!CGRectIsEmpty(first)&&!CGRectIsEmpty(second)) {
        self.verticalDivider=fabs(CGRectGetMidX(second)-CGRectGetMidX(first)) >
                             fabs(CGRectGetMidY(second)-CGRectGetMidY(first));
    }
    [self setNeedsLayout];
}
- (void)layoutSubviews {
    [super layoutSubviews];
    NSArray<NSValue *> *rects=@[[NSValue valueWithCGRect:self.firstRect],
                                [NSValue valueWithCGRect:self.secondRect]];
    for (NSInteger i=0;i<2;i++) {
        CGRect rect=rects[i].CGRectValue;
        BOOL valid=CGRectGetWidth(rect)>60 && CGRectGetHeight(rect)>60;
        DFSPNativeSlotPill *pill=self.pills[i];
        BOOL focused=(self.focusedSlot==i);
        BOOL visible=valid && (self.focusedSlot<0 || focused);
        BOOL compact=(CGRectGetWidth(rect)<320.0 || CGRectGetHeight(rect)<220.0);
        CGRect peer=rects[(NSUInteger)(1-i)].CGRectValue;
        BOOL allowsExpand=CGRectGetWidth(peer)>60 && CGRectGetHeight(peer)>60;
        // Native12 single-pane mode: only App (44x22 / compact 38x19).
        // Focused mode still displays Restore (80x22 / compact 72x19).
        [pill configureFocused:focused compact:compact allowsExpand:allowsExpand];
        CGSize pillSize=[pill nativeSize];
        pill.hidden=!visible || CGRectGetWidth(rect)<pillSize.width ||
                     CGRectGetHeight(rect)<pillSize.height;
        // Approved Native12 HUD8 presentation: TOP-CENTER of EACH pane.
        // The DEB audit proves pill size/modes, not global UI coordinates.
        // Keep the top offset isolated: +3pt comes from the older QA layout
        // reference and still requires a real CarPlay comparison.
        // QA5's former midY centering placed pills in the middle of app content.
        CGFloat const topInset=3.0;
        if (visible) pill.frame=CGRectMake(CGRectGetMidX(rect)-pillSize.width/2,
                                          CGRectGetMinY(rect)+topInset,
                                          pillSize.width,pillSize.height);
    }
    CGRect a=self.firstRect, b=self.secondRect;
    BOOL valid=CGRectGetWidth(a)>100 && CGRectGetHeight(a)>100 &&
               CGRectGetWidth(b)>100 && CGRectGetHeight(b)>100;
    self.dividerTrack.hidden=!valid || self.focusedSlot>=0;
    self.dividerLogo.hidden=!valid || self.focusedSlot>=0;
    if (valid) {
        CGRect tr;
        if (self.verticalDivider) {
            // Pane index is logical slot order, NOT necessarily left-to-right.
            // Compute the real shared edge of the two hosted pane rectangles.
            BOOL firstLeft=CGRectGetMidX(a)<=CGRectGetMidX(b);
            CGFloat x=firstLeft?
                 (CGRectGetMaxX(a)+CGRectGetMinX(b))*0.5:
                 (CGRectGetMaxX(b)+CGRectGetMinX(a))*0.5;
            tr=CGRectMake(x-16,MAX(CGRectGetMinY(a),CGRectGetMinY(b)),
                          32,MIN(CGRectGetMaxY(a),CGRectGetMaxY(b))-
                                  MAX(CGRectGetMinY(a),CGRectGetMinY(b)));
            self.dividerLine.frame=CGRectMake(15.5,0,1,MAX(0,tr.size.height));
        } else {
            BOOL firstTop=CGRectGetMidY(a)<=CGRectGetMidY(b);
            CGFloat y=firstTop?
                 (CGRectGetMaxY(a)+CGRectGetMinY(b))*0.5:
                 (CGRectGetMaxY(b)+CGRectGetMinY(a))*0.5;
            tr=CGRectMake(MAX(CGRectGetMinX(a),CGRectGetMinX(b)),y-16,
                          MIN(CGRectGetMaxX(a),CGRectGetMaxX(b))-
                            MAX(CGRectGetMinX(a),CGRectGetMinX(b)),32);
            self.dividerLine.frame=CGRectMake(0,15.5,MAX(0,tr.size.width),1);
        }
        self.dividerTrack.frame=tr;
        CGFloat length=self.verticalDivider?tr.size.height:tr.size.width;
        CGFloat gripSize=length<280.0?28.0:30.0;
        self.dividerLogo.layer.cornerRadius=gripSize/2.0;
        if(self.verticalDivider)
            self.dividerLogo.frame=CGRectMake(CGRectGetMidX(tr)-gripSize/2,
                        CGRectGetMinY(tr)+tr.size.height*self.logoRelativePosition-
                        gripSize/2,gripSize,gripSize);
        else
            self.dividerLogo.frame=CGRectMake(CGRectGetMinX(tr)+tr.size.width*
                         self.logoRelativePosition-gripSize/2,
                         CGRectGetMidY(tr)-gripSize/2,
                         gripSize,gripSize);
    }
    if(!self.pickerVisible)return;
    self.shade.frame=self.bounds;
    CGFloat w=MIN(470,MAX(260,CGRectGetWidth(self.bounds)-16));
    CGFloat h=MIN(150,MAX(110,CGRectGetHeight(self.bounds)-16));
    self.sheet.frame=CGRectMake((self.bounds.size.width-w)/2,
                               (self.bounds.size.height-h)/2,w,h);
    CGFloat logoWidth=MIN(120.0,MAX(78.0,w*.27));
    self.approvedLogo.frame=CGRectMake(8,7,logoWidth,DFSPMenuHeight);
    CGFloat remaining=w-logoWidth-48-16;
    CGFloat tabWidth=remaining/4;
    for (NSInteger i=0;i<4;i++) {
        UIButton *tab=self.menuButtons[i];
        tab.frame=CGRectMake(8+logoWidth+i*tabWidth,7,
                             tabWidth,DFSPMenuHeight);
        UIView *glyph=[tab viewWithTag:8162];
        glyph.frame=CGRectMake((tabWidth-16)/2,1,16,16);
        UIView *label=[tab viewWithTag:8163];
        label.frame=CGRectMake(0,18,tabWidth,12);
    }
    self.dismissButton.frame=CGRectMake(w-42,8,32,28);
}
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (self.hidden || self.alpha<=0.01)return nil;
    if (self.pickerVisible)return [super hitTest:point withEvent:event];
    NSMutableArray<UIView *> *targets=[NSMutableArray arrayWithArray:self.pills];
    [targets addObject:self.dividerTrack];
    [targets addObject:self.dividerLogo];
    for(UIView *view in [targets reverseObjectEnumerator]) {
        if (view.hidden || !view.userInteractionEnabled)continue;
        CGPoint p=[self convertPoint:point toView:view];
        if ([view pointInside:p withEvent:event])
            return [view hitTest:p withEvent:event]?:view;
    }
    // Native12 compositor passes touches to the actual app scene elsewhere.
    return nil;
}
- (void)setFocusedSlot:(NSInteger)focusedSlot {
    if (focusedSlot!=_focusedSlot) {
        _focusedSlot=focusedSlot;
        [self setNeedsLayout];
    }
}
- (void)expandTapped:(UIButton *)button {
    // Distinct per-pane focus: NEVER send the full CarPlay Zoom event.
    [self.delegate nativeFrameRequestedFocusForSlot:button.tag];
}
- (void)restoreTapped:(UIButton *)button {
    [self.delegate nativeFrameRequestedRestoreForSlot:button.tag];
}
- (void)pillTapped:(UIButton *)sender {
    self.selectedSlot=sender.tag;
    self.pickerVisible=YES;self.shade.hidden=NO;
    [self bringSubviewToFront:self.shade];
    [self setNeedsLayout];[self layoutIfNeeded];
}
- (void)dismissPicker {
    self.pickerVisible=NO;
    self.shade.hidden=YES;
}
- (void)menuTapped:(UIButton *)sender {
    NSInteger tab=sender.tag;
    NSInteger slot=self.selectedSlot;
    [self dismissPicker];
    switch(tab) {
      case 0: [self.delegate nativeFrameRequestedAppForSlot:slot];break;
      case 1: [self.delegate nativeFrameRequestedZoom];break;
      case 2: [self.delegate nativeFrameRequestedStyle];break;
      case 3: [self.delegate nativeFrameRequestedCloseForSlot:slot];break;
      default:break;
    }
}
- (void)swapTapped:(id)sender {
    (void)sender;
    [self.delegate nativeFrameRequestedSwap];
}
- (void)dragDivider:(UIPanGestureRecognizer *)pan {
    if (self.dividerTrack.hidden)return;
    CGPoint point=[pan locationInView:self];
    CGRect whole=CGRectUnion(self.firstRect,self.secondRect);
    if(CGRectGetWidth(whole)<=100 || CGRectGetHeight(whole)<=100)return;
    double ratio=self.verticalDivider?
        (point.x-CGRectGetMinX(whole))/CGRectGetWidth(whole):
        (point.y-CGRectGetMinY(whole))/CGRectGetHeight(whole);
    // SPDash.ratio belongs to pane[0]. If it has been swapped to right or
    // bottom, the physical leading-edge fraction must be inverted.
    BOOL reversed=self.verticalDivider?
        CGRectGetMidX(self.firstRect)>CGRectGetMidX(self.secondRect):
        CGRectGetMidY(self.firstRect)>CGRectGetMidY(self.secondRect);
    if (reversed)ratio=1.0-ratio;
    BOOL ended=pan.state==UIGestureRecognizerStateEnded||
               pan.state==UIGestureRecognizerStateCancelled;
    if(pan.state==UIGestureRecognizerStateBegan||
       pan.state==UIGestureRecognizerStateChanged||ended) {
        ratio=DFSPClampRatio(ratio,ended);
        self.currentRatio=ratio;
        [self.delegate nativeFrameDraggedToRatio:ratio ended:ended];
    }
}
- (void)moveLogo:(UILongPressGestureRecognizer *)hold {
    if(hold.state!=UIGestureRecognizerStateChanged &&
       hold.state!=UIGestureRecognizerStateEnded)return;
    CGRect tr=self.dividerTrack.frame;
    CGPoint p=[hold locationInView:self];
    if (self.verticalDivider && tr.size.height>DFSPGripSize)
        self.logoRelativePosition=fmax(0.1,fmin(0.9,(p.y-tr.origin.y)/tr.size.height));
    else if(!self.verticalDivider && tr.size.width>DFSPGripSize)
        self.logoRelativePosition=fmax(0.1,fmin(0.9,(p.x-tr.origin.x)/tr.size.width));
    [self setNeedsLayout];
}
- (void)resetForDisconnect {
    [self dismissPicker];
    self.delegate=nil;
    [self removeFromSuperview];
}
@end
