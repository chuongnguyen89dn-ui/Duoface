#import <Foundation/Foundation.h>
#import "DFSPDisplayState.h"
NS_ASSUME_NONNULL_BEGIN
typedef void (^DFSPDisplayAckBlock)(BOOL applied);
/* Ports MUST send true only AFTER the appropriate process owner validates
   actual window geometry / system chrome state (not merely event delivery). */
typedef void (^DFSPDisplayOwnerPort)(BOOL enabled, uint64_t token,
                                     DFSPDisplayAckBlock completion);
/* Connect this adapter to the existing Native12 menu Zoom action.
   No new zoom control is created; neither owner port is hardwired to CB. */
@interface DFSPDisplayCoordinator : NSObject
@property(nonatomic,readonly) DFSPMode mode;
@property(nonatomic,readonly) BOOL fullscreenConfirmed;
@property(nonatomic,readonly) NSString *zoomAccessibilityLabel;
- (instancetype)initWithHostPort:(DFSPDisplayOwnerPort)host
                      chromePort:(DFSPDisplayOwnerPort)chrome
    NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
- (void)carPlayDidConnect;
- (void)existingNativeZoomPressed;
- (void)carPlayWillDisconnect;
@end
NS_ASSUME_NONNULL_END
