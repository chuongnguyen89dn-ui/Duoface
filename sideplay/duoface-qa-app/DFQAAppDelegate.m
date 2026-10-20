#import <UIKit/UIKit.h>
@interface DFQARootController : UIViewController
@end
@interface DFQAAppDelegate : UIResponder <UIApplicationDelegate>
@property(nonatomic,strong) UIWindow *window;
@end
@implementation DFQAAppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    self.window=[[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    UINavigationController *nav=[[UINavigationController alloc]
      initWithRootViewController:[DFQARootController new]];
    if(@available(iOS 13.0,*)){nav.navigationBar.prefersLargeTitles=YES;}
    self.window.rootViewController=nav;
    [self.window makeKeyAndVisible];
    return YES;
}
@end
