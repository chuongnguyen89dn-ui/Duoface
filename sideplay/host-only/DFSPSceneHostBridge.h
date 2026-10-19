#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

// DuoFace-owned boundary to the EXISTING, licensed SidePlay application host.
// This class never draws SidePlay UI, changes the vendor's entitlement/service
// checks, manipulates its CarPlay scene or performs an undocumented license call.
// During migration, only app-host capability is allowed through this boundary.
// Native12/Visual12/HUD8 own all visual, gesture and settings layers.
@interface DFSPSceneHostBridge : NSObject
@property (nonatomic, weak, readonly, nullable) id host;
@property (nonatomic, weak, readonly, nullable) UIWindow *carWindow;
- (nullable instancetype)initWithLiveHost:(id)host carWindow:(UIWindow *)window;
- (NSUInteger)hostedSlotCount;
- (BOOL)hasHostedAppInSlot:(NSUInteger)slot;
- (nullable UIView *)hostedSceneViewForSlot:(NSUInteger)slot;
- (CGRect)hostedFrameForSlot:(NSUInteger)slot relativeToView:(UIView *)target;
// These calls are for later, gated function-by-function migrations.
// Not used to replace working SidePlay app launching in milestone M1.
- (BOOL)loadBundleIdentifier:(NSString *)bundleID intoSlot:(NSUInteger)slot;
- (BOOL)unloadSlot:(NSUInteger)slot;
@end

NS_ASSUME_NONNULL_END
