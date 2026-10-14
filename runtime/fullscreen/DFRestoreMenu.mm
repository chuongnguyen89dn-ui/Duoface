#import "DFRestoreMenu.h"

// Source-bound values: audit/airaw-restore-control-20261014.txt.
// This is the fullscreen-only TOP-edge reconstruction, not the whole Airaw menu.
@interface DFRestoreMenu ()
@property(nonatomic, weak) UIView *hostView;
@property(nonatomic, strong) UIView *grabberPill;
@property(nonatomic, strong) UIVisualEffectView *panel;
@property(nonatomic, strong) UIButton *closeButton;
@property(nonatomic, strong) NSTimer *autoHideTimer;
@property(nonatomic) BOOL menuVisible;
@end

@implementation DFRestoreMenu
- (instancetype)initWithFrame:(CGRect)frame {
    if (!(self = [super initWithFrame:frame])) return nil;
    self.backgroundColor = UIColor.clearColor;
    self.clipsToBounds = NO;
    self.grabberPill = [UIView new];
    self.grabberPill.backgroundColor = UIColor.whiteColor;
    self.grabberPill.layer.cornerRadius = 2.5;
    self.grabberPill.userInteractionEnabled = NO;
    [self addSubview:self.grabberPill];
    self.panel = [[UIVisualEffectView alloc] initWithEffect:
        [UIBlurEffect effectWithStyle:(UIBlurEffectStyle)20]];
    self.panel.hidden = YES;
    [self addSubview:self.panel];
    self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.closeButton.frame = CGRectMake(0, 0, 44, 44);
    self.closeButton.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    self.closeButton.tintColor = UIColor.whiteColor;
    self.closeButton.clipsToBounds = YES;
    self.closeButton.layer.cornerRadius = 12;
    UIImage *image = [[UIImage systemImageNamed:@"arrow.down.right.and.arrow.up.left"
        withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:20
        weight:(UIImageSymbolWeight)5]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIColor *fill = [UIColor colorWithWhite:1 alpha:0.12];
    if (@available(iOS 15.0, *)) {
        UIButtonConfiguration *configuration = [UIButtonConfiguration filledButtonConfiguration];
        configuration.image = image;
        configuration.baseForegroundColor = UIColor.whiteColor;
        configuration.baseBackgroundColor = fill;
        configuration.cornerStyle = UIButtonConfigurationCornerStyleFixed;
        configuration.contentInsets = NSDirectionalEdgeInsetsZero;
        UIBackgroundConfiguration *background = configuration.background;
        background.cornerRadius = 12;
        configuration.background = background;
        self.closeButton.configuration = configuration;
    } else {
        [self.closeButton setImage:image forState:UIControlStateNormal];
        self.closeButton.backgroundColor = fill;
    }
    self.closeButton.accessibilityLabel = @"Exit Full Screen";
    [self.closeButton addTarget:self action:@selector(didTapSettings)
        forControlEvents:UIControlEventTouchUpInside];
    [self.panel.contentView addSubview:self.closeButton];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleMenu:)];
    tap.cancelsTouchesInView = NO;
    [self addGestureRecognizer:tap];
    return self;
}
- (BOOL)installOnContainer:(UIView *)container alignedToHostView:(UIView *)hostView {
    if (!container || !hostView || container.window != hostView.window || !hostView.window) return NO;
    self.hostView = hostView;
    [container addSubview:self];
    [self alignToHostView];
    return self.superview == container && self.bounds.size.width > 0;
}
- (void)alignToHostView {
    UIView *host = self.hostView;
    if (!host || !self.superview) return;
    CGRect rect = [self.superview convertRect:host.bounds fromView:host];
    // Airaw default horizontal chrome height = screenPointsToLocal(96)+72 at scale1.
    self.frame = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, 168);
    [self setNeedsLayout];
    [self.superview bringSubviewToFront:self];
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = self.bounds.size.width;
    // Airaw top grabber: centered 48x5, radius2.5. Horizontal panel: x12,y0,h68.
    self.grabberPill.frame = CGRectMake((width-48)*0.5, 0, 48, 5);
    self.panel.frame = CGRectMake(12, 0, MAX(160, width-24), 68);
    self.closeButton.frame = CGRectMake(self.panel.bounds.size.width-10-44, (68-44)*0.5, 44, 44);
}
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (self.hidden || self.alpha < 0.01 || !self.userInteractionEnabled) return nil;
    if (self.menuVisible && CGRectContainsPoint(self.panel.frame, point)) {
        return [self.panel hitTest:[self.panel convertPoint:point fromView:self] withEvent:event];
    }
    // Keep the two app panes touchable; reserve only the top grabber target.
    CGRect target = CGRectInset(self.grabberPill.frame, -24, -24);
    return CGRectContainsPoint(target, point) ? self : nil;
}
- (void)toggleMenu:(UITapGestureRecognizer *)tap {
    CGPoint point = [tap locationInView:self];
    if (self.menuVisible && CGRectContainsPoint(self.panel.frame, point)) return;
    if (self.menuVisible) [self hideMenu];
    else {
        self.menuVisible = YES; self.panel.hidden = NO; self.grabberPill.hidden = YES;
        [self.autoHideTimer invalidate];
        __weak DFRestoreMenu *weakSelf = self;
        self.autoHideTimer = [NSTimer scheduledTimerWithTimeInterval:5 repeats:NO
            block:^(NSTimer *timer) { (void)timer; [weakSelf hideMenu]; }];
    }
}
- (void)hideMenu {
    [self.autoHideTimer invalidate]; self.autoHideTimer = nil;
    self.menuVisible = NO; self.panel.hidden = YES; self.grabberPill.hidden = NO;
}
- (void)didTapSettings {
    // Airaw 0x3b20c: onCloseRequested block -> arwExitNativeFullscreen.
    if (self.onCloseRequested) self.onCloseRequested();
}
- (void)clearCallbacks {
    [self hideMenu]; self.onCloseRequested = nil; self.hostView = nil;
}
- (void)dealloc { [self.autoHideTimer invalidate]; }
@end
