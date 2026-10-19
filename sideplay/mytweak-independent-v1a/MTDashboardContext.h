#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
/// Read-only CarPlay UI-process evidence, independent of any vendor runtime.
@interface MTDashboardContext : NSObject
+ (void)startIfCarPlayUIProcess;
@end
FOUNDATION_EXPORT NSString *MTDashboardContextPath(void);
NS_ASSUME_NONNULL_END
