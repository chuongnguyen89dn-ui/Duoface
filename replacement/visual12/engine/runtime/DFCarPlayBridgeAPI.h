// DuoFace-owned bridge contract. This is not an Apple public CarPlay API.
// This module owns no UIWindow and may bind only to the sole existing host.
// Never instantiate together with a legacy CBBridgeManager scene owner.
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
FOUNDATION_EXPORT NSString *const DFCarPlayErrorDomain;
typedef NS_ENUM(NSInteger, DFCarPlayErrorCode) {
    DFCarPlayErrorUnavailable = 1,
    DFCarPlayErrorInvalidRequest = 2,
    DFCarPlayErrorBusy = 3,
    DFCarPlayErrorSceneFailed = 4,
    DFCarPlayErrorCancelled = 5,
};
typedef void (^DFCarPlayCompletion)(NSError * _Nullable error);

@protocol DFCarPlayBridgeAPI <NSObject>
- (void)startWithCompletion:(DFCarPlayCompletion)done;
- (void)openApp:(NSString *)bundleID
        inPane:(NSUInteger)pane
    completion:(DFCarPlayCompletion)done;
- (void)setSplitRatio:(CGFloat)ratio;
- (void)setLayoutKind:(NSInteger)kind fraction:(CGFloat)fraction secondary:(CGFloat)secondary;
- (void)swapPanes;
- (void)focusPane:(NSUInteger)pane;
- (void)restoreSplit;
- (void)closePane:(NSUInteger)pane;
- (void)stop;
@end

// G1/G2 integration: the caller creates a SINGLE external UIRootSceneWindow,
// provides its existing root controller and two or three pane views. This coordinator
// ONLY hosts SB app scenes inside those views; it does not create a second owner.
// It does not use DuoNavi, SidePlay, DuoDash or their license APIs.
@interface DFCarPlaySplitCoordinator : NSObject <DFCarPlayBridgeAPI>
- (nullable instancetype)initWithRootController:(UIViewController *)root
                                          panes:(NSArray<UIView *> *)panes
                                          error:(NSError * _Nullable * _Nullable)error;
@property(nonatomic,readonly) BOOL started;
- (BOOL)hasLiveSceneInPane:(NSUInteger)pane;
@end
NS_ASSUME_NONNULL_END
