// Experimental visual-only DuoFace runtime hook; NOT compiled or tested on iOS.
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#include <objc/runtime.h>
// Minimal ABI declaration: resolve the substrate hook symbol at link/runtime.
extern void MSHookMessageEx(Class cls, SEL sel, IMP replacement, IMP *original);

static NSString * const kAssets = @"/var/jb/Library/Application Support/DuoFace/VisualAssets/";
static char kOverlayKey;
static IMP oldButtonDidMove, oldSplashLayout;

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
    overlay.image = image;
    [button bringSubviewToFront:overlay];
    // Original glyphs are NOT suppressed yet. Do not release this experiment.
}
static void DFButtonDidMove(UIButton *self, SEL cmd) {
    ((void(*)(id,SEL))oldButtonDidMove)(self,cmd);
    if (self.window) DFApply(self);
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
    // Splash background is NOT approved or implemented.
}
__attribute__((constructor)) static void DFInit(void) {
    Class button = objc_getClass("UIButton");
    Class splash = objc_getClass("CBSplitSplashScreenView");
    if (button) MSHookMessageEx(button, @selector(didMoveToWindow), (IMP)DFButtonDidMove, &oldButtonDidMove);
    if (splash) MSHookMessageEx(splash, @selector(layoutSubviews), (IMP)DFSplashLayout, &oldSplashLayout);
}
