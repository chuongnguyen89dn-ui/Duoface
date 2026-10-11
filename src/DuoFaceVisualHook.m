// DuoFace visual-only runtime hook; UNVERIFIED on device, do not publish yet.
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
// Minimal ABI declaration: resolve the substrate hook symbol at link/runtime.
extern void MSHookMessageEx(Class cls, SEL sel, IMP replacement, IMP *original);

static NSString * const kAssets = @"/var/jb/Library/Application Support/DuoFace/VisualAssets/";
static char kOverlayKey;
static IMP oldButtonDidMove, oldButtonLayout, oldSplashLayout;
static BOOL dfApplying = NO;

static UIImage *DFImage(NSString *name) {
    return [UIImage imageWithContentsOfFile:[kAssets stringByAppendingString:name]];
}
static BOOL DFHasAction(UIButton *b, NSString *selector) {
    for (id target in [b allTargets])
        for (NSNumber *event in @[@(UIControlEventTouchUpInside), @(UIControlEventTouchDown),
                                   @(UIControlEventTouchUpOutside), @(UIControlEventTouchCancel)])
            for (NSString *action in [b actionsForTarget:target forControlEvent:[event unsignedIntegerValue]])
                if ([action isEqualToString:selector]) return YES;
    return NO;
}
static BOOL DFInsideClass(UIView *view, NSString *className) {
    for (UIView *v = view; v; v = v.superview)
        if ([NSStringFromClass([v class]) isEqualToString:className]) return YES;
    return NO;
}
static void DFApply(UIButton *button) {
    NSString *asset = nil;
    if (DFHasAction(button, @"dotsTapped:")) asset = @"duoface-picker.png";
    else if (DFHasAction(button, @"expandTapped:") || DFHasAction(button, @"restoreTapped:"))
        asset = @"duoface-fullscreen.png";
    else if (DFInsideClass(button, @"CBDividerView") &&
             (DFHasAction(button, @"moveButtonTouchDown:") || DFHasAction(button, @"moveButtonTouchUp:")))
        asset = @"duoface-swap.png";
    if (!asset) return;
    UIImage *image = DFImage(asset);
    if (!image) return;
    UIImageView *overlay = objc_getAssociatedObject(button, &kOverlayKey);
    if (!overlay) {
        overlay = [[UIImageView alloc] initWithFrame:button.bounds];
        overlay.userInteractionEnabled = NO;
        overlay.contentMode = UIViewContentModeScaleAspectFit;
        overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [button addSubview:overlay];
        objc_setAssociatedObject(button, &kOverlayKey, overlay, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [overlay release];
    }
    // Hide only original image glyph, not the button or its hit area/actions.
    // For the picker, its original dots are sibling/subviews; cover the button
    // surface with an opaque backdrop matching its own background before drawing.
    if (button.imageView && button.imageView != overlay) button.imageView.hidden = YES;
    overlay.backgroundColor = button.backgroundColor ?: [UIColor blackColor];
    overlay.image = image;
    [button bringSubviewToFront:overlay];
}
static void DFButtonDidMove(UIButton *self, SEL cmd) {
    ((void(*)(id,SEL))oldButtonDidMove)(self,cmd);
    if (self.window) DFApply(self);
}
static void DFButtonLayout(UIButton *self, SEL cmd) {
    ((void(*)(id,SEL))oldButtonLayout)(self,cmd);
    if (dfApplying || !self.window) return;
    dfApplying = YES;
    DFApply(self);
    dfApplying = NO;
}
static void DFSplashLayout(UIView *self, SEL cmd) {
    ((void(*)(id,SEL))oldSplashLayout)(self,cmd);
    NSMutableArray *stack = [NSMutableArray arrayWithObject:self];
    while (stack.count) {
        UIView *v = [[stack lastObject] retain]; [stack removeLastObject];
        if ([v isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)v;
            if ([label.text isEqualToString:@"TWO SCREENS. ZERO LIMITS."])
                label.text = @"TWO FACES ONE SCREEN";
            else if ([label.text isEqualToString:@"WORKS WITH APPLE CARPLAY"])
                label.hidden = YES;
        }
        [stack addObjectsFromArray:v.subviews]; [v release];
    }
    // Preserve existing splash layout and loading animation; recolor only the
    // splash container background. No control icons are added to splash.
    self.backgroundColor = [UIColor colorWithRed:0.035 green:0.025 blue:0.035 alpha:1.0];
}
__attribute__((constructor)) static void DFInit(void) {
    Class button = objc_getClass("UIButton");
    Class splash = objc_getClass("CBSplitSplashScreenView");
    if (button) {
        MSHookMessageEx(button, @selector(didMoveToWindow), (IMP)DFButtonDidMove, &oldButtonDidMove);
        MSHookMessageEx(button, @selector(layoutSubviews), (IMP)DFButtonLayout, &oldButtonLayout);
    }
    if (splash) MSHookMessageEx(splash, @selector(layoutSubviews), (IMP)DFSplashLayout, &oldSplashLayout);
}
