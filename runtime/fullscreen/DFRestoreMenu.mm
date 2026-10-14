#import "DFRestoreMenu.h"

// Fullscreen-only recovery control for the v12 split host.
// The old Airaw-inspired white grabber overlaid its own close target on
// some CarPlay screen geometries. A directly tappable exit button replaces
// the grabber + tap-to-reveal panel, without changing the host restore path.
@interface DFRestoreMenu ()
@property(nonatomic, weak) UIView *hostView;
@property(nonatomic, strong) UIButton *closeButton;
@end

@implementation DFRestoreMenu
- (instancetype)initWithFrame:(CGRect)frame {
    if (!(self = [super initWithFrame:frame])) return nil;
    self.backgroundColor = UIColor.clearColor;
    self.clipsToBounds = NO;

    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, 44, 44);
    button.tintColor = UIColor.whiteColor;
    button.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.88];
    button.layer.cornerRadius = 12.0;
    button.clipsToBounds = YES;
    button.accessibilityLabel = @"Thu nhỏ";
    button.accessibilityHint = @"Khôi phục bố cục chia hai màn hình";
    UIImage *image = [UIImage systemImageNamed:@"arrow.down.right.and.arrow.up.left"
        withConfiguration:[UIImageSymbolConfiguration
            configurationWithPointSize:20 weight:UIImageSymbolWeightMedium]];
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:self action:@selector(didTapRestore:)
        forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:button];
    self.closeButton = button;
    return self;
}

- (BOOL)installOnContainer:(UIView *)container alignedToHostView:(UIView *)hostView {
    if (!container || !hostView || container.window != hostView.window || !hostView.window) return NO;
    self.hostView = hostView;
    [container addSubview:self];
    [self alignToHostView];
    BOOL installed = self.superview == container &&
                     self.bounds.size.width >= 44 &&
                     self.closeButton.superview == self &&
                     self.closeButton.enabled;
    NSLog(@"[DuoFaceFullscreen] restore control installed=%d", installed);
    return installed;
}

- (void)alignToHostView {
    UIView *host = self.hostView;
    if (!host || !self.superview) return;
    CGRect rect = [self.superview convertRect:host.bounds fromView:host];
    // An edge-aligned 44pt button replaces the 168pt transparent grabber area.
    self.frame = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, 52);
    [self setNeedsLayout];
    [self.superview bringSubviewToFront:self];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = self.bounds.size.width;
    self.closeButton.frame = CGRectMake(MAX(0.0, (width - 44.0) * 0.5),
                                        4.0, 44.0, 44.0);
}

// Forward touches only inside the visible 44x44 exit button.
// Both video/map panes receive all other touches as before.
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (self.hidden || self.alpha < 0.01 || !self.userInteractionEnabled ||
        !self.closeButton.enabled || self.closeButton.hidden) return nil;
    if (!CGRectContainsPoint(self.closeButton.frame, point)) return nil;
    CGPoint local = [self.closeButton convertPoint:point fromView:self];
    return [self.closeButton hitTest:local withEvent:event];
}

- (void)didTapRestore:(UIButton *)sender {
    (void)sender;
    NSLog(@"[DuoFaceFullscreen] direct restore button tapped");
    if (self.onCloseRequested) self.onCloseRequested();
}

- (void)clearCallbacks {
    self.onCloseRequested = nil;
    self.hostView = nil;
}
@end
