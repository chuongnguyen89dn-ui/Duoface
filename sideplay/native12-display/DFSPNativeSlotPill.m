#import "DFSPNativeSlotPill.h"
#import <math.h>

static UIImage *DFSPPillArt(NSString *filename, NSString *fallback) {
    NSString *folder=@"/var/jb/Library/Application Support/DuoFaceSidePlayDisplayQA/";
    NSString *path=[folder stringByAppendingString:filename];
    return [UIImage imageWithContentsOfFile:path] ?: [UIImage systemImageNamed:fallback];
}
static UIButton *DFSPActionButton(NSInteger slot, NSString *image,
                                  NSString *fallback, NSString *label,
                                  NSString *identifier, id target, SEL action) {
    UIButton *button=[UIButton buttonWithType:UIButtonTypeCustom];
    button.tag=slot;
    button.tintColor=UIColor.whiteColor;
    [button setImage:DFSPPillArt(image,fallback) forState:UIControlStateNormal];
    button.imageView.contentMode=UIViewContentModeScaleAspectFit;
    button.accessibilityLabel=label;
    button.accessibilityIdentifier=[NSString stringWithFormat:
                  @"duoface.native.slot.%ld.%@",(long)slot,identifier];
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}
@interface DFSPNativeSlotPill ()
@property(nonatomic,strong) UIButton *menuButton;
@property(nonatomic,strong) UIButton *expandButton;
@property(nonatomic,strong) UIButton *restoreButton;
@property(nonatomic,strong) UIView *separator;
@property(nonatomic,readwrite) NSInteger slot;
@property(nonatomic,readwrite) BOOL slotFocused;
@property(nonatomic,readwrite) BOOL compact;
@property(nonatomic,readwrite) BOOL allowsExpand;
@end
@implementation DFSPNativeSlotPill
- (instancetype)initWithSlot:(NSInteger)slot target:(id)target
                  menuAction:(SEL)menuAction expandAction:(SEL)expandAction
               restoreAction:(SEL)restoreAction {
    if (!(self=[super initWithEffect:
            [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterialDark]])) return nil;
    self.slot=slot;
    self.layer.cornerRadius=11.0;
    self.layer.masksToBounds=YES;
    self.layer.borderWidth=0.5;
    self.layer.borderColor=[UIColor colorWithWhite:1 alpha:0.25].CGColor;
    self.accessibilityIdentifier=[NSString stringWithFormat:
                   @"duoface.native.slot.%ld.pill",(long)slot];
    self.menuButton=DFSPActionButton(slot,@"duoface-picker.png",@"ellipsis",
        @"Chọn menu ứng dụng",@"app",target,menuAction);
    self.expandButton=DFSPActionButton(slot,@"duoface-fullscreen.png",
        @"arrow.up.left.and.arrow.down.right",@"Phóng to riêng ô",@"expand",target,expandAction);
    self.restoreButton=DFSPActionButton(slot,@"duoface-fullscreen.png",
        @"arrow.down.right.and.arrow.up.left",@"Khôi phục chia màn hình",
        @"restore",target,restoreAction);
    self.separator=[[UIView alloc]initWithFrame:CGRectZero];
    self.separator.backgroundColor=[UIColor colorWithWhite:1 alpha:0.25];
    self.separator.userInteractionEnabled=NO;
    [self.contentView addSubview:self.menuButton];
    [self.contentView addSubview:self.expandButton];
    [self.contentView addSubview:self.restoreButton];
    [self.contentView addSubview:self.separator];
    [self configureFocused:NO compact:NO allowsExpand:YES];
    return self;
}
- (void)configureFocused:(BOOL)focused compact:(BOOL)compact
             allowsExpand:(BOOL)allowsExpand {
    self.slotFocused=focused;
    self.compact=compact;
    self.allowsExpand=allowsExpand;
    self.menuButton.hidden=focused;
    self.expandButton.hidden=focused || !allowsExpand;
    self.restoreButton.hidden=!focused;
    self.separator.hidden=focused || !allowsExpand;
    [self setNeedsLayout];
}
- (CGSize)nativeSize {
    // Source: saved Native12 CBSlotPillView.updateBoundsSize evidence (six modes).
    CGFloat w=self.slotFocused?(self.compact?72:80):
             (self.allowsExpand?(self.compact?64:76):(self.compact?38:44));
    return CGSizeMake(w,self.compact?19:22);
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w=CGRectGetWidth(self.bounds),h=CGRectGetHeight(self.bounds),half=w/2;
    self.menuButton.frame=self.allowsExpand?CGRectMake(0,0,half,h):self.bounds;
    self.expandButton.frame=CGRectMake(half,0,w-half,h);
    self.restoreButton.frame=self.slotFocused?self.bounds:self.expandButton.frame;
    self.separator.frame=CGRectMake(half-0.25,3.5,0.5,MAX(0,h-7));
}
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if (self.hidden || self.alpha<=0.01) return NO;
    return CGRectContainsPoint(CGRectInset(self.bounds,-8,-10),point);
}
@end
