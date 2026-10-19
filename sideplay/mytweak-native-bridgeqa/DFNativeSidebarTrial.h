// Time-bounded, third-opt-in CarPlay-native statusbar visibility experiment.
// Does NOT invent an AppDock UIView or hook the native Dashboard.
#import <UIKit/UIKit.h>
@interface DFNativeSidebarTrial : NSObject
@property(nonatomic,readonly) BOOL active;
- (void)tickWithSurface:(NSDictionary * _Nullable)surface;
- (void)stop;
@end
