#import <UIKit/UIKit.h>

// Fullscreen close-control subset of ARWHostMenuView's default TOP edge.
// Does not reimplement Airaw's app picker, Control Center, or scale controls.
@interface DFRestoreMenu : UIView
@property(nonatomic, copy) void (^onCloseRequested)(void);
- (BOOL)installOnContainer:(UIView *)container alignedToHostView:(UIView *)hostView;
- (void)alignToHostView;
- (void)clearCallbacks;
@end
