// MTBridgeCoordinator — "bộ não" của tweak.
// Quan sát màn hình ngoài (CarPlay head unit hiện ra như một UIScreen ngoài),
// dựng MTBridgeWindow gắn lên màn đó; khi ngắt kết nối thì dọn dẹp.

#import <UIKit/UIKit.h>

@interface MTBridgeCoordinator : NSObject

+ (instancetype)sharedCoordinator;

// Bắt đầu quan sát UIScreenDidConnect/DidDisconnect. Gọi một lần khi tweak load.
- (void)start;
- (void)stop;

@property (nonatomic, readonly, getter=isCarPlayConnected) BOOL carPlayConnected;

@end
