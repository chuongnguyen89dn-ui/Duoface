// Experimental, read-only CarPlay host geometry probe. Does NOT toggle fullscreen.
// Do not install on production; compile and test in isolated development package.
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
static void DFLogHost(NSString *event, id obj) {
    UIView *v = [obj isKindOfClass:[UIView class]] ? obj :
        ([obj isKindOfClass:[UIViewController class]] ? [(UIViewController *)obj view] : nil);
    if (!v || !v.window) return;
    NSLog(@"[DuoFaceHostProbe] %@ class=%@ frame=%@ bounds=%@ window=%@ safe=%@ hidden=%d",
          event, NSStringFromClass([obj class]), NSStringFromCGRect(v.frame),
          NSStringFromCGRect(v.bounds), NSStringFromCGRect(v.window.bounds),
          NSStringFromUIEdgeInsets(v.safeAreaInsets), v.hidden);
}
%hook DBDockWindow
- (void)layoutSubviews { %orig; DFLogHost(@"dock-layout", self); }
%end
%hook DBApplicationViewController
- (void)viewDidLayoutSubviews { %orig; DFLogHost(@"app-layout", self); }
%end
%hook DBDockRootViewController
- (void)viewDidLayoutSubviews { %orig; DFLogHost(@"dock-root-layout", self); }
%end
