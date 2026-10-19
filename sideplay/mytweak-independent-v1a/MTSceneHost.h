// MyTweak standalone SpringBoard scene host. No DuoFace CB* dependency.
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

FOUNDATION_EXPORT NSString *const MTSceneHostDidFailNotification;

@interface MTSceneHost : NSObject
+ (instancetype)sharedHost;
// Creates a pending host surface; scene readiness is asynchronous.
- (nullable UIView *)hostViewForBundleID:(NSString *)bundleID error:(NSError **)error;
- (void)releaseHostedView:(UIView *)view;
- (void)stopAllHosts;
@end
