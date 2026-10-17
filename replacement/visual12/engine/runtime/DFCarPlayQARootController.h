// Compile-only QA harness. Never include this interface in production builds.
#import <UIKit/UIKit.h>
#if DFCARPLAY_QA
@interface DFCarPlayQARootController : UIViewController
- (void)runSingleBundle:(NSString *)bundleID;
- (void)runPairFirst:(NSString *)firstBundle second:(NSString *)secondBundle;
- (void)shutdown;
@end
#endif
