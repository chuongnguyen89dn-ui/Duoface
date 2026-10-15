#import "DFISplitLayout.h"
#import <math.h>

static NSString * const DFISplitErrorDomain = @"com.duoface.independent.split";

@interface DFISplitLayout ()
@property (nonatomic, weak) UIView *containerView;
@property (nonatomic, strong) UIView *leftHostView;
@property (nonatomic, strong) UIView *rightHostView;
@property (nonatomic) CGRect originalLeftFrame;
@property (nonatomic) CGRect originalRightFrame;
@property (nonatomic) UIViewAutoresizing originalLeftMask;
@property (nonatomic) UIViewAutoresizing originalRightMask;
@property (nonatomic, readwrite, getter=isAttached) BOOL attached;
@property (nonatomic, readwrite) CGFloat leftFraction;
@end

@implementation DFISplitLayout

- (instancetype)initWithContainerView:(UIView *)containerView {
    NSParameterAssert(containerView != nil);
    if (!(self = [super init])) return nil;
    _containerView = containerView;
    _leftFraction = 0.5;
    return self;
}

- (BOOL)attachLeftHostView:(UIView *)leftHost
            rightHostView:(UIView *)rightHost
                    error:(NSError * _Nullable __autoreleasing *)error {
    // UIKit views must be attached and laid out on the main thread.
    if (![NSThread isMainThread]) {
        if (error) *error = [NSError errorWithDomain:DFISplitErrorDomain code:1
            userInfo:@{NSLocalizedDescriptionKey: @"Yêu cầu luồng giao diện chính"}];
        return NO;
    }
    UIView *container = self.containerView;
    if (!container || self.attached || !leftHost || !rightHost ||
        leftHost == rightHost || leftHost == container || rightHost == container ||
        leftHost.superview != nil || rightHost.superview != nil) {
        if (error) *error = [NSError errorWithDomain:DFISplitErrorDomain code:2
            userInfo:@{NSLocalizedDescriptionKey: @"Hai vùng scene phải có thật, khác nhau và chưa gắn vào cây giao diện"}];
        return NO;
    }

    self.originalLeftFrame = leftHost.frame;
    self.originalRightFrame = rightHost.frame;
    self.originalLeftMask = leftHost.autoresizingMask;
    self.originalRightMask = rightHost.autoresizingMask;
    self.leftHostView = leftHost;
    self.rightHostView = rightHost;
    leftHost.autoresizingMask = UIViewAutoresizingNone;
    rightHost.autoresizingMask = UIViewAutoresizingNone;
    [container addSubview:leftHost];
    [container addSubview:rightHost];
    self.attached = YES;
    [self relayout];
    return YES;
}

- (void)setLeftFractionClamped:(CGFloat)fraction {
    if (!isfinite(fraction)) return;
    self.leftFraction = MIN(0.8, MAX(0.2, fraction));
    if (self.attached) [self relayout];
}

- (void)relayout {
    if (![NSThread isMainThread] || !self.attached) return;
    UIView *container = self.containerView;
    UIView *left = self.leftHostView;
    UIView *right = self.rightHostView;
    if (!container || !left || !right || left.superview != container ||
        right.superview != container) {
        // Host đã bị hệ thống thu hồi: không tự gắn lại scene cũ.
        [self detach];
        return;
    }
    CGRect bounds = container.bounds;
    if (CGRectIsEmpty(bounds) || !isfinite(bounds.size.width) ||
        !isfinite(bounds.size.height)) return;

    CGFloat w = bounds.size.width * self.leftFraction;
    left.frame = CGRectMake(bounds.origin.x, bounds.origin.y, w, bounds.size.height);
    right.frame = CGRectMake(bounds.origin.x + w, bounds.origin.y,
                             bounds.size.width - w, bounds.size.height);
}

- (void)detach {
    if (![NSThread isMainThread]) return;
    UIView *container = self.containerView;
    if (self.leftHostView.superview == container) [self.leftHostView removeFromSuperview];
    if (self.rightHostView.superview == container) [self.rightHostView removeFromSuperview];
    self.leftHostView.frame = self.originalLeftFrame;
    self.rightHostView.frame = self.originalRightFrame;
    self.leftHostView.autoresizingMask = self.originalLeftMask;
    self.rightHostView.autoresizingMask = self.originalRightMask;
    self.leftHostView = nil;
    self.rightHostView = nil;
    self.attached = NO;
}

@end
