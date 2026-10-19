#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
@interface MTBridgeCoordinator : NSObject
+ (instancetype)sharedCoordinator;
+ (BOOL)trialEnabled;
+ (void)setTrialEnabled:(BOOL)enabled;
- (void)start;
- (void)stop;
- (void)stopAndDisable;
@property(nonatomic,readonly,getter=isCarPlayConnected) BOOL carPlayConnected;
@end
NS_ASSUME_NONNULL_END
