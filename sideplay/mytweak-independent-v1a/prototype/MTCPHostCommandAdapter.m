// This adapter never creates another CarPlay window or synthetically injects touches.
#import "MTCPHostCommandAdapter.h"
#import "../MTBridgeRootViewController.h"
#import "../MTBridgeCoordinator.h"
#import "MTCPBridgeContract.h"
@interface MTBridgeRootViewController (MTCPTrustedMenuCalls)
- (void)toggleSplit;
- (void)swapApps;
- (void)toggleZoom;
@end
@implementation MTCPHostCommandAdapter
+ (BOOL)deliverActionPacket:(NSDictionary *)packet
                     toRoot:(MTBridgeRootViewController *)root {
    if (![NSThread isMainThread] ||
        ![NSProcessInfo.processInfo.processName isEqualToString:@"SpringBoard"] ||
        !MTCPBridgeExplicitOptIn() || !root ||
        ![root isKindOfClass:MTBridgeRootViewController.class])return NO;
    // The session/sequence/freshness gate belongs to MTCPCommandRelay before
    // this method. This method accepts only a subset of already parsed actions.
    if (![packet isKindOfClass:NSDictionary.class] ||
        ![packet[@"Kind"] isEqual:@"command"] ||
        ![packet[@"Action"] isKindOfClass:NSString.class])return NO;
    NSString *action=packet[@"Action"];
    if ([action isEqualToString:@"swap"]) {
        [root swapApps];return YES;
    }
    if ([action isEqualToString:@"split"]) {
        [root toggleSplit];return YES;
    }
    if ([action isEqualToString:@"zoom"]) {
        [root toggleZoom];return YES;
    }
    if ([action isEqualToString:@"close"]) {
        [[MTBridgeCoordinator sharedCoordinator] stopAndDisable];return YES;
    }
    // A real Dashboard owner must implement native Home. No fake action.
    // Raw pointer packets need an independently validated UIKit touch adapter.
    return NO;
}
@end
