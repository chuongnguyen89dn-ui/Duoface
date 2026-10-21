#import <UIKit/UIKit.h>
@interface DFNative12BasicController : UIViewController
- (void)swap:(id)sender;
// Commands shared by first-party external touch windows and visible CarPlay scene.
- (void)performCarPlayControl:(NSString *)action;
- (void)performCarPlayControl:(NSString *)action slot:(NSInteger)slot;
- (void)setPresetRatio:(CGFloat)ratio;
@end
