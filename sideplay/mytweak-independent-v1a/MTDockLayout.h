#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
/// Convert genuine CarPlay DBDockWindow geometry into area outside the Dock.
/// Returns NO for missing, stale, invalid or unexpected records. Never invents dock size.
FOUNDATION_EXPORT BOOL MTDockContentRect(CGRect fullDisplay,
                                          NSDictionary * _Nullable record,
                                          CGRect * _Nullable output);
FOUNDATION_EXPORT NSString *MTDockRecordPath(void);
NS_ASSUME_NONNULL_END
