// Explicit CarPlay-owned host, attach to an EXISTING Dashboard root view only.
// Not installed via LS admission, constructors or a new window.
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
@interface MTCPDashboardOwner : NSObject
@property(nonatomic,readonly) BOOL attached;
@property(nonatomic,readonly) CGRect activeContentRect;
@property(nonatomic,copy,readonly,nullable) NSString *receiverSession;
@property(nonatomic,readonly,getter=isHostFullscreen) BOOL hostFullscreen;
// Whole-host fullscreen, not selected split-slot focus. Captures and restores
// the exact native bar hidden state and last measured normal content rect.
- (BOOL)setHostFullscreen:(BOOL)fullscreen;
- (BOOL)attachToDashboardRoot:(UIViewController *)dashboardRoot;
- (void)refresh;
- (void)detach;
@end
NS_ASSUME_NONNULL_END
