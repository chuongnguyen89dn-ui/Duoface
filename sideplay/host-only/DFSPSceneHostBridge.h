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
// M1 is intentionally READ ONLY. Native12 picker will request launching
// only after M2 verifies whether SidePlay -loadApp: expects an SBApplication
// object, an identifier, or another type; ObjC encoding "@" does NOT tell us.
@end

NS_ASSUME_NONNULL_END
