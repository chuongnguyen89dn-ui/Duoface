// Explicit CarPlay-owned host, attach to an EXISTING Dashboard root view only.
// Not installed via LS admission, constructors or a new window.
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
@interface MTCPDashboardOwner : NSObject
@property(nonatomic,readonly) BOOL attached;
@property(nonatomic,readonly) CGRect activeContentRect;
- (BOOL)attachToDashboardRoot:(UIViewController *)dashboardRoot;
- (void)refresh;
- (void)detach;
@end
NS_ASSUME_NONNULL_END
