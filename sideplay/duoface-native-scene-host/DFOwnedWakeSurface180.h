// Independent owned-view wake gate. Never a second UIWindow or an app hook.
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
@interface DFOwnedWakeSurface180 : UIView
// Pure query: hidden controls + this exact current owned pane. No side effects.
@property(nonatomic,copy,nullable) BOOL (^wakeCaptureAllowed180)(void);
// Called only for delivered local contacts, never from hitTest/preflight.
@property(nonatomic,copy,nullable) void (^wakeContact180)(NSString *phase,NSUInteger count);
@property(nonatomic,readonly) BOOL hasWakeContacts180;
- (BOOL)reservesWakeAtPoint180:(CGPoint)point event:(nullable UIEvent *)event;
@end
NS_ASSUME_NONNULL_END
