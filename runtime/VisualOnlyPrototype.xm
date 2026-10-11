// EXPERIMENTAL ONLY — not built, not tested on iOS or CarPlay.
// Visual-only Logos hook; never change button actions, frames, hit insets, or split logic.
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static UIImage *DFImage(NSString *name) {
    NSString *path = [@"/var/jb/Library/Application Support/DuoFace/VisualAssets"
                      stringByAppendingPathComponent:name];
    return [UIImage imageWithContentsOfFile:path];
}
static BOOL DFHasAction(UIButton *b, NSString *selector) {
    for (id target in b.allTargets) {
        for (NSString *name in [b actionsForTarget:target forControlEvent:UIControlEventTouchUpInside] ?: @[])
            if ([name isEqualToString:selector]) return YES;
        for (NSString *name in [b actionsForTarget:target forControlEvent:UIControlEventTouchDown] ?: @[])
            if ([name isEqualToString:selector]) return YES;
    }
    return NO;
}
static void DFOverlay(UIButton *button, NSString *filename) {
    UIImage *image = DFImage(filename);
    if (!image || CGRectIsEmpty(button.bounds)) return;
    const NSInteger tag = 0xD0FA;
    UIImageView *view = [button viewWithTag:tag];
    if (view && ![view isKindOfClass:UIImageView.class]) return;
    if (!view) {
        view = [[UIImageView alloc] initWithFrame:button.bounds];
        view.tag = tag;
        view.userInteractionEnabled = NO;
        view.contentMode = UIViewContentModeScaleAspectFit;
        [button addSubview:view];
    }
    view.frame = button.bounds;
    view.image = image;
    [button bringSubviewToFront:view];
    // Do not change UIButton's own image or targets until device validation.
}
static void DFScan(UIView *root) {
    if ([root isKindOfClass:UIButton.class]) {
        UIButton *b = (UIButton *)root;
        if (DFHasAction(b, @"dotsTapped:"))
            DFOverlay(b, @"duoface-picker.png");
        else if (DFHasAction(b, @"expandTapped:") || DFHasAction(b, @"restoreTapped:"))
            DFOverlay(b, @"duoface-fullscreen.png");
        else if (DFHasAction(b, @"moveButtonTouchDown:") ||
                 DFHasAction(b, @"moveButtonTouchUp:"))
            DFOverlay(b, @"duoface-swap.png");
    }
    for (UIView *child in [root.subviews copy]) {
        if (child.tag == 0xD0FA) continue;
        DFScan(child);
    }
}
%hook CBSlotPillView
- (void)layoutSubviews {
    %orig;
    DFScan(self);
}
%end
%hook CBDividerView
- (void)layoutSubviews {
    %orig;
    DFScan(self);
}
%end
%hook CBSplitSplashScreenView
- (void)layoutSubviews {
    %orig;
    // Splash background/label structure not yet validated; intentionally
    // do not alter loading animation, logo or splash subviews here.
}
%end
