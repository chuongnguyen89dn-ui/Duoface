#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
/* Owns only the geometric presentation of the ENTIRE external CarPlay content.
   The calling SidePlay window owner must pass the REAL usable bounds reported
   by CarPlay. This class cannot infer/restore system dock visibility by itself. */
@interface DFSPNative12Host : NSObject
@property(nonatomic,readonly) BOOL isFullscreen;
@property(nonatomic,readonly) BOOL isAttached;
- (nullable instancetype)initWithCarPlayWindow:(UIWindow *)window
                                   contentRoot:(UIView *)contentRoot
                           nativeUsableInWindow:(CGRect)usable;
- (BOOL)applyNormal;
- (BOOL)applyFullscreen;
- (BOOL)reconcileAfterSystemLayout;
- (void)restoreAndDetach;
@end
NS_ASSUME_NONNULL_END
