#import <UIKit/UIKit.h>
#import "../../native-carplay-scene-v1/DF186NativePaneController.h"

@interface DF186TestDelegate:UIResponder<UIApplicationDelegate>
@property(nonatomic,strong) UIWindow *window;
@end
@implementation DF186TestDelegate
- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)options {
 (void)app;(void)options;
 self.window=[[UIWindow alloc]initWithFrame:UIScreen.mainScreen.bounds];
 UIViewController *root=[UIViewController new];self.window.rootViewController=root;
 [self.window makeKeyAndVisible];
 dispatch_async(dispatch_get_main_queue(),^{
  NSMutableArray *errors=[NSMutableArray new];
  DF186NativePaneController *pane=[DF186NativePaneController new];
  [root addChildViewController:pane];pane.view.frame=CGRectMake(12,0,198,360);
  [root.view addSubview:pane.view];[pane didMoveToParentViewController:root];
  UIViewController *native=[UIViewController new];
  [pane addChildViewController:native];[pane.view addSubview:native.view];
  [native didMoveToParentViewController:pane];
  UIView *mounted=native.view;pane.nativeController=native;pane.mountedView=mounted;
  __block BOOL authorized=YES;pane.layoutAuthorized=^BOOL{return authorized;};
  for(NSUInteger cycle=0;cycle<12;cycle++) {
   // Replay the observed drift with unchanged OUTER pane geometry.
   mounted.frame=CGRectZero;
   [pane.view setNeedsLayout];[pane.view layoutIfNeeded];
   [pane layoutNativeContent];
   if(!CGRectEqualToRect(mounted.frame,pane.view.bounds))
    [errors addObject:@"same-size drift was not reconciled"];
  }
  pane.view.frame=CGRectMake(12,0,297,360);[pane.view setNeedsLayout];[pane.view layoutIfNeeded];
  if(!CGRectEqualToRect(mounted.frame,pane.view.bounds))
   [errors addObject:@"divider reflow did not reach mounted view"];
  authorized=NO;mounted.frame=CGRectZero;[pane layoutNativeContent];
  if(!CGRectEqualToRect(mounted.frame,CGRectZero))
   [errors addObject:@"revoked owner still wrote layout"];
  authorized=YES;
  UIView *replacement=[UIView new];native.view=replacement;
  mounted.frame=CGRectZero;[pane layoutNativeContent];
  if(!CGRectEqualToRect(mounted.frame,CGRectZero) || !CGRectEqualToRect(replacement.frame,CGRectZero))
   [errors addObject:@"replaced view was accepted as same mounted view"];
  native.view=mounted;
  [native willMoveToParentViewController:nil];[mounted removeFromSuperview];
  [native removeFromParentViewController];mounted.frame=CGRectZero;[pane layoutNativeContent];
  if(!CGRectEqualToRect(mounted.frame,CGRectZero))
   [errors addObject:@"detached controller still wrote layout"];
  NSDictionary *result=@{@"passed":@(errors.count==0),@"errors":errors,
    @"scope":@"real UIKit containment only; no native CarPlay scene or vehicle pixel acceptance"};
  NSString *documents=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES).firstObject;
  [result writeToFile:[documents stringByAppendingPathComponent:@"result.plist"] atomically:YES];
 });
 return YES;
}
@end
int main(int argc,char **argv) {
 @autoreleasepool{return UIApplicationMain(argc,argv,nil,NSStringFromClass(DF186TestDelegate.class));}
}
