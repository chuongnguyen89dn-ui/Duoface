#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Bộ bố cục độc lập. Chỉ nhận hai UIView chứa scene THẬT đã tạo ở tầng host.
// Không tự tạo cảnh giả, không khởi chạy ứng dụng và không thay đổi cửa sổ hệ thống.
@interface DFISplitLayout : NSObject

@property (nonatomic, readonly, getter=isAttached) BOOL attached;
@property (nonatomic, readonly) CGFloat leftFraction;

- (instancetype)initWithContainerView:(UIView *)containerView;
- (BOOL)attachLeftHostView:(UIView *)leftHost
            rightHostView:(UIView *)rightHost
                    error:(NSError * _Nullable * _Nullable)error;
- (void)setLeftFractionClamped:(CGFloat)fraction;
- (void)relayout;
- (void)detach;

@end

NS_ASSUME_NONNULL_END
