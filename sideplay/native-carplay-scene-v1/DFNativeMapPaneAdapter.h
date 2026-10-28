// First-party native Maps CarPlayApp same-process UIViewController handoff.
// Original OmniCar machine evidence: adopt:slot: 0x19878-0x19a80; the
// matching UIKit containment lifecycle, no vendor implementation copied.
// STAGED ONLY; caller must provide the actual live native owner and an
// already-admitted CarPlay UIKit parent in the SAME external UIWindow.
// NO default caller, no automatic reparenting or scene lifecycle mutation.
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
@interface DFNativeMapPaneAdapter : NSObject
@property(nonatomic,readonly,getter=isAttached) BOOL attached;
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
