// MTBridgeRootViewController — màn hình gốc trên cửa sổ CarPlay.
// Quản lý MTSplitContainerViewController và mở màn chọn app cho từng slot.

#import <UIKit/UIKit.h>

@class MTAppSlotViewController;

@interface MTBridgeRootViewController : UIViewController

// Mở màn chọn app cho một slot (hiện trên chính màn CarPlay).
- (void)presentAppPickerForSlot:(MTAppSlotViewController *)slot;
// First-party remote divider control; only normal split mode, no app event spoofing.
- (BOOL)remoteDividerPhase:(NSString *)phase normalizedPoint:(CGPoint)point;

@end
