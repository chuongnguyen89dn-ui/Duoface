#import <Foundation/Foundation.h>
@interface DFCPNativeBridgeQA : NSObject
+ (instancetype)shared;
- (void)start;
- (void)tick;
@end
