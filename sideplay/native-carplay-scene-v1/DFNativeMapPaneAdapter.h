// First-party native Maps CarPlayApp same-process UIViewController handoff.
// Original OmniCar machine evidence: adopt:slot: 0x19878-0x19a80; the
// matching UIKit containment lifecycle, no vendor implementation copied.
// Caller must provide the actual live native owner and an already-admitted
// CarPlay UIKit parent in the SAME external UIWindow. The coordinator calls
// this only after explicit selection or a verified reconnect of that choice.
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
@interface DFNativeMapPaneAdapter : NSObject
@property(nonatomic,readonly,getter=isAttached) BOOL attached;
- (BOOL)hasVerifiedNativeOwner;
- (BOOL)discardDetachedNativeOwner;
+ (NSString *)preflightNativeController:(UIViewController *)nativeVC
                                  into:(UIViewController *)parent
                             container:(UIView *)container
                         measuredArea:(CGRect)usable;
- (BOOL)adoptNativeController:(UIViewController *)nativeVC
                        into:(UIViewController *)parent
                   container:(UIView *)container
                measuredArea:(CGRect)usable
        explicitlyAuthorized:(BOOL)authorized
                       error:(NSString * _Nullable * _Nullable)error;
- (BOOL)restoreOriginalOwnerWithError:(NSString * _Nullable * _Nullable)error;
@end
NS_ASSUME_NONNULL_END
