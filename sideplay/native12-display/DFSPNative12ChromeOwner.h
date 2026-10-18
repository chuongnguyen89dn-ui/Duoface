#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
/* Dashboard/CarPlay-process owner, bound explicitly to a verified SidePlay
   session. Does not discover or alter a SpringBoard or app split UI. */
@interface DFSPNative12ChromeOwner : NSObject
@property(nonatomic,readonly) BOOL active;
@property(nonatomic,readonly) BOOL chromeHidden;
- (instancetype)initWithObservedWindows:(NSArray<UIWindow *> *)windows;
- (BOOL)beginActiveSessionShowingBar;
- (BOOL)setSystemBarHidden:(BOOL)hidden;
- (void)endSessionRestoreOriginalVisibility;
@end
NS_ASSUME_NONNULL_END
