#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
/// Independent read-only capture of the actual CarPlay Dashboard-owned DBWorkspace.
/// This does NOT activate a new app, create a Dock, or replace system navigation.
@interface MTDashboardWorkspace : NSObject
+ (void)installEarlyObserver;
+ (NSDictionary<NSString *,id> *)snapshot;
@end
NS_ASSUME_NONNULL_END
