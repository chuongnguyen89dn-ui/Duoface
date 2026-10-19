#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
/// Only applies recent, geometry-validated *actual CarPlay root safe area*.
/// Returns NO if data does not establish a meaningful content inset.
FOUNDATION_EXPORT BOOL MTDashboardUsableRect(CGRect wholeDisplay,
                                               NSDictionary * _Nullable record,
                                               CGRect * _Nullable output);
NS_ASSUME_NONNULL_END
