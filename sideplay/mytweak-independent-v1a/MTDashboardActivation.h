#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
/// A real CarPlay Dashboard workspace transition, never a painted Home/Dock.
@interface MTDashboardActivation : NSObject
+ (void)installListenerInCarPlay;
+ (void)requestNativeHomeFromSpringBoard;
+ (void)requestDuoFaceShellFromSpringBoard;
@end
NS_ASSUME_NONNULL_END
