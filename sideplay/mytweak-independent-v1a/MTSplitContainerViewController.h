// MTSplitContainerViewController — chia màn CarPlay thành 2 slot trái/phải.
// - Kéo thanh chia ở giữa để đổi tỉ lệ (25% – 75%).
// - Double-tap vào một slot để cho nó toàn màn hình, tap lại để về chia đôi.

#import <UIKit/UIKit.h>

@class MTAppSlotViewController;

@interface MTSplitContainerViewController : UIViewController

@property (nonatomic, strong, readonly) MTAppSlotViewController *leftSlot;
@property (nonatomic, strong, readonly) MTAppSlotViewController *rightSlot;

// Tỉ lệ chiều rộng của slot trái (0.25 – 0.75). Mặc định 0.5.
@property (nonatomic, assign) CGFloat leftRatio;

// Bật/tắt toàn màn hình cho một slot. Truyền cùng slot đang fullscreen để thoát.
- (void)toggleFullscreenForSlot:(MTAppSlotViewController *)slot;

@end
