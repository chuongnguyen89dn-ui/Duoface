// DuoFace-owned independent reconstruction of Native12's *visual hierarchy*.
// No vendor CB* objects, license/check services, or original compiled dashboard.
// Distinct sources/owners: root window surface, split, slot pill, divider and picker.
#pragma once

@interface DFINativeSplitSurface : UIView
@end
@implementation DFINativeSplitSurface
- (instancetype)initWithFrame:(CGRect)frame {
    if((self=[super initWithFrame:frame])) {
        self.backgroundColor=UIColor.blackColor;
        self.opaque=YES;
        self.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        self.accessibilityIdentifier=@"duoface.native.split";
    }
    return self;
}
@end

@interface DFINativeWindowSurface : UIView
@property(nonatomic,strong,readonly) DFINativeSplitSurface *splitSurface;
- (CGRect)usableContentFrame;
@end
@implementation DFINativeWindowSurface {
    DFINativeSplitSurface *_splitSurface;
}
- (instancetype)initWithFrame:(CGRect)frame {
    if((self=[super initWithFrame:frame])) {
        self.backgroundColor=UIColor.clearColor;
        self.opaque=NO;
        self.accessibilityIdentifier=@"duoface.native.window";
        _splitSurface=[[DFINativeSplitSurface alloc]initWithFrame:self.bounds];
        [self addSubview:_splitSurface];
    }
    return self;
}
- (DFINativeSplitSurface *)splitSurface{return _splitSurface;}
- (CGRect)usableContentFrame {
    // ARM64 DuoNavi 1.0.4 CBWindow.carPlayContentInsets (IMP 0xb1370):
    // uses an explicit configuration/real UIWindow.safeAreaInsets first;
    // if all are zero, the fallback is (top=0,left=64,bottom=0,right=0).
    // carPlayUsableBounds (0xb15cc) subtracts these from the full screen,
    // with a minimum 100x100 viability gate. It is NOT a decorative fake dock.
    UIEdgeInsets e=self.safeAreaInsets;
    if(e.top<=0 && e.left<=0 && e.bottom<=0 && e.right<=0 && self.window)
        e=self.window.safeAreaInsets;
    if(e.top<=0 && e.left<=0 && e.bottom<=0 && e.right<=0)
        e=UIEdgeInsetsMake(0,64,0,0);
    CGRect r=UIEdgeInsetsInsetRect(self.bounds,e);
    if(CGRectGetWidth(r)<100 || CGRectGetHeight(r)<100) {
        // Keep a viable split; do not let malformed headunit safeArea hide it.
        r=CGRectInset(self.bounds,0,0);
        if(CGRectGetWidth(r)>164)r.origin.x+=64,r.size.width-=64;
    }
    return CGRectIntegral(r);
}
- (void)layoutSubviews {
    [super layoutSubviews];
    _splitSurface.frame=[self usableContentFrame];
}
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    // The root scene is a transparent compositor outside actual split content.
    // Do not claim/intercept the left CarPlay Dock or status-bar hit region.
    if(!CGRectContainsPoint(_splitSurface.frame,point))return nil;
    return [super hitTest:point withEvent:event];
}
@end

@interface DFINativeSlotPillView : UIVisualEffectView
@property(nonatomic,strong,readonly) UIButton *dotsButton;
@property(nonatomic,strong,readonly) UIButton *expandButton;
@property(nonatomic,strong,readonly) UIButton *restoreButton;
@property(nonatomic) BOOL compactMode;
@property(nonatomic) BOOL showsExpandButton;
- (CGSize)nativeReferenceSize;
- (instancetype)initWithSlot:(NSInteger)slot target:(id)target
                 pickAction:(SEL)pickAction focusAction:(SEL)focusAction
          restoreAction:(SEL)restoreAction;
