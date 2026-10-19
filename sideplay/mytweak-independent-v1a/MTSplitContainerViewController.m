#import "MTSplitContainerViewController.h"
#import "MTAppSlotViewController.h"
#import "MTTrialLog.h"
#import <math.h>
@interface MTSplitContainerViewController ()
@property(nonatomic,strong,readwrite) MTAppSlotViewController *leftSlot;
@property(nonatomic,strong,readwrite) MTAppSlotViewController *rightSlot;
@property(nonatomic,strong) UIView *dividerView;
@property(nonatomic,weak,nullable) MTAppSlotViewController *fullscreenSlot;
@end
@implementation MTSplitContainerViewController { CGFloat _panStartRatio; }
- (void)viewDidLoad {
    [super viewDidLoad];
    self.leftRatio=0.5;
    self.singlePaneMode=YES; // v1b first; v1c via Split button in same install
    self.view.backgroundColor=UIColor.blackColor;
    self.leftSlot=[MTAppSlotViewController new];
    self.leftSlot.slotIndex=0;
    self.rightSlot=[MTAppSlotViewController new];
    self.rightSlot.slotIndex=1;
    for (MTAppSlotViewController *slot in @[self.leftSlot,self.rightSlot]) {
        [self addChildViewController:slot];
        [self.view addSubview:slot.view];
        [slot didMoveToParentViewController:self];
    }
    self.dividerView=[UIView new];
    self.dividerView.backgroundColor=[UIColor colorWithWhite:0.32 alpha:1];
    [self.view addSubview:self.dividerView];
    UIPanGestureRecognizer *pan=[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dividerPanned:)];
    [self.dividerView addGestureRecognizer:pan];
    UILongPressGestureRecognizer *hold=[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(dividerHeld:)];
    hold.minimumPressDuration=0.3;
    [self.dividerView addGestureRecognizer:hold];
    [pan requireGestureRecognizerToFail:hold];
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat w=self.view.bounds.size.width,h=self.view.bounds.size.height;
    if (w<=0 || h<=0) return;
    MTAppSlotViewController *solo=self.fullscreenSlot ?: (self.singlePaneMode ? self.leftSlot : nil);
    if (solo) {
        MTAppSlotViewController *other=(solo==self.leftSlot)?self.rightSlot:self.leftSlot;
        solo.view.hidden=NO;solo.view.frame=self.view.bounds;
        other.view.hidden=YES;
        self.dividerView.hidden=YES;
    } else {
        self.leftSlot.view.hidden=NO;
        self.rightSlot.view.hidden=NO;
        self.dividerView.hidden=NO;
        CGFloat dividerWidth=12.0;
        CGFloat usable=MAX(0,w-dividerWidth);
        CGFloat leftWidth=round(usable * fmax(0.25,fmin(0.75,self.leftRatio)));
        self.leftSlot.view.frame=CGRectMake(0,0,leftWidth,h);
        self.dividerView.frame=CGRectMake(leftWidth,0,dividerWidth,h);
        self.rightSlot.view.frame=CGRectMake(leftWidth+dividerWidth,0,usable-leftWidth,h);
    }
}
- (void)dividerPanned:(UIPanGestureRecognizer *)pan {
    if (self.fullscreenSlot || self.singlePaneMode) return;
    CGFloat w=self.view.bounds.size.width;
    if (w<=0) return;
    if (pan.state==UIGestureRecognizerStateBegan) _panStartRatio=self.leftRatio;
    if (pan.state==UIGestureRecognizerStateChanged || pan.state==UIGestureRecognizerStateEnded) {
        CGFloat dx=[pan translationInView:self.view].x;
        self.leftRatio=fmax(0.25,fmin(0.75,_panStartRatio+dx/w));
        [self.view setNeedsLayout];
        if (pan.state==UIGestureRecognizerStateEnded)
            MTTrialLog(@"ratio",[NSString stringWithFormat:@"left=%.3f",self.leftRatio]);
    }
}
- (void)dividerHeld:(UILongPressGestureRecognizer *)hold {
    if (hold.state==UIGestureRecognizerStateBegan) [self swapSlots];
}
- (void)swapSlots {
    MTAppSlotViewController *previousLeft=self.leftSlot;
    self.leftSlot=self.rightSlot;
    self.rightSlot=previousLeft;
    self.leftSlot.slotIndex=0;
    self.rightSlot.slotIndex=1;
    // Swap controller frames, NOT hosted subviews; avoids unnecessary scene invalidation.
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    MTTrialLog(@"split-swap",[NSString stringWithFormat:@"leftRatio=%.3f",self.leftRatio]);
}
- (void)toggleFullscreenForSlot:(MTAppSlotViewController *)slot {
    self.fullscreenSlot=(self.fullscreenSlot==slot)?nil:slot;
    [UIView animateWithDuration:0.22 animations:^{[self.view setNeedsLayout];[self.view layoutIfNeeded];}];
    MTTrialLog(@"fullscreen",self.fullscreenSlot ? @"ON" : @"OFF");
}
@end
