// MTBridgeRootViewController — màn hình gốc trên cửa sổ CarPlay.
// Quản lý MTSplitContainerViewController và mở màn chọn app cho từng slot.

#import <UIKit/UIKit.h>

@class MTAppSlotViewController;

@interface MTBridgeRootViewController : UIViewController

// Mở màn chọn app cho một slot (hiện trên chính màn CarPlay).
- (void)presentAppPickerForSlot:(MTAppSlotViewController *)slot;

@end