- (void)setFocused:(BOOL)focused;
@end
@implementation DFINativeSlotPillView {
    UIButton *_dotsButton;
    UIButton *_expandButton;
    UIButton *_restoreButton;
    UIView *_separatorView;
    BOOL _focusedMode;
}
static UIButton *DFINativePillButton(NSInteger slot, NSString *symbol,
                                    NSString *asset, NSString *identifier,
                                    id target, SEL action) {
    UIButton *button=[UIButton buttonWithType:UIButtonTypeCustom];
    button.tag=slot;
    button.tintColor=UIColor.whiteColor;
    button.contentMode=UIViewContentModeScaleAspectFit;
    button.accessibilityIdentifier=
       [NSString stringWithFormat:@"duoface.native.slot.%ld.%@",(long)slot,identifier];
    UIImage *artwork=DFIApprovedArtwork(asset);
    UIImage *image=artwork?:[UIImage systemImageNamed:symbol];
    [button setImage:image forState:UIControlStateNormal];
    button.imageView.contentMode=UIViewContentModeScaleAspectFit;
    if(target && action)[button addTarget:target action:action
                          forControlEvents:UIControlEventTouchUpInside];
    return button;
}
- (instancetype)initWithSlot:(NSInteger)slot target:(id)target
                 pickAction:(SEL)pickAction focusAction:(SEL)focusAction
          restoreAction:(SEL)restoreAction {
    if((self=[super initWithEffect:
          [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterialDark]])) {
        // Native12 CBSlotPillView.initWithSlotIndex: sets 76×22 and radius 11
        // (actual immutable DEB ASM 0x84208–0x84224 and 0x84328–0x84334).
        self.layer.cornerRadius=11.0;
        self.layer.masksToBounds=YES;
        self.accessibilityIdentifier=
           [NSString stringWithFormat:@"duoface.native.slot.%ld.pill",(long)slot];
        // Native12 constructor initWithSlotIndex: initial states:
        // isFocusedMode=NO, showsExpandButton=YES, isCompactMode=NO.
        _focusedMode=NO;_compactMode=NO;_showsExpandButton=YES;
        _dotsButton=DFINativePillButton(slot,@"ellipsis",
             @"VisualAssets/duoface-picker.png",@"app",target,pickAction);
        _expandButton=DFINativePillButton(slot,@"arrow.up.left.and.arrow.down.right",
             @"VisualAssets/duoface-fullscreen.png",@"expand",target,focusAction);
        _restoreButton=DFINativePillButton(slot,@"arrow.down.right.and.arrow.up.left",
             @"VisualAssets/duoface-fullscreen.png",@"restore",target,restoreAction);
        _dotsButton.accessibilityLabel=@"Chọn ứng dụng trong ô";
        _expandButton.accessibilityLabel=@"Phóng to ô";
        _restoreButton.accessibilityLabel=@"Khôi phục chia màn hình";
        // Actual Native12 initWithSlotIndex: 0x84820..0x848b4:
        // 0.5pt separator line, UIColor white with alpha 0.25.
        _separatorView=[[UIView alloc]initWithFrame:CGRectMake(0,4,0.5,14)];
        _separatorView.backgroundColor=[UIColor colorWithWhite:1.0 alpha:0.25];
        _separatorView.userInteractionEnabled=NO;
        [self.contentView addSubview:_dotsButton];
        [self.contentView addSubview:_expandButton];
        [self.contentView addSubview:_separatorView];
        [self.contentView addSubview:_restoreButton];
        [self setFocused:NO];
    }
    return self;
}
- (UIButton *)dotsButton{return _dotsButton;}
- (UIButton *)expandButton{return _expandButton;}
- (UIButton *)restoreButton{return _restoreButton;}
- (CGSize)nativeReferenceSize {
    // Exact Native12 CBSlotPillView.updateBoundsSize IMP 0x85184:
    // flags: +0xc58 focused; +0xc5c showsExpandButton; +0xc60 compact.
    // Branches verified through original setIsFocusedMode:/setShowsExpandButton:/
    // setIsCompactMode: static setters in same signed DEB.
    CGFloat width=_focusedMode?(_compactMode?72.0:80.0):
                  (_showsExpandButton?(_compactMode?64.0:76.0):
                                      (_compactMode?38.0:44.0));
    return CGSizeMake(width,_compactMode?19.0:22.0);
}
- (void)setFocused:(BOOL)focused {
    _focusedMode=focused;
    // Native12 CBSlotPillView.layoutSubviews 0x84cf8..0x84d6c:
    // focused hides dots and expand, exposes restore only.
    // Original 1.0.4 toggleFocusForSlot: calls the respective focus/restore
    // transition, not a second app-picker action while focused.
    _dotsButton.hidden=focused;
    _expandButton.hidden=focused || !_showsExpandButton;
    _separatorView.hidden=focused || !_showsExpandButton;
    _restoreButton.hidden=!focused;
    [self setNeedsLayout];
}
- (void)setCompactMode:(BOOL)value {
    _compactMode=value;
    [self setNeedsLayout];
}
- (void)setShowsExpandButton:(BOOL)value {
    _showsExpandButton=value;
    [self setFocused:_focusedMode];
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat height=self.bounds.size.height;
    CGFloat width=self.bounds.size.width;
    // Native12 CBSlotPillView.layoutSubviews ARM64 0x84e30..0x84eb0:
    // left child occupies width/2 and right child the remainder.
    // All six verified Native12 pill widths are even, so width*0.5
    // equals the native rounded-half result without a libm call.
    CGFloat half=width*0.5;
    _dotsButton.frame=CGRectMake(0,0,half,height);
    _expandButton.frame=CGRectMake(half,0,MAX(0,width-half),height);
    // Native12 nonfocused branch 0x84e64..0x84e94 uses x=half-0.25,
    // y=3.5, width 0.5 and height (pill height-7).
    _separatorView.frame=CGRectMake(half-0.25,3.5,0.5,MAX(0,height-7.0));
    // Focused Native12 branch 0x84d70..0x84d88 sends the current
    // entire pill bounds to restoreButton.setFrame: (not right half).
    _restoreButton.frame=_focusedMode?self.bounds:_expandButton.frame;
}
// Native12 CBSlotPillView.pointInside:withEvent: at 0x85348 expands
// CGRect hit bounds by 8pt horizontally and 10pt vertically. This only
// follows the parent hit region; child-button hit forwarding still needs
// a stopped-car touch test and is NOT assumed proven by this method.
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if(self.hidden || self.alpha<=0.01)return NO;
    return CGRectContainsPoint(CGRectInset(self.bounds,-8.0,-10.0),point);
}
@end

