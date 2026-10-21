#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
@class MTAppSlotViewController;
@interface MTSplitContainerViewController : UIViewController
@property(nonatomic,strong,readonly) MTAppSlotViewController *leftSlot;
@property(nonatomic,strong,readonly) MTAppSlotViewController *rightSlot;
@property(nonatomic,assign) CGFloat leftRatio;
@property(nonatomic,assign) BOOL singlePaneMode;
- (void)toggleFullscreenForSlot:(MTAppSlotViewController *)slot;
- (void)swapSlots;
// Consume validated CarPlay coordinate phases for the split handle only.
- (BOOL)remoteDividerPhase:(NSString *)phase localPoint:(CGPoint)point;
@end
NS_ASSUME_NONNULL_END
