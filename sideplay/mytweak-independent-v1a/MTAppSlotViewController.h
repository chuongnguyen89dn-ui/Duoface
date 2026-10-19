// MTAppSlotViewController — một "ô" trên màn CarPlay.
// Trạng thái trống: hiện nút "Chọn app". Đã gắn app: hiện view của app
// (khi MTSceneHost host được) hoặc tên app + ghi chú.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class MTAppSession;
@class MTAppSlotViewController;

@protocol MTAppSlotDelegate <NSObject>
- (void)slotDidRequestAppPicker:(MTAppSlotViewController *)slot;
- (void)slotDidDoubleTap:(MTAppSlotViewController *)slot;
@end

@interface MTAppSlotViewController : UIViewController

@property (nonatomic, weak, nullable) id<MTAppSlotDelegate> delegate;
@property (nonatomic, assign) NSInteger slotIndex; // 0 = trái, 1 = phải

- (void)setSession:(MTAppSession *)session; // gắn app đã mở vào slot
- (void)showLaunchError:(NSError *)error;  // hiện lỗi mở app
- (void)clearSlot;                          // về trạng thái trống

@end

NS_ASSUME_NONNULL_END