@interface DFINativeDividerTrack : UIView
@property(nonatomic,strong,readonly) UIView *stroke;
- (instancetype)initWithIndex:(NSInteger)index target:(id)target action:(SEL)action;
- (void)positionStrokeVertically:(BOOL)vertical;
@end
@implementation DFINativeDividerTrack {
    UIView *_stroke;
}
- (instancetype)initWithIndex:(NSInteger)index target:(id)target action:(SEL)action {
    if((self=[super initWithFrame:CGRectZero])) {
        self.tag=index;
        self.opaque=NO;
        self.backgroundColor=UIColor.clearColor;
        self.userInteractionEnabled=YES;
        self.accessibilityIdentifier=[NSString stringWithFormat:
            @"duoface.native.divider.%ld",(long)index];
        _stroke=[UIView new];
        _stroke.userInteractionEnabled=NO;
        _stroke.backgroundColor=[UIColor.whiteColor colorWithAlphaComponent:0.18];
        [self addSubview:_stroke];
        UIPanGestureRecognizer *pan=[[UIPanGestureRecognizer alloc]
                                      initWithTarget:target action:action];
        pan.cancelsTouchesInView=NO;
        [self addGestureRecognizer:pan];
    }
    return self;
}
- (UIView *)stroke{return _stroke;}
- (void)positionStrokeVertically:(BOOL)vertical {
    CGRect b=self.bounds;
    _stroke.frame=vertical?
       CGRectMake((b.size.width-1)/2.0,0,1,b.size.height):
       CGRectMake(0,(b.size.height-1)/2.0,b.size.width,1);
}
@end

