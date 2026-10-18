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
- (void)layoutSubviews {
    [super layoutSubviews];
    // Full native usableBounds/window-level geometry needs a verified receiver
    // sample. Never invent a fake system CarPlay bar or guessed safe inset.
    _splitSurface.frame=self.bounds;
}
@end

@interface DFINativeSlotPillView : UIVisualEffectView
@property(nonatomic,strong,readonly) UIButton *dotsButton;
@property(nonatomic,strong,readonly) UIButton *expandButton;
@property(nonatomic,strong,readonly) UIButton *restoreButton;
- (instancetype)initWithSlot:(NSInteger)slot target:(id)target
                 pickAction:(SEL)pickAction focusAction:(SEL)focusAction;
- (void)setFocused:(BOOL)focused;
@end
@implementation DFINativeSlotPillView {
    UIButton *_dotsButton;
    UIButton *_expandButton;
    UIButton *_restoreButton;
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
                 pickAction:(SEL)pickAction focusAction:(SEL)focusAction {
    if((self=[super initWithEffect:
          [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterialDark]])) {
        self.layer.cornerRadius=13.0;
        self.layer.masksToBounds=YES;
        self.accessibilityIdentifier=
           [NSString stringWithFormat:@"duoface.native.slot.%ld.pill",(long)slot];
        _dotsButton=DFINativePillButton(slot,@"ellipsis",
             @"VisualAssets/duoface-picker.png",@"app",target,pickAction);
        _expandButton=DFINativePillButton(slot,@"arrow.up.left.and.arrow.down.right",
             @"VisualAssets/duoface-fullscreen.png",@"expand",target,focusAction);
        _restoreButton=DFINativePillButton(slot,@"arrow.down.right.and.arrow.up.left",
             @"VisualAssets/duoface-fullscreen.png",@"restore",target,focusAction);
        _dotsButton.accessibilityLabel=@"Chọn ứng dụng trong ô";
        _expandButton.accessibilityLabel=@"Phóng to ô";
        _restoreButton.accessibilityLabel=@"Khôi phục chia màn hình";
        [self.contentView addSubview:_dotsButton];
        [self.contentView addSubview:_expandButton];
        [self.contentView addSubview:_restoreButton];
        [self setFocused:NO];
    }
    return self;
}
- (UIButton *)dotsButton{return _dotsButton;}
- (UIButton *)expandButton{return _expandButton;}
- (UIButton *)restoreButton{return _restoreButton;}
- (void)setFocused:(BOOL)focused {
    _expandButton.hidden=focused;
    _restoreButton.hidden=!focused;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    _dotsButton.frame=CGRectMake(4,2,30,26);
    _expandButton.frame=CGRectMake(39,2,30,26);
    _restoreButton.frame=_expandButton.frame;
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
                 tapAction:(SEL)tapAction panAction:(SEL)panAction;
@end
@implementation DFINativeDividerLogo
- (instancetype)initWithIndex:(NSInteger)index target:(id)target
                 tapAction:(SEL)tapAction panAction:(SEL)panAction {
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
        UIPanGestureRecognizer *pan=[[UIPanGestureRecognizer alloc]
                                      initWithTarget:target action:panAction];
        pan.cancelsTouchesInView=NO;
        [self addGestureRecognizer:pan];
    }
    return self;
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
        self.layer.cornerRadius=14.0;
        self.layer.masksToBounds=YES;
        self.layer.borderWidth=1.0;
        self.layer.borderColor=[UIColor.whiteColor colorWithAlphaComponent:.18].CGColor;
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
