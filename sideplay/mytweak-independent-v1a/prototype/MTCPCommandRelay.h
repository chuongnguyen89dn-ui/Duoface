// Strictly opt-in, session-bound command relay. Does not synthesize UIKit touches.
#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
@interface MTCPCommandRelay : NSObject
- (BOOL)startForSession:(NSString *)session handler:(void (^)(NSDictionary *message))handler;
- (void)stop;
@end
NS_ASSUME_NONNULL_END
