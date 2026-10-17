// DuoFace-owned CB API shim for the previously implemented standalone scene host.
// Build ONLY in a package that does not load the legacy CB implementations.
// No DuoNavi or DuoDash binary, server, lease, or vendor implementation required.
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
FOUNDATION_EXPORT NSString * const DFCBCompatErrorDomain;

// Existing independent host calls these from the SpringBoard MAIN thread.
// Bind after its external split window is fully visible; unbind BEFORE shutdown.
FOUNDATION_EXPORT BOOL DFCBBindHost(UIWindow *window,
                                    UIViewController *splitController,
                                    NSError * _Nullable * _Nullable error);
FOUNDATION_EXPORT void DFCBUnbindHost(UIWindow *window);
FOUNDATION_EXPORT BOOL DFCBHostIsBound(void);

// Selector surface consumed by the saved DuoFace Fullscreen implementation.
@interface CBWindow : NSObject
+ (CGRect)carPlayScreenBounds;
+ (CGRect)carPlayUsableBounds;
@property(nonatomic) CGRect appFrame;
@property(nonatomic,readonly,nullable) UIWindow *rootWindow;
@property(nonatomic,readonly,nullable) UIView *contentView;
@property(nonatomic,readonly) BOOL isVisible;
- (void)resizeWindows;
- (void)show;
- (void)hide:(nullable void(^)(void))completion;
- (void)destroyWindows;
@end

@interface CBBridgedSplitApp : NSObject
@property(nonatomic,readonly,nullable) UIView *view;
- (void)layoutSplitViews;
@end

@interface CBBridgeManager : NSObject
+ (nullable instancetype)sharedInstanceIfExists;
@property(nonatomic,readonly) BOOL activated;
@property(nonatomic,readonly,nullable) CBWindow *window;
@property(nonatomic,readonly,nullable) CBBridgedSplitApp *currentApp;
@property(nonatomic) CGRect appFrame;
@property(nonatomic) CGSize renderSize;
- (void)deactivateCurrentApp;
@end
NS_ASSUME_NONNULL_END
