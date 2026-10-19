#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
/// CarPlay-process-only observer; never draws or mutates Apple's native Dock.
@interface MTNativeDockProbe : NSObject
+ (void)startForCarPlayProcess;
@end
NS_ASSUME_NONNULL_END