@interface DFINativeDividerLogo : UIButton
- (instancetype)initWithIndex:(NSInteger)index target:(id)target
                 tapAction:(SEL)tapAction holdAction:(SEL)holdAction;
@end
@implementation DFINativeDividerLogo
- (instancetype)initWithIndex:(NSInteger)index target:(id)target
                 tapAction:(SEL)tapAction holdAction:(SEL)holdAction {
    if((self=[super initWithFrame:CGRectZero])) {
        self.tag=index;
        self.accessibilityIdentifier=[NSString stringWithFormat:
             @"duoface.native.divider.%ld.logo",(long)index];
        self.accessibilityLabel=@"Thanh chia DuoFace";
        self.tintColor=UIColor.whiteColor;
        self.backgroundColor=UIColor.clearColor;
        UIImage *asset=DFIApprovedArtwork(@"VisualAssets/duoface-swap.png");
        if(asset)[self setImage:asset forState:UIControlStateNormal];
        else [self setImage:[UIImage systemImageNamed:@"arrow.left.arrow.right"]
                      forState:UIControlStateNormal];
        self.imageView.contentMode=UIViewContentModeScaleAspectFit;
        if(target && tapAction)[self addTarget:target action:tapAction
                              forControlEvents:UIControlEventTouchUpInside];
        // Native12 approved gesture ownership:
        // short touch = original slot swap; hold >=0.30s moves logo ALONG
        // divider only. Ratio pan belongs to adjacent DividerTrack.
        UILongPressGestureRecognizer *hold=[[UILongPressGestureRecognizer alloc]
                                      initWithTarget:target action:holdAction];
        hold.minimumPressDuration=0.30;
        hold.allowableMovement=14.0;
        hold.cancelsTouchesInView=YES;
        [self addGestureRecognizer:hold];
    }
    return self;
}
// Native12 CBDividerView.pointInside:withEvent: (0xff864..0xff8dc)
// first tests every move-button frame expanded via CGRectInset(-12,-12).
// Keep the real grip visually 28/30pt but preserve its generous touch zone.
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if(self.hidden || self.alpha<=0.01)return NO;
    return CGRectContainsPoint(CGRectInset(self.bounds,-12.0,-12.0),point);
}
@end

@interface DFINativePickerCard : UIVisualEffectView
@end
@implementation DFINativePickerCard
- (instancetype)initWithFrame:(CGRect)frame {
    if((self=[super initWithEffect:
           [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialDark]])) {
        self.frame=frame;
        self.accessibilityIdentifier=@"duoface.native.picker.card";
        // Original visual12 sheet sets 20pt corner radius in _sheetCard
        // (audit/v12-picker-targeted-controls-20261015.txt, init 0xa0420).
        // Approved Native12 DFPickerZoomMenu clears its border, preserves blur.
        self.layer.cornerRadius=20.0;
        self.layer.masksToBounds=YES;
        self.layer.borderWidth=0.0;
        self.contentView.layer.borderWidth=0.0;
    }
    return self;
}
@end

@interface DFINativePickerMenuBar : UIVisualEffectView
@end
@implementation DFINativePickerMenuBar
- (instancetype)initWithFrame:(CGRect)frame {
    if((self=[super initWithEffect:nil])) {
        self.frame=frame;
        self.backgroundColor=UIColor.clearColor;
        self.accessibilityIdentifier=@"duoface.native.picker.menu-bar";
    }
    return self;
}
@end

static CGRect DFINativePickerCardFrame(CGRect windowBounds, NSUInteger rowCount) {
    CGFloat width=MIN(470.0,MAX(180.0,CGRectGetWidth(windowBounds)-16.0));
    CGFloat desired=MIN(280.0,MAX(140.0,(CGFloat)rowCount*40.0+55.0));
    CGFloat height=MIN(desired,MAX(90.0,CGRectGetHeight(windowBounds)-16.0));
    return CGRectMake(CGRectGetMidX(windowBounds)-width/2.0,
                      CGRectGetMidY(windowBounds)-height/2.0,width,height);
}
