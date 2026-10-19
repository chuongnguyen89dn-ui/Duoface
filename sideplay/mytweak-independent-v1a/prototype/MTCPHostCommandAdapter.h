// SpringBoard-owned UI action adapter: explicit call site required.
#import <Foundation/Foundation.h>
@class MTBridgeRootViewController;
NS_ASSUME_NONNULL_BEGIN
@interface MTCPHostCommandAdapter : NSObject
+ (BOOL)deliverActionPacket:(NSDictionary *)packet
                     toRoot:(MTBridgeRootViewController *)root;
@end
NS_ASSUME_NONNULL_END
