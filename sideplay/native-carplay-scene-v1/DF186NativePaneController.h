#import <UIKit/UIKit.h>

// UIKit containment belongs to an independent pane controller, not to the
// Dashboard's collection of system application controllers. Keep the exact
// mounted UIView for layout and attestation; never substitute sceneHostView.
@interface DF186NativePaneController:UIViewController
@property(nonatomic,weak) UIViewController *nativeController;
@property(nonatomic,weak) UIView *mountedView;
@property(nonatomic,copy) BOOL (^layoutAuthorized)(void);
@property(nonatomic,assign) BOOL layingOutContent;
- (void)layoutNativeContent;
@end
@implementation DF186NativePaneController
- (void)loadView {
 self.view=[UIView new];self.view.clipsToBounds=YES;
 self.view.backgroundColor=UIColor.clearColor;
}
- (void)layoutNativeContent {
 UIView *v=self.mountedView;
 if(self.layingOutContent || !self.layoutAuthorized || !self.layoutAuthorized() || !v ||
    self.nativeController.viewIfLoaded!=v ||
    self.nativeController.parentViewController!=self ||
    v.superview!=self.view || CGRectIsEmpty(self.view.bounds))return;
 // Native CarPlay coordinates are points. Never apply the phone bridge zoom.
 self.layingOutContent=YES;
 @try {
  v.frame=self.view.bounds;
  [v setNeedsLayout];[v layoutIfNeeded];
 } @finally {self.layingOutContent=NO;}
}
- (void)viewDidLayoutSubviews {
 [super viewDidLayoutSubviews];[self layoutNativeContent];
}
@end

