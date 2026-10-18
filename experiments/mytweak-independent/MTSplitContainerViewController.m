#import "MTSplitContainerViewController.h"
#import "MTAppSlotViewController.h"

@interface MTSplitContainerViewController ()
@property (nonatomic, strong, readwrite) MTAppSlotViewController *leftSlot;
@property (nonatomic, strong, readwrite) MTAppSlotViewController *rightSlot;
@property (nonatomic, strong) UIView *dividerView;
@property (nonatomic, weak, nullable) MTAppSlotViewController *fullscreenSlot;
@end

@implementation MTSplitContainerViewController {
    CGFloat _panStartRatio; // tỉ lệ lúc bắt đầu kéo divider
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.leftRatio = 0.5;
    self.view.backgroundColor = [UIColor blackColor];

    _leftSlot = [[MTAppSlotViewController alloc] init];
    _leftSlot.slotIndex = 0;
    _rightSlot = [[MTAppSlotViewController alloc] init];
    _rightSlot.slotIndex = 1;

    for (MTAppSlotViewController *slot in @[_leftSlot, _rightSlot]) {
        [self addChildViewController:slot];
        [self.view addSubview:slot.view];
        [slot didMoveToParentViewController:self];
    }

    _dividerView = [[UIView alloc] init];
    _dividerView.backgroundColor = [UIColor darkGrayColor];
    [self.view addSubview:_dividerView];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]
        initWithTarget:self action:@selector(dividerPanned:)];
    [_dividerView addGestureRecognizer:pan];
}

// Layout bằng frame cho đơn giản và chắc chắn (không phụ thuộc Auto Layout
// trên window ngoài, vốn đôi khi có behavior lạ).
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat w = self.view.bounds.size.width;
    CGFloat h = self.view.bounds.size.height;
    if (w <= 0 || h <= 0) {
        return;
    }

    if (self.fullscreenSlot) {
        self.fullscreenSlot.view.frame = self.view.bounds;
        self.fullscreenSlot.view.hidden = NO;
        MTAppSlotViewController *other =
            (self.fullscreenSlot == self.leftSlot) ? self.rightSlot : self.leftSlot;
        other.view.hidden = YES;
        self.dividerView.hidden = YES;
    } else {
        self.leftSlot.view.hidden = NO;
        self.rightSlot.view.hidden = NO;
        self.dividerView.hidden = NO;
        CGFloat dividerW = 8.0;
        CGFloat leftW = w * self.leftRatio;
        self.leftSlot.view.frame = CGRectMake(0, 0, leftW, h);
        self.dividerView.frame = CGRectMake(leftW, 0, dividerW, h);
        self.rightSlot.view.frame = CGRectMake(leftW + dividerW, 0,
                                               w - leftW - dividerW, h);
    }
}

- (void)dividerPanned:(UIPanGestureRecognizer *)pan {
    if (self.fullscreenSlot) {
        return;
    }
    if (pan.state == UIGestureRecognizerStateBegan) {
        _panStartRatio = self.leftRatio;
    }
    CGFloat w = self.view.bounds.size.width;
    if (w <= 0) {
        return;
    }
    CGPoint t = [pan translationInView:self.view];
    CGFloat r = _panStartRatio + t.x / w;
    r = fmax(0.25, fmin(0.75, r)); // kẹp trong 25% – 75%
    self.leftRatio = r;
    [self.view setNeedsLayout];
}

- (void)toggleFullscreenForSlot:(MTAppSlotViewController *)slot {
    self.fullscreenSlot = (self.fullscreenSlot == slot) ? nil : slot;
    [UIView animateWithDuration:0.25 animations:^{
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    }];
    NSLog(@"[MyTweak] Fullscreen %@ for slot %ld",
          self.fullscreenSlot ? @"ON" : @"OFF", (long)slot.slotIndex);
}

@end
