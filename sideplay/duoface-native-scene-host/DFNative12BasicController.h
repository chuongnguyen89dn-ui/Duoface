#import <UIKit/UIKit.h>
@interface DFNative12BasicController : UIViewController
- (void)swap:(id)sender;
// Commands from CarPlay-owned CPBarButton/CPMapButton, not CPWindow touches.
- (void)performCarPlayControl:(NSString *)action;
- (void)setPresetRatio:(CGFloat)ratio;
@end
