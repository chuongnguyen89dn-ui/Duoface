// Independently maintained first-party DuoFace module, ported from the
// project's own prior scene-host experiments; no vendor binary or license.
// DuoFace standalone SpringBoard scene host. No DuoFace CB* dependency.
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const DFSceneHostDidFailNotification;
FOUNDATION_EXPORT NSString *const DFSceneHostDidBecomeReadyNotification;

@interface DFSceneHost : NSObject
+ (instancetype)sharedHost;
// Creates a pending host surface; scene readiness is asynchronous.
- (nullable UIView *)hostViewForBundleID:(NSString *)bundleID error:(NSError * _Nullable * _Nullable)error;
- (void)releaseHostedView:(UIView *)view;
- (void)stopAllHosts;
@end

NS_ASSUME_NONNULL_END
