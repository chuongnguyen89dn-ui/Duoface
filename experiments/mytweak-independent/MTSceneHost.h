// MyTweak standalone SpringBoard scene host. No vendor host dependency.
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

FOUNDATION_EXPORT NSString *const MTSceneHostDidFailNotification;

@interface MTSceneHost : NSObject
+ (instancetype)sharedHost;
- (nullable UIView *)hostViewForBundleID:(NSString *)bundleID error:(NSError **)error;
- (void)releaseHostedView:(UIView *)view;
- (void)stopAllHosts;
@end
